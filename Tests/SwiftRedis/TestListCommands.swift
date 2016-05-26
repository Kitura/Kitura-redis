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
            ("test_lpushAndLpop", test_lpushAndLpop)
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
            let binaryValue1 = RedisString("testing 1 2 3")
            let binaryValue2 = RedisString("over the hill and through the woods")
            
            redis.lpush(self.key1, values: value1, value2) {(numberSet: Int?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssertNotNil(numberSet, "Result of lpush was nil, without an error")
                XCTAssertEqual(numberSet!, 2, "Failed to lpush \(self.key1)")
                
                redis.lpop(self.key1) {(popedValue: RedisString?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(popedValue, "Result of lpop was nil, but \(self.key1) should exist")
                    XCTAssertEqual(popedValue!, RedisString(value2), "Popped \(popedValue) for \(self.key1) instead of \(value2)")
                    
                    redis.lpush(self.key2, values: binaryValue2, binaryValue1) {(numberSet: Int?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(numberSet, "Result of lpush was nil, without an error")
                        XCTAssertEqual(numberSet!, 2, "Failed to lpush \(self.key2)")
                        
                        redis.lpop(self.key2) {(popedValue: RedisString?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertNotNil(popedValue, "Result of lpop was nil, but \(self.key2) should exist")
                            XCTAssertEqual(popedValue!, binaryValue1, "Popped \(popedValue) for \(self.key2) instead of \(binaryValue1)")
                            
                            redis.lpop(self.key3) {(popedValue: RedisString?, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssertNil(popedValue, "Result of lpop was not nil, but \(self.key3) does not exist")
                            }
                        }
                    }
                }
            }
        }
    }
    
}
