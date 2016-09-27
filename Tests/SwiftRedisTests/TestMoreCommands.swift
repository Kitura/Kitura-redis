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

public class TestMoreCommands: XCTestCase {
    static var allTests : [(String, (TestMoreCommands) -> () throws -> Void)] {
        return [
            ("test_msetAndMget", test_msetAndMget),
            ("test_keyManipulation", test_keyManipulation),
            ("test_Move", test_Move),
            ("test_expiration", test_expiration)
        ]
    }
    
    let key1 = "test1"
    let key2 = "test2"
    let key3 = "test3"
    let key4 = "test4"
    let key5 = "test5"
    
    let expVal1 = "Hi ho, hi ho"
    let expVal2 = "it's off to test"
    let expVal3 = "we go"
    let expVal4 = "Testing"
    let expVal5 = "testing 1 2 3"
    
    func test_msetAndMget() {
        setupTests() {
            redis.mset((self.key1, self.expVal1), (self.key2, self.expVal2), (self.key3, self.expVal3)) {(wereSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssert(wereSet, "Keys 1,2,3 should have been set")
                
                redis.get(self.key1) {(value: RedisString?, error:NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertEqual(value!.asString, self.expVal1, "\(self.key1) wasn't set to \(self.expVal1). Instead was \(value)")
                    
                    redis.mget(self.key1, self.key2, self.key4, self.key3) {(values: [RedisString?]?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(values, "Received a nil values array")
                        XCTAssertEqual(values!.count, 4, "Values array didn't have four elements. Had \(values!.count) elements")
                        XCTAssertNotNil(values![0], "Values array [0] was nil")
                        XCTAssertEqual(values![0]!.asString, self.expVal1, "Values array [0] wasn't equal to \(self.expVal1), was \(values![0]!)")
                        XCTAssertNotNil(values![1], "Values array [1] was nil")
                        XCTAssertEqual(values![1]!.asString, self.expVal2, "Values array [1] wasn't equal to \(self.expVal2), was \(values![1]!)")
                        XCTAssertNil(values![2], "Values array [2] wasn't nil. Was \(values![2])")
                        XCTAssertNotNil(values![3], "Values array [3] was nil")
                        XCTAssertEqual(values![3]!.asString, self.expVal3, "Values array [3] wasn't equal to \(self.expVal3), was \(values![3]!)")
                        
                        redis.mset((self.key3, self.expVal3), (self.key4, self.expVal4), (self.key5, self.expVal5), exists: false) {(wereSet: Bool, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertFalse(wereSet, "Keys shouldn't have been set \(self.key3) still has a value")
                            
                            redis.del(self.key3) {(deleted: Int?, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                
                                redis.mset((self.key3, self.expVal3), (self.key4, self.expVal4), (self.key5, self.expVal5), exists: false) {(wereSet: Bool, error: NSError?) in
                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                    XCTAssert(wereSet, "Keys 3,4,5 should have been set")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func test_keyManipulation() {
        setupTests() {
            redis.mset((self.key1, self.expVal1), (self.key2, self.expVal2)) {(wereSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                
                redis.rename(self.key1, newKey: self.key3) {(renamed: Bool, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssert(renamed, "Failed to rename \(self.key1) to \(self.key3)")
                    
                    redis.get(self.key3) {(value: RedisString?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(value, "\(self.key3) should have been found")
                        XCTAssertEqual(value!.asString, self.expVal1, "\(self.key3) should have been equal to \(self.expVal1). Was \(value)")
                        
                        redis.rename(self.key3, newKey: self.key2, exists: false) {(renamed: Bool, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertFalse(renamed, "Shouldn't have renamed \(self.key3) to \(self.key2)")
                            
                            redis.rename(self.key3, newKey: self.key4, exists: false) {(renamed: Bool, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssert(renamed, "Should have renamed \(self.key3) to \(self.key4)")
                                
                                redis.exists(self.key1) {(count: Int?, error: NSError?) in
                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                    XCTAssertNotNil(count, "Count of keys should not be nil")
                                    XCTAssertEqual(count!, 0, "\(self.key1) should not exist")
                                    
                                    redis.exists(self.key4) {(count: Int?, error: NSError?) in
                                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                        XCTAssertNotNil(count, "Count of keys should not be nil")
                                        XCTAssertEqual(count!, 1, "\(self.key4) should exist")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func test_Move() {
        setupTests() {
            redis.select(1) {(error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                
                redis.set(self.key1, value: self.expVal1) {(wasSet: Bool, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    
                    redis.move(self.key1, toDB: 0) {(moved: Bool, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssert(moved, "\(self.key1) wasn't move to DB 0")
                        
                        redis.get(self.key1) {(value: RedisString?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertNil(value, "\(self.key1) should no longer exist in DB 1")
                            
                            redis.select(0) {(error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                
                                redis.get(self.key1) {(value: RedisString?, error: NSError?) in
                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                    XCTAssertNotNil(value, "\(self.key1) should now exist in DB 0")
                                    XCTAssertEqual(value!.asString, self.expVal1, "\(self.key1) should have a value of \(self.expVal1) it has a value of \(value!)")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func test_expiration() {
        setupTests() {
            let expiration = 1.850
            redis.set(self.key1, value: self.expVal1) {(wasSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                
                redis.ttl(self.key1) {(ttl: TimeInterval?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(ttl, "ttl result shouldn't be nil")
                    XCTAssertEqual(ttl, -1.0, "\(self.key1) shouldn't have an expiration. It has \(ttl!)")
                    
                    redis.expire(self.key1, inTime: expiration) {(expirationSet: Bool, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssert(expirationSet, "Expiration for \(self.key1) wasn't set")
                        
                        redis.ttl(self.key1) {(ttl: TimeInterval?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertNotNil(ttl, "ttl result shouldn't be nil")
                            XCTAssert(expiration-0.1 <= ttl! && ttl! <= expiration+0.1, "ttl for \(self.key1) should be approximately \(expiration). It was \(ttl!)")
                            
                            redis.persist(self.key1) {(persistant: Bool, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssert(persistant, "Expiration for \(self.key1) wasn't reset")
                                
                                let timeFromNow = 120.0
                                let date = NSDate(timeIntervalSinceNow: timeFromNow)
                                redis.expire(self.key1, atDate: date) {(expirationSet: Bool, error: NSError?) in
                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                    XCTAssert(expirationSet, "Expiration for \(self.key1) wasn't set")
                                    
                                    redis.ttl(self.key1) {(ttl: TimeInterval?, error: NSError?) in
                                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                        XCTAssertNotNil(ttl, "ttl result shouldn't be nil")
                                        XCTAssert(timeFromNow-1.0 <= ttl! && ttl! <= timeFromNow+1.0, "ttl for \(self.key1) should be approximately \(timeFromNow). It was \(ttl!)")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    private func setupTests(callback: () -> Void) {
        connectRedis() {(error: NSError?) in
            if error != nil {
                XCTFail("Could not connect to Redis")
                return
            }
            
            redis.del(self.key1, self.key2, self.key3, self.key4, self.key5) {(deleted: Int?, error: NSError?) in
                callback()
            }
        }
    }
}
