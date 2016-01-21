//
//  TestIssueCommand.swift
//  Phoenix
//
//  Created by Samuel Kallner on 23/12/2015.
//  Copyright © 2015 Daniel Firsht. All rights reserved.
//

import SwiftRedis

import Foundation
import XCTest

class TestIssueCommand: XCTestCase {
    var allTests : [(String, () throws -> Void)] {
        return [
            ("test_SetAndGet", test_SetAndGet)
        ]
    }
    
    func test_SetAndGet() {
        connectRedis() {(error: NSError?) in
            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")

            let key = "plover"
            let value = "613"
            
            redis.issueCommand("SET", key, value) {(response: RedisResponse) in
                switch response {
                    case .Error(let error):
                        XCTFail("Failed to SET \(key) to \(value). Error message=\(error)")
                    
                    case .Status(let str):
                        XCTAssertEqual(str, "OK", "SET result value was NOT 'OK'. It was [\(str)]")
                    
                        redis.issueCommand("GET", key) {(response: RedisResponse) in
                            switch response {
                                case .Error(let error):
                                    XCTFail("Failed to GET \(key). Error message=\(error)")
                            
                                case .StringValue(let str):
                                    XCTAssertEqual(str.asString, value,  "GET of \(key) result was NOT [\(value)]")
                            
                                default:
                                    XCTFail("Received a RedisResponse of \(response) from a GET")
                            }
                        }
                    
                    default:
                        XCTFail("Received a RedisResponse of \(response) from a SET")
                }
            }
        }
    }
}
