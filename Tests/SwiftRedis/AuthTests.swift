//
//  AuthTests.swift
//  Phoenix
//
//  Created by Samuel Kallner on 30/12/2015.
//  Copyright © 2015 Daniel Firsht. All rights reserved.
//

#if os(Linux)
    import Glibc
#elseif os(OSX)
    import Darwin
#endif

import Foundation
import XCTest

@testable import SwiftRedis

public class AuthTests: XCTestCase {
    
    let key = "authTestKey"
    let host = "localhost"
    let password = readPassword()
    
    public var allTests : [(String, () throws -> Void)] {
        return [
            ("test_ConnectWithAuth", test_ConnectWithAuth)
        ]
    }
    
    func test_ConnectWithAuth() {
        // reinit redis var in CommonUtils to reset authentication
        redis = Redis()
        connectRedis(false) {(error: NSError?) in
            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
            
            let expectedValue = "Hi ho, hi ho, we are so secured"
            redis.set(self.key, value: expectedValue) {(wasSet: Bool, error: NSError?) in
                XCTAssertNotNil(error, "Error was nil")
                XCTAssertFalse(wasSet, "Set \(self.key) without authenticating")
                
                redis.auth(self.password) {(error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    
                    redis.set(self.key, value: expectedValue) {(wasSet: Bool, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssert(wasSet, "Failed to set \(self.key)")
                        
                        redis.get(self.key) {(returnedValue: RedisString?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertEqual(returnedValue!.asString, expectedValue, "Returned value was not '\(expectedValue)'")
                        }
                    }
                }
            }
        }
    }
}
