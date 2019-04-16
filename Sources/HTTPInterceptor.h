//
//  HTTPInterceptor.h
//
//  Created by Siarhei Ladzeika on 16 Apr 19.
//  Copyright © 2019 Siarhei Ladzeika. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^NSURLProtocolInterceptorRequestPreprocessor)(NSMutableURLRequest* request);

typedef void (^NSURLProtocolInterceptorFailureDataCompletion)(NSError* error);
typedef void (^NSURLProtocolInterceptorSuccessDataCompletion)(NSInteger httpStatusCode, id __nullable data, NSString* __nullable mimeType, NSString* __nullable encoding, NSDictionary* __nullable headerFields);
typedef void (^NSURLProtocolInterceptorRequestFilter)(NSURLRequest* request, NSURLProtocolInterceptorSuccessDataCompletion successCompletion, NSURLProtocolInterceptorFailureDataCompletion __nullablefailureCompletion);

typedef NSString* NSURLProtocolInterceptorHandlerKey;

@interface HTTPInterceptor : NSObject

+ (NSURLProtocolInterceptorHandlerKey)addPreprocessor:(NSURLProtocolInterceptorRequestPreprocessor)preprocessor;
+ (void)removePreprocessorForKey:(NSURLProtocolInterceptorHandlerKey)key;
+ (NSURLProtocolInterceptorHandlerKey)addInterceptor:(NSURLProtocolInterceptorRequestFilter)filter;
+ (void)removeInterceptorForKey:(NSURLProtocolInterceptorHandlerKey)key;

+ (NSURLProtocolInterceptorHandlerKey)mapUrl:(NSURL*)url toLocalPathUrl:(NSURL*)localUrl;

@end

NS_ASSUME_NONNULL_END
