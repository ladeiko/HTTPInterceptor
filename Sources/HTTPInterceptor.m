//
//  HTTPInterceptor.m
//
//  Created by Siarhei Ladzeika on 16 Apr 19.
//  Copyright © 2017 Siarhei Ladzeika. All rights reserved.
//

#import "HTTPInterceptor.h"
#import <CoreServices/CoreServices.h>

static BOOL urlsAreEqual(NSURL* a, NSURL* b) {
    return [[a URLByAppendingPathComponent:@""] isEqual:[b URLByAppendingPathComponent:@""]];
}

static NSString * const NSURLProtocolInterceptorHandledKey = @"NSURLProtocolInterceptorHandledKey";
static NSMutableArray<NSDictionary*>* gRequestFilters = nil;
static NSMutableArray<NSDictionary*>* g_preprocessor = nil;

@interface NSURLProtocolInterceptor : NSURLProtocol<NSURLConnectionDelegate> {}
@property (nonatomic, strong) NSURLConnection *connection;
@end

@implementation HTTPInterceptor

+ (NSURLProtocolInterceptorHandlerKey)addPreprocessor:(__nonnull NSURLProtocolInterceptorRequestPreprocessor)preprocessor {
    NSString* const key = [@"PRE-" stringByAppendingString:[[NSUUID UUID] UUIDString]];
    @synchronized(self) {
        if (!g_preprocessor) {
            g_preprocessor = [NSMutableArray new];
        }
        [g_preprocessor addObject:@{ @"key": key, @"block": [preprocessor copy] }];
    }
    return key;
}

+ (void)removePreprocessorForKey:(__nonnull NSURLProtocolInterceptorHandlerKey)key {
    @synchronized(self) {
        [g_preprocessor filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            return ![[evaluatedObject objectForKey:@"key"] isEqualToString:key];
        }]];
    }
}

+ (NSString*)addInterceptor:(NSURLProtocolInterceptorRequestFilter)filter {
    NSString* const key = [@"REQ-" stringByAppendingString:[[NSUUID UUID] UUIDString]];
    @synchronized(self) {
        if (!gRequestFilters) {
            gRequestFilters = [NSMutableArray new];
        }
        [gRequestFilters addObject:@{ @"key": key, @"block": [filter copy] }];
    }
    return key;
}


+ (void)removeInterceptorForKey:(NSString*)key {
    @synchronized(self) {
        [gRequestFilters filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
            return ![[evaluatedObject objectForKey:@"key"] isEqualToString:key];
        }]];
    }
}

+ (NSURLProtocolInterceptorHandlerKey)mapUrl:(NSURL*)url toLocalPathUrl:(NSURL*)localUrl {
    NSString* const target = url.absoluteString;
    return [self addInterceptor:^(NSURLRequest * _Nonnull request, NSURLProtocolInterceptorSuccessDataCompletion  _Nonnull successCompletion, NSURLProtocolInterceptorFailureDataCompletion  _Nonnull __nullablefailureCompletion) {
        
        if (![request.URL.absoluteString hasPrefix:target]){
            return;
        }
        
        const BOOL match = urlsAreEqual(url, request.URL);
        
        void(^const f404)(void) = ^ {
            successCompletion(404, nil, nil, nil, nil);
        };
        
        NSString* localFilePath = nil;
        
        BOOL isDirectory = NO;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:localUrl.path isDirectory:&isDirectory] && !isDirectory) {
            if (match) {
                localFilePath = localUrl.path;
            }
            else {
                f404();
                return;
            }
        }
        else {

            NSURLComponents* const components = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
            NSString* const path = [components path];
            
            localFilePath = [[localUrl URLByAppendingPathComponent:path] path];
            
            if (![[NSFileManager defaultManager] fileExistsAtPath:localFilePath isDirectory:&isDirectory]) {
                f404();
                return;
            }
            
            if (isDirectory) {
                localFilePath = [localFilePath stringByAppendingPathComponent:@"index.html"];
                if (![[NSFileManager defaultManager] fileExistsAtPath:localFilePath isDirectory:&isDirectory] || isDirectory) {
                    f404();
                    return;
                }
            }
        }
        
        NSData* const data = [NSData dataWithContentsOfFile:localFilePath];
        if (!data) {
            f404();
            return;
        }
        
        NSString* const fileExtension = [localFilePath pathExtension];
        
        NSString* const UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, NULL);
        NSString* const contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
        NSString* encoding = nil;
        
        if ([@[@"text"] containsObject:[[contentType componentsSeparatedByString:@"/"] firstObject]]) {
            encoding = @"utf-8";
        }
        
        successCompletion(200, [NSURL fileURLWithPath:localFilePath], contentType, encoding, nil);
    }];
}

