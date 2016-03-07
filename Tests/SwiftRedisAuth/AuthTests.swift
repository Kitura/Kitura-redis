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
import SwiftyJSON

let redis = Redis()

public class AuthTests: XCTestCase {
    
    let key = "authTestKey"
    let host = "localhost"
    var password = ""
    
    public var allTests : [(String, () throws -> Void)] {
        return [
            ("test_ConnectWithAuth", test_ConnectWithAuth)
        ]
    }
    
    func test_ConnectWithAuth() {
        readPassword()
        connectRedis() {(error: NSError?) in
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

    func connectRedis (callback: (NSError?) -> Void) {
        if !redis.connected  {
            redis.connect(host, port: 6379, callback: callback)
        }
        else {
            callback(nil)
        }
    }

    func readPassword() {
        // Read in credentials an NSData
        let passwordData = NSData(contentsOfFile: "Tests/SwiftRedisAuth/password.txt")
        XCTAssertNotNil(passwordData, "Failed to read in the password.txt file")

        let password = String(data: passwordData!, encoding:NSUTF8StringEncoding)

        guard
           let passwordLiteral = password
        else {
            XCTFail("Error in password.txt.")
            exit(1)
        }

        self.password = passwordLiteral
    }
}
