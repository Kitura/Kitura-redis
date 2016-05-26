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

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import Foundation
import XCTest


public class TestListCommands: XCTestCase {
    static var allTests : [(String, TestListCommands -> () throws -> Void)] {
        return [
            ("test_lpushAndLpop", test_lpushAndLpop),
            ("test_binaryLpushAndLpop", test_binaryLpushAndLpop),
            ("test_rpushAndRpop", test_rpushAndRpop),
            ("test_binaryRpushAndRpop", test_binaryRpushAndRpop)
        ]
    }
    
    var key1: String { return "test1" }
    var key2: String { return "test2" }
    var key3: String { return "test3" }
    
    func localSetup(block: () -> Void) {
        connectRedis() {(error: NSError?) in
            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
        
            redis.del(self.key1, self.key2, self.key3) {(deleted: Int?, error: NSError?) in
                block()
            }
        }
    }
    
    func test_lpushAndLpop() {
        localSetup() {
            let value1 = "testing 1 2 3"
            let value2 = "over the hill and through the woods"
            let value3 = "to grandmothers house we go"
            
            redis.lpush(self.key1, values: value1, value2) {(numberSet: Int?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssertNotNil(numberSet, "Result of lpush was nil, without an error")
                XCTAssertEqual(numberSet!, 2, "Failed to lpush \(self.key1)")
                
                redis.lpop(self.key1) {(popedValue: RedisString?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(popedValue, "Result of lpop was nil, but \(self.key1) should exist")
                    XCTAssertEqual(popedValue!, RedisString(value2), "Popped \(popedValue) for \(self.key1) instead of \(value2)")
                    
                    redis.lpushx(self.key1, value: value3) {(numberSet: Int?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(numberSet, "Result of lpushx was nil, without an error")
                        XCTAssertEqual(numberSet!, 2, "Failed to lpushx \(self.key1)")
                            
                        redis.lpop(self.key3) {(popedValue: RedisString?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertNil(popedValue, "Result of lpop was not nil, but \(self.key3) does not exist")
                            
                            redis.lpushx(self.key3, value: value3) {(numberSet: Int?, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssertNotNil(numberSet, "Result of lpushx was nil, without an error")
                                XCTAssertEqual(numberSet!, 0, "lpushx to \(self.key3) should have returned 0 (list not found) returned \(numberSet!)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func test_binaryLpushAndLpop() {
        localSetup() {
            let binaryValue1 = RedisString("testing 1 2 3")
            let binaryValue2 = RedisString("over the hill and through the woods")
            let binaryValue3 = RedisString("to grandmothers house we go")
            
            redis.lpush(self.key2, values: binaryValue2, binaryValue1) {(numberSet: Int?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssertNotNil(numberSet, "Result of lpush was nil, without an error")
                XCTAssertEqual(numberSet!, 2, "Failed to lpush \(self.key2)")
                        
                redis.lpop(self.key2) {(popedValue: RedisString?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(popedValue, "Result of lpop was nil, but \(self.key2) should exist")
                    XCTAssertEqual(popedValue!, binaryValue1, "Popped \(popedValue) for \(self.key2) instead of \(binaryValue1)")
                    
                    redis.lpushx(self.key2, value: binaryValue3) {(numberSet: Int?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(numberSet, "Result of lpushx was nil, without an error")
                        XCTAssertEqual(numberSet!, 2, "Failed to lpushx to \(self.key2) returned \(numberSet!)")
                            
                        redis.lpop(self.key3) {(popedValue: RedisString?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertNil(popedValue, "Result of lpop was not nil, but \(self.key3) does not exist")
                            
                            redis.lpushx(self.key3, value: binaryValue3) {(numberSet: Int?, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssertNotNil(numberSet, "Result of lpushx was nil, without an error")
                                XCTAssertEqual(numberSet!, 0, "lpushx to \(self.key3) should have returned 0 (list not found) returned \(numberSet!)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func test_rpushAndRpop() {
        localSetup() {
            let value1 = "testing 1 2 3"
            let value2 = "over the hill and through the woods"
            let value3 = "to grandmothers house we go"
            
            redis.rpush(self.key1, values: value1, value2) {(numberSet: Int?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssertNotNil(numberSet, "Result of rpush was nil, without an error")
                XCTAssertEqual(numberSet!, 2, "Failed to rpush \(self.key1)")
                
                redis.rpop(self.key1) {(popedValue: RedisString?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(popedValue, "Result of rpop was nil, but \(self.key1) should exist")
                    XCTAssertEqual(popedValue!, RedisString(value2), "Popped \(popedValue) for \(self.key1) instead of \(value2)")
                    
                    redis.rpushx(self.key1, value: value3) {(numberSet: Int?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(numberSet, "Result of rpushx was nil, without an error")
                        XCTAssertEqual(numberSet!, 2, "Failed to rpushx \(self.key1)")
                        
                        redis.rpop(self.key3) {(popedValue: RedisString?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertNil(popedValue, "Result of rpop was not nil, but \(self.key3) does not exist")
                            
                            redis.rpushx(self.key3, value: value3) {(numberSet: Int?, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssertNotNil(numberSet, "Result of rpushx was nil, without an error")
                                XCTAssertEqual(numberSet!, 0, "rpushx to \(self.key3) should have returned 0 (list not found) returned \(numberSet!)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func test_binaryRpushAndRpop() {
        localSetup() {
            let binaryValue1 = RedisString("testing 1 2 3")
            let binaryValue2 = RedisString("over the hill and through the woods")
            let binaryValue3 = RedisString("to grandmothers house we go")
            
            redis.rpush(self.key2, values: binaryValue2, binaryValue1) {(numberSet: Int?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssertNotNil(numberSet, "Result of rpush was nil, without an error")
                XCTAssertEqual(numberSet!, 2, "Failed to rpush \(self.key2)")
                
                redis.rpop(self.key2) {(popedValue: RedisString?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(popedValue, "Result of rpop was nil, but \(self.key2) should exist")
                    XCTAssertEqual(popedValue!, binaryValue1, "Popped \(popedValue) for \(self.key2) instead of \(binaryValue1)")
                    
                    redis.rpushx(self.key2, value: binaryValue3) {(numberSet: Int?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(numberSet, "Result of rpushx was nil, without an error")
                        XCTAssertEqual(numberSet!, 2, "Failed to rpushx to \(self.key2) returned \(numberSet!)")
                        
                        redis.rpop(self.key3) {(popedValue: RedisString?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertNil(popedValue, "Result of rpop was not nil, but \(self.key3) does not exist")
                            
                            redis.rpushx(self.key3, value: binaryValue3) {(numberSet: Int?, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssertNotNil(numberSet, "Result of rpushx was nil, without an error")
                                XCTAssertEqual(numberSet!, 0, "rpushx to \(self.key3) should have returned 0 (list not found) returned \(numberSet!)")
                            }
                        }
                    }
                }
            }
        }
    }
    
}