@end

@implementation NSURLProtocolInterceptor

+ (void)load {
    [NSURLProtocol registerClass:NSURLProtocolInterceptor.class];
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    
    NSString* const lc = [request.URL.absoluteString lowercaseString];
    
    if (![lc hasPrefix:@"http://"] && ![lc hasPrefix:@"https://"]) {
        return NO;
    }
    
    if ([NSURLProtocol propertyForKey:NSURLProtocolInterceptorHandledKey inRequest:request]) {
        return NO;
    }
    
    return YES;
}

+ (NSURLRequest *) canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void) startLoading {
    
    NSMutableURLRequest *newRequest = [self.request mutableCopy];
    
    [NSURLProtocol setProperty:@YES forKey:NSURLProtocolInterceptorHandledKey inRequest:newRequest];
    
    NSArray<NSDictionary*>* preprocessors;
    
    @synchronized([HTTPInterceptor class]) {
        preprocessors = [g_preprocessor copy];
    }
    
    for (NSDictionary* info in preprocessors) {
        const NSURLProtocolInterceptorRequestPreprocessor f = (NSURLProtocolInterceptorRequestPreprocessor)info[@"block"];
        f(newRequest);
    }
    
    NSArray<NSDictionary*>* filters;
    
    @synchronized([HTTPInterceptor class]) {
        filters = [gRequestFilters copy];
    }
    
    if ([filters count] > 0 && [newRequest.URL.absoluteString hasPrefix:@"http"]) {
        
        __block BOOL completed = NO;
        
        const NSURLProtocolInterceptorSuccessDataCompletion successCompletion = ^(NSInteger httpStatusCode, id data, NSString* mimeType, NSString* encoding, NSDictionary* extraHeaderFields){
            assert(completed == NO);
            assert(httpStatusCode > 0 && httpStatusCode < 600);
            completed = YES;
            
            unsigned long long contentLength = 0;
            
            if ([data isKindOfClass:[NSData class]]) {
                contentLength = [data length];
            }
            else if ([data isKindOfClass:[NSURL class]]) {
                NSURL* const url = (NSURL*)data;
                contentLength = [[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:NULL] fileSize];
            }
            
            NSMutableDictionary* const headerFields = extraHeaderFields ? [extraHeaderFields mutableCopy] : [NSMutableDictionary new];
            NSMutableArray* contentType = [NSMutableArray new];
            
            [headerFields setObject: [@(contentLength) stringValue] forKey:@"Content-Length"];
            
            if (mimeType) {
                [contentType addObject:mimeType];
            }
            
            if (encoding) {
                if ([encoding isEqualToString:@"utf8"]) {
                    encoding = @"utf-8";
                }
                [contentType addObject:[NSString stringWithFormat:@"charset=%@", encoding]];
            }
            
            if ([contentType count] > 0) {
                [headerFields setObject:[contentType componentsJoinedByString:@"; "] forKey:@"Content-Type"];
            }
            
            NSHTTPURLResponse* const response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                                            statusCode:httpStatusCode
                                                                           HTTPVersion:@"HTTP/1.1"
                                                                          headerFields:[headerFields copy]];
            [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
            
            if ([data isKindOfClass:[NSData class]]) {
                [self.client URLProtocol:self didLoadData:data];
            }
            else if ([data isKindOfClass:[NSURL class]]) {
                @autoreleasepool {
                    NSURL* const url = data;
                    NSFileHandle* handle = [NSFileHandle fileHandleForReadingAtPath:url.path];
                    static const NSInteger limit = 1024 * 1024;
                    while (true) {
                        @autoreleasepool {
                        NSData* data = [handle readDataOfLength:limit];
                            if ([data length] > 0) {
                                [self.client URLProtocol:self didLoadData:data];
                            }
                            else {
                                break;
                            }
                        }
                    }
                }
            }
            
            [self.client URLProtocolDidFinishLoading:self];
        };
        
        const NSURLProtocolInterceptorFailureDataCompletion failureCompletion = ^(NSError* error) {
            assert(completed == NO);
            completed = YES;
            [self.client URLProtocol:self didFailWithError:error];
        };
        
        for (NSDictionary* info in filters) {
            const NSURLProtocolInterceptorRequestFilter f = (NSURLProtocolInterceptorRequestFilter)info[@"block"];
            f(self.request, successCompletion, failureCompletion);
            if (completed){
                return;
            }
        }
    }
    
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    self.connection = [NSURLConnection connectionWithRequest:newRequest delegate:self];
    #pragma clang diagnostic pop
}

- (void) stopLoading {
    [self.connection cancel];
}

#pragma mark - NSURLConnectionDelegate

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.client URLProtocolDidFinishLoading:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}

@end


