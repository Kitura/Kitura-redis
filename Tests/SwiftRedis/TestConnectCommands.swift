/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import SwiftRedis

import Foundation
import XCTest

public class TestConnectCommands: XCTestCase {
    public var allTests : [(String, () throws -> Void)] {
        return [
            ("test_pingAndEcho", test_pingAndEcho),
            ("test_select", test_select)
        ]
    }
    
    func test_pingAndEcho() {
        connectRedis() {(error: NSError?) in
            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
            
            redis.ping() {(error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                let pingText = "Hello, hello, hello, hi there"
                redis.ping(pingText) {(error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    
                    let echoText = "Echo, echo, echo......"
                    redis.echo(echoText) {(text: RedisString?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(text, "Received a nil for echo text")
                        XCTAssertEqual(text!.asString, echoText, "Echo returned '\(text!)'. Should have returned '\(echoText)'.")
                    }
                }
            }
        }
    }
    
    func selectTestSetup(callback: () -> Void) {
        connectRedis() {(error: NSError?) in
            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
            
            redis.select(1) {(error: NSError?) in
                redis.del(self.key) {(count: Int?, error: NSError?) in
                    redis.select(0) {(error: NSError?) in
                        callback()
                    }
                }
            }
        }
    }
    
    let key = "selectKey"
    
    func test_select() {
        selectTestSetup() {
            let expectedValue = "testing 1 2 3"
            let newValue = "xyzzy-plover"
            
            redis.set(self.key, value: expectedValue) {(wasSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssert(wasSet, "Failed to set \(self.key)")
                    
                redis.select(99) {(error: NSError?) in
                    XCTAssertNotNil(error, "Database 99 shouldn't have been selected")
                        
                    redis.select(1) {(error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        
                        redis.get(self.key) {(returnedValue: RedisString?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertNil(returnedValue, "Returned value was not nil. Was '\(returnedValue)'")
                                
                            redis.set(self.key, value: newValue) {(wasSet: Bool, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssert(wasSet, "Failed to set \(self.key)")
                                
                                redis.select(0) {(error: NSError?) in
                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                    
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
        }
    }
}