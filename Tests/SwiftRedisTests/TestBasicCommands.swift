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
import Dispatch

public class TestBasicCommands: XCTestCase {
    static var allTests: [(String, (TestBasicCommands) -> () throws -> Void)] {
        return [
            ("test_setAndGet", test_setAndGet),
            ("test_SetExistOptions", test_SetExistOptions),
            ("test_SetExpireOptions", test_SetExpireOptions),
            ("test_keys", test_keys),
            ("test_randomkey", test_randomkey),
            ("test_incrDecr", test_incrDecr),
            ("test_incrFloats", test_incrFloats),
            ("test_empty", test_empty),
            ("test_scan", test_scan),
            ("test_scanPattern", test_scanPattern),
            ("test_scanCount", test_scanCount),
            ("test_touchNone", test_touchNone),
            ("test_touchOne", test_touchOne),
            ("test_touchMulti", test_touchMulti),
            ("test_type", test_type),
            ("test_typeBadKey", test_typeBadKey)
        ]
    }

    var key1: String { return "test1" }
    var key2: String { return "test2" }
    var key3: String { return "test3" }
    var key4: String { return "test4" }

    func localSetup(block: () -> Void) {
        connectRedis() {(err: NSError?) in
            XCTAssertNil(err, "\(err)")

//            redis.del(key1, key2, key3, key4, callback: { (res, err) in
//                XCTAssertNil(err, "\(err)")
//                block()
//            })
            
            redis.flushdb(callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                block()
            })
        }
    }

    func test_setAndGet() {
        localSetup() {
            let expectedValue = "testing 1 2 3"
            let newValue = "xyzzy-plover"

            redis.set(self.key1, value: expectedValue) {(wasSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssert(wasSet, "Failed to set \(self.key1)")

                redis.get(self.key1) {(returnedValue: RedisString?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertEqual(returnedValue!.asString, expectedValue, "Returned value was not '\(expectedValue)'")

                    redis.getSet(self.key1, value: newValue) {(returnedValue: RedisString?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertEqual(returnedValue!.asString, expectedValue, "Returned value was not '\(expectedValue)'")

                        redis.get(self.key1) {(returnedValue: RedisString?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertEqual(returnedValue!.asString, newValue, "Returned value was not '\(newValue)'")
                        }
                    }
                }
            }
        }
    }

    func test_SetExistOptions() {
        localSetup() {
            let expectedValue = "hi ho, hi ho, it's off to test we go"
            let newValue = "A testing we go, a testing we go"

            redis.set(self.key2, value: expectedValue, exists: true) {(wasSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssertFalse(wasSet, "Shouldn't have set \(self.key2)")

                redis.get(self.key2) {(returnedValue: RedisString?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNil(returnedValue, "\(self.key2) shouldn't exist")

                    redis.set(self.key2, value: expectedValue, exists: false) {(wasSet: Bool, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssert(wasSet, "Failed to set \(self.key2)")

                        redis.get(self.key2) {(returnedValue: RedisString?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertEqual(returnedValue!.asString, expectedValue, "Returned value was not '\(expectedValue)'")

                            redis.set(self.key2, value: newValue, exists: false) {(wasSet: Bool, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssertFalse(wasSet, "Shouldn't have set \(self.key2)")

                                redis.del(self.key2) {(deleted: Int?, error: NSError?) in
                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")

                                    redis.set(self.key2, value: newValue, exists: false) {(wasSet: Bool, error: NSError?) in
                                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                        XCTAssert(wasSet, "Failed to set \(self.key2)")

                                        redis.get(self.key2) {(returnedValue: RedisString?, error: NSError?) in
                                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                            XCTAssertEqual(returnedValue!.asString, newValue, "Returned value was not '\(newValue)'")
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

    func test_SetExpireOptions() {
        localSetup() {
            let expectedValue = "hi ho, hi ho, it's off to test we go"

            redis.set(self.key3, value: expectedValue, expiresIn: 2.750) {(wasSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssert(wasSet, "Failed to set \(self.key3)")

                redis.get(self.key3) {(returnedValue: RedisString?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertEqual(returnedValue!.asString, expectedValue, "Returned value was not '\(expectedValue)'")

                    usleep(3000000)

                    redis.get(self.key3) {(returnedValue: RedisString?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNil(returnedValue, "\(self.key3) shouldn't exist any more")
                    }
                }
            }
        }
    }

    func test_keys() {
        let exp = expectation(description: "Return all keys matching `pattern`.")
        localSetup {
            redis.mset(("one", "1"), ("two", "2"), ("three", "3"), ("four", "4"), callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                
                redis.keys(pattern: "*o*", callback: { (res, err) in
                    XCTAssertNil(err, "\(err)")
                    XCTAssertEqual(res?.count, 3)
                    exp.fulfill()
                })
            })
        }
        waitForExpectations(timeout: 5) { (err) in
            XCTAssertNil(err, "\(err)")
        }
    }
    
    func test_randomkey() {
        let exp = expectation(description: "Return a random key from the currently selected database.")
        localSetup {
            redis.mset(("one", "1"), ("two", "2"), ("three", "3"), ("four", "4"), callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                
                redis.randomkey(callback: { (res, err) in
                    XCTAssertNil(err, "\(err)")
                    XCTAssertNotNil(res)
                    exp.fulfill()
                })
            })
        }
        waitForExpectations(timeout: 5) { (err) in
            XCTAssertNil(err, "\(err)")
        }
    }
    
    func test_incrDecr() {
        localSetup() {
            var theValue=101

            redis.set(self.key1, value: String(theValue)) {(wasSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssert(wasSet, "Failed to set \(self.key1)")

                redis.incr(self.key1) {(newValue: Int?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(newValue, "Result of an INCR shouldn't be nil")
                    XCTAssertEqual(theValue+1, newValue!, "The returned value wasn't \(theValue+1)")
                    theValue = newValue!

                    redis.decr(self.key1) {(newValue: Int?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(newValue, "Result of an DECR shouldn't be nil")
                        XCTAssertEqual(theValue-1, newValue!, "The returned value wasn't \(theValue-1)")
                        theValue = newValue!

                        redis.decr(self.key2) {(newValue: Int?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertNotNil(newValue, "Result of an DECR shouldn't be nil")
                            XCTAssertEqual(-1, newValue!, "The returned value wasn't \(-1)")

                            redis.incr(self.key1, by: 10) {(newValue: Int?, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssertNotNil(newValue, "Result of an INCR shouldn't be nil")
                                XCTAssertEqual(theValue+10, newValue!, "The returned value wasn't \(theValue+10)")
                                theValue = newValue!

                                redis.decr(self.key1, by: 5) {(newValue: Int?, error: NSError?) in
                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                    XCTAssertNotNil(newValue, "Result of an DECR shouldn't be nil")
                                    XCTAssertEqual(theValue-5, newValue!, "The returned value wasn't \(theValue-5)")
                                    theValue = newValue!
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func test_incrFloats() {
        localSetup() {
            var theValue: Double = 84.75

            redis.set(self.key3, value: String(theValue)) {(wasSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssert(wasSet, "Failed to set \(self.key3)")

                let incValue: Float = 12.5
                redis.incr(self.key3, byFloat: incValue) {(newValue: RedisString?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(newValue, "Result of an INCRBYFLOAT shouldn't be nil")
                    XCTAssertEqual(theValue+Double(incValue), newValue!.asDouble, "The returned value wasn't \(theValue+Double(incValue))")
                    theValue = newValue!.asDouble
                }
            }
        }
    }

    func test_empty() {
        localSetup() {
            let emptyValue = ""

            redis.set(self.key1, value: emptyValue) {(wasSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssert(wasSet, "Failed to set \(self.key1)")

                redis.get(self.key1) {(returnedValue: RedisString?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertEqual(returnedValue!.asString, emptyValue, "Returned value was not '\(emptyValue)'")
                }
            }
        }
    }
    
    func test_scan() {
        let exp = expectation(description: "Iterate over some elements.")
        localSetup {
            let dispatchGroup = DispatchGroup()
            for _ in 0...3 {
                dispatchGroup.enter()
            }
            redis.set(key1, value: "Sa", callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                dispatchGroup.leave()
            })
            redis.set(key2, value: "nt", callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                dispatchGroup.leave()
            })
            redis.set(key3, value: "er", callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                dispatchGroup.leave()
            })
            redis.set(key4, value: "ia", callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                dispatchGroup.leave()
            })
            dispatchGroup.wait()
            
            redis.scan(cursor: 0, callback: { (newCursor, res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssertNotNil(newCursor)
                XCTAssertEqual(res?.count, 4)
                exp.fulfill()
            })
        }
        waitForExpectations(timeout: 5) { (err) in
            XCTAssertNil(err, "\(err)")
        }
    }

    func test_scanPattern() {
        let exp = expectation(description: "Iterate over elements matching a pattern.")
        localSetup {
            let dispatchGroup = DispatchGroup()
            for _ in 0...3 {
                dispatchGroup.enter()
            }
            redis.set(key1, value: "Sa", callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                dispatchGroup.leave()
            })
            redis.set(key2, value: "nt", callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                dispatchGroup.leave()
            })
            redis.set(key3, value: "er", callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                dispatchGroup.leave()
            })
            redis.set(key4, value: "ia", callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                dispatchGroup.leave()
            })
            dispatchGroup.wait()
            
            redis.scan(cursor: 0, match: "*1", callback: { (newCursor, res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssertNotNil(newCursor)
                XCTAssertNotNil(res)
                exp.fulfill()
            })
        }
        waitForExpectations(timeout: 5) { (err) in
            XCTAssertNil(err, "\(err)")
        }
    }
    
    func test_scanCount() {
        let exp = expectation(description: "Iterate over a certain number of elements.")
        localSetup {
            let dispatchGroup = DispatchGroup()
            for _ in 0...3 {
                dispatchGroup.enter()
            }
            redis.set(key1, value: "Sa", callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                dispatchGroup.leave()
            })
            redis.set(key2, value: "nt", callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                dispatchGroup.leave()
            })
            redis.set(key3, value: "er", callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                dispatchGroup.leave()
            })
            redis.set(key4, value: "ia", callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                dispatchGroup.leave()
            })
            dispatchGroup.wait()
            
            redis.scan(cursor: 0, count: 2, callback: { (newCursor, res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssertNotNil(newCursor)
                XCTAssertNotNil(res)
                exp.fulfill()
            })
        }
        waitForExpectations(timeout: 5) { (err) in
            XCTAssertNil(err, "\(err)")
        }
    }
    
    func test_touchNone() {
        let exp = expectation(description: "Alters the last access time of a key(s).")
        localSetup {
            redis.touch(key: key1, callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssertEqual(res, 0)
                exp.fulfill()
            })
        }
        waitForExpectations(timeout: 5) { (err) in
            XCTAssertNil(err, "\(err)")
        }
    }
    
    func test_touchOne() {
        let exp = expectation(description: "Alters the last access time of a key(s).")
        localSetup {
            redis.set(key1, value: "Hello", callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                
                redis.touch(key: key1, callback: { (res, err) in
                    XCTAssertNil(err, "\(err)")
                    XCTAssertEqual(res, 1)
                    exp.fulfill()
                })
            })
        }
        waitForExpectations(timeout: 5) { (err) in
            XCTAssertNil(err, "\(err)")
        }
    }
    
    func test_touchMulti() {
        let exp = expectation(description: "Alters the last access time of a key(s).")
        localSetup {
            redis.set(key1, value: "Hello", callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                
                redis.set(key2, value: "Hello", callback: { (res, err) in
                    XCTAssertNil(err, "\(err)")
                    XCTAssert(res)
                
                    redis.touch(key: key1, keys: key2, callback: { (res, err) in
                        XCTAssertNil(err, "\(err)")
                        XCTAssertEqual(res, 2)
                        exp.fulfill()
                    })
                })
            })
        }
        waitForExpectations(timeout: 5) { (err) in
            XCTAssertNil(err, "\(err)")
        }
    }
    
    func test_type() {
        let exp = expectation(description: "Returns the string representation of the type of the value stored at key.")
        localSetup {
            redis.set(key1, value: "Hello", callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                
                redis.type(key: key1, callback: { (res, err) in
                    XCTAssertNil(err, "\(err)")
                    XCTAssertEqual(res, "string")
                    exp.fulfill()
                })
            })
        }
        waitForExpectations(timeout: 5) { (err) in
            XCTAssertNil(err, "\(err)")
        }
    }
    
    func test_typeBadKey() {
        let exp = expectation(description: "Return `none` for bad key.")
        localSetup {
            redis.type(key: key1, callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssertEqual(res, "none")
                exp.fulfill()
            })
        }
        waitForExpectations(timeout: 5) { (err) in
            XCTAssertNil(err, "\(err)")
        }
    }
}
