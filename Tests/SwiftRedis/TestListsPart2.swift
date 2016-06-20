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


public class TestListsPart2: XCTestCase {
    static var allTests : [(String, (TestListsPart2) -> () throws -> Void)] {
        return [
            ("test_lindexLinsertAndLlen", test_lindexLinsertAndLlen),
            ("test_binaryLindexLinsertAndLlen", test_binaryLindexLinsertAndLlen),
            ("test_lsetAndLtrim", test_lsetAndLtrim),
            ("test_binaryLsetAndLtrim", test_binaryLsetAndLtrim),
            ("test_rpoplpush", test_rpoplpush)
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
    
    func test_lindexLinsertAndLlen() {
        localSetup() {
            let value1 = "testing 1 2 3"
            let value2 = "over the hill and through the woods"
            let value3 = "to grandmothers house we go"
            
            redis.lpush(self.key1, values: value1, value3) {(numberSet: Int?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                
                redis.linsert(self.key1, before: true, pivot: value3, value: value2) {(listSize: Int?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(listSize, "Result of linsert was nil, but \(self.key1) should exist")
                    XCTAssertEqual(listSize!, 3, "Returned \(listSize!) for \(self.key1) instead of 3")
                    
                    redis.llen(self.key1) {(listSize: Int?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(listSize, "Result of llen was nil, but \(self.key1) should exist")
                        XCTAssertEqual(listSize!, 3, "Returned \(listSize!) for \(self.key1) instead of 3")
                        
                        redis.lindex(self.key1, index: 2) {(retrievedValue: RedisString?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertNotNil(retrievedValue, "Result of lindex was nil, but \(self.key1) should exist")
                            XCTAssertEqual(retrievedValue!, RedisString(value1), "Result of lindex was \(retrievedValue!). It should have been \(value1)")
                        }
                    }
                }
            }
        }
    }
    
    func test_binaryLindexLinsertAndLlen() {
        localSetup() {
            let binaryValue1 = RedisString("testing 1 2 3")
            let binaryValue2 = RedisString("over the hill and through the woods")
            let binaryValue3 = RedisString("to grandmothers house we go")
            
            redis.lpush(self.key1, values: binaryValue2, binaryValue1) {(numberSet: Int?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                
                redis.linsert(self.key1, before: false, pivot: binaryValue2, value: binaryValue3) {(listSize: Int?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(listSize, "Result of linsert was nil, but \(self.key1) should exist")
                    XCTAssertEqual(listSize!, 3, "Returned \(listSize!) for \(self.key1) instead of 3")
                    
                    redis.llen(self.key1) {(listSize: Int?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(listSize, "Result of llen was nil, but \(self.key1) should exist")
                        XCTAssertEqual(listSize!, 3, "Returned \(listSize!) for \(self.key1) instead of 3")
                        
                        redis.lindex(self.key1, index: 2) {(retrievedValue: RedisString?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertNotNil(retrievedValue, "Result of lindex was nil, but \(self.key1) should exist")
                            XCTAssertEqual(retrievedValue!, binaryValue3, "Result of lindex was \(retrievedValue!). It should have been \(binaryValue2)")
                        }
                    }
                }
            }
        }
    }
    
    func test_lsetAndLtrim() {
        localSetup() {
            let value1 = "testing 1 2 3"
            let value2 = "over the hill and through the woods"
            let value3 = "to grandmothers house we go"
            
            redis.lpush(self.key1, values: value1, value3) {(numberSet: Int?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                
                redis.lset(self.key1, index: 1, value: value2) {(wasOK: Bool, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssert(wasOK, "lset failed")
                    
                    redis.lindex(self.key1, index: 1) {(valueReturned: RedisString?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(valueReturned, "Returned values of lindex was nil, even though no error occurred.")
                        XCTAssertEqual(valueReturned!, RedisString(value2), "lindex returned \(valueReturned!). It should have returned \(value2)")
                    
                        redis.ltrim(self.key1, start: 0, end: 0) {(wasOK: Bool, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssert(wasOK, "ltrim failed")
                     
                            redis.llen(self.key1) {(listLength: Int?, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssertNotNil(listLength, "Returned values of llen was nil, even though no error occurred.")
                                XCTAssertEqual(listLength!, 1, "The length of the list was \(listLength!). It should have been 1.")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func test_binaryLsetAndLtrim() {
        localSetup() {
            let binaryValue1 = RedisString("testing 1 2 3")
            let binaryValue2 = RedisString("over the hill and through the woods")
            let binaryValue3 = RedisString("to grandmothers house we go")
            
            redis.lpush(self.key2, values: binaryValue3, binaryValue2) {(numberSet: Int?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                
                redis.lset(self.key2, index: 1, value: binaryValue1) {(wasOK: Bool, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssert(wasOK, "lset failed")
                    
                    redis.lindex(self.key2, index: 1) {(valueReturned: RedisString?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(valueReturned, "Returned values of lindex was nil, even though no error occurred.")
                        XCTAssertEqual(valueReturned!, binaryValue1, "lindex returned \(valueReturned!). It should have returned \(binaryValue1)")
                        
                        redis.ltrim(self.key2, start: 0, end: 0) {(wasOK: Bool, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssert(wasOK, "ltrim failed")
                            
                            redis.llen(self.key2) {(listLength: Int?, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssertNotNil(listLength, "Returned values of llen was nil, even though no error occurred.")
                                XCTAssertEqual(listLength!, 1, "The length of the list was \(listLength!). It should have been 1.")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func test_rpoplpush() {
        localSetup() {
            let value1 = "testing 1 2 3"
            let value2 = "over the hill and through the woods"
            let value3 = "to grandmothers house we go"
            
            redis.rpush(self.key1, values: value1, value2, value3) {(numberSet: Int?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                
                redis.rpoplpush(self.key1, destination: self.key2) {(valueReturned: RedisString?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(valueReturned, "Returned values of rpoplpush was nil, even though no error occurred.")
                    XCTAssertEqual(valueReturned!, RedisString(value3), "rpoplpush returned \(valueReturned!). It should have returned \(value3)")
                    
                    redis.llen(self.key1) {(listLength: Int?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(listLength, "Returned values of llen was nil, even though no error occurred.")
                        XCTAssertEqual(listLength!, 2, "The length of the list \(self.key1) was \(listLength!). It should have been 2.")
                        
                        redis.llen(self.key2) {(listLength: Int?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertNotNil(listLength, "Returned values of llen was nil, even though no error occurred.")
                            XCTAssertEqual(listLength!, 1, "The length of the list \(self.key2) was \(listLength!). It should have been 1.")
                        }
                    }
                }
            }
        }
    }
    
}
