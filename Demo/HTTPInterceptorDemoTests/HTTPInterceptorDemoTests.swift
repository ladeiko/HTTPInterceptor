//
//  HTTPInterceptorDemoTests.swift
//  HTTPInterceptorDemoTests
//
//  Created by Siarhei Ladzeika on 4/16/19.
//  Copyright © 2019 Siarhei Ladzeika. All rights reserved.
//

import XCTest
import HTTPInterceptor

class HTTPInterceptorDemoTests: XCTestCase {

    func testRequestPreprocessor() {
        
        let expectedFieldName = "X-" + UUID().uuidString
        let expectedFieldValue = UUID().uuidString
        
        let key = HTTPInterceptor.addPreprocessor { (request) in
            if let url = request.url, url.absoluteString == "https://postman-echo.com/get" {
                request.setValue(expectedFieldValue, forHTTPHeaderField: expectedFieldName)
            }
        }
        
        struct PostmanResponse: Decodable {
            var args: [String: String]
            var headers: [String: String]
            var url: String
        }
        
        let decorder = JSONDecoder()
        
        let data1 = try! Data(contentsOf: URL(string: "https://postman-echo.com/get")!)
        let response1 = try! decorder.decode(PostmanResponse.self, from: data1)
        
        XCTAssert(response1.headers[expectedFieldName.lowercased()] == expectedFieldValue)
        
        HTTPInterceptor.removePreprocessor(forKey: key)
        
        let data2 = try! Data(contentsOf: URL(string: "https://postman-echo.com/get")!)
        let response2 = try! decorder.decode(PostmanResponse.self, from: data2)
        
        XCTAssert(response2.headers[expectedFieldName.lowercased()] == nil)
    }

    func testRequestInterceptor() {
        
        let expectedResponse = UUID().uuidString
        var called = 0

        let key = HTTPInterceptor.add { (request, succeeded, failed) in
            if let url = request.url, url.absoluteString == "https://google.com" {
                called += 1
                succeeded(200, expectedResponse.data(using: .utf8), "text/html", "utf-8", nil)
            }
        }
        
        let interceptedActualResponse = try! String(contentsOf: URL(string: "https://google.com")!, encoding: .utf8)
        XCTAssert(expectedResponse == interceptedActualResponse)
        XCTAssert(called == 1)
        
        HTTPInterceptor.remove(forKey: key)
        
        let realActualResponse = try! String(contentsOf: URL(string: "https://google.com")!, encoding: .utf8)
        XCTAssert(expectedResponse != realActualResponse)
        XCTAssert(called == 1)
    }
    
    func testFileMapping() {
        
        let localURL = URL(fileURLWithPath: NSTemporaryDirectory().appending(UUID().uuidString))
        
        self.addTeardownBlock {
            try? FileManager.default.removeItem(at: localURL)
        }
        
        try! FileManager.default.createDirectory(at: localURL, withIntermediateDirectories: true, attributes: nil)
        
        let content = UUID().uuidString
        try! content.write(to: localURL.appendingPathComponent("content.txt"), atomically: true, encoding: .utf8)
        
        let key = HTTPInterceptor.mapUrl(URL(string: "http://hello.com")!, toLocalPathUrl: localURL.appendingPathComponent("content.txt"))
        
        let actual1 = try! String(contentsOf: URL(string: "http://hello.com")!)
        XCTAssert(actual1 == content)
        
        let actual2 = try! String(contentsOf: URL(string: "http://hello.com/")!)
        XCTAssert(actual2 == content)
        
        XCTAssertThrowsError(try String(contentsOf: URL(string: "http://hello.com:80")!))
        XCTAssertThrowsError(try String(contentsOf: URL(string: "http://hello.com/a")!))
        XCTAssertThrowsError(try String(contentsOf: URL(string: "http://hello.com/content2.txt")!))

        HTTPInterceptor.remove(forKey: key)
    }
    
    func testFolderMapping() {
        
        let localURL = URL(fileURLWithPath: NSTemporaryDirectory().appending(UUID().uuidString))
        
        self.addTeardownBlock {
            try? FileManager.default.removeItem(at: localURL)
        }
        
        try! FileManager.default.createDirectory(at: localURL, withIntermediateDirectories: true, attributes: nil)
        
        let content1 = UUID().uuidString
        try! content1.write(to: localURL.appendingPathComponent("content1.txt"), atomically: true, encoding: .utf8)
        
        let content2 = UUID().uuidString
        try! content2.write(to: localURL.appendingPathComponent("content2.txt"), atomically: true, encoding: .utf8)
        
        let key = HTTPInterceptor.mapUrl(URL(string: "http://hello.com")!, toLocalPathUrl: localURL)
        
        let actual1 = try! String(contentsOf: URL(string: "http://hello.com/content1.txt")!)
        XCTAssert(actual1 == content1)
        
        let actual2 = try! String(contentsOf: URL(string: "http://hello.com/content2.txt")!)
        XCTAssert(actual2 == content2)
        
        XCTAssertThrowsError(try String(contentsOf: URL(string: "http://hello.com/content3.txt")!))
        
        HTTPInterceptor.remove(forKey: key)
    }
    
    func testFolderWithSubpathMapping() {
        
        let localURL = URL(fileURLWithPath: NSTemporaryDirectory().appending(UUID().uuidString))
        
        self.addTeardownBlock {
            try? FileManager.default.removeItem(at: localURL)
        }
        
        try! FileManager.default.createDirectory(at: localURL, withIntermediateDirectories: true, attributes: nil)
        
        let content1 = UUID().uuidString
        try! content1.write(to: localURL.appendingPathComponent("content1.txt"), atomically: true, encoding: .utf8)
        
        let content2 = UUID().uuidString
        try! content2.write(to: localURL.appendingPathComponent("content2.txt"), atomically: true, encoding: .utf8)
        
        let key = HTTPInterceptor.mapUrl(URL(string: "http://hello.com/sub")!, toLocalPathUrl: localURL)
        
        XCTAssertThrowsError(try String(contentsOf: URL(string: "http://hello.com")!))
        XCTAssertThrowsError(try String(contentsOf: URL(string: "http://hello.com/")!))
        XCTAssertThrowsError(try String(contentsOf: URL(string: "http://hello.com/sub")!))
        XCTAssertThrowsError(try String(contentsOf: URL(string: "http://hello.com/sub/")!))
        
        let actual1 = try! String(contentsOf: URL(string: "http://hello.com/sub/content1.txt")!)
        XCTAssert(actual1 == content1)
        
        let actual2 = try! String(contentsOf: URL(string: "http://hello.com/sub/content2.txt")!)
        XCTAssert(actual2 == content2)
        
        XCTAssertThrowsError(try String(contentsOf: URL(string: "http://hello.com/sub/content3.txt")!))
        
        HTTPInterceptor.remove(forKey: key)
    }

}
