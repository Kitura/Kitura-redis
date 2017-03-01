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
            ("test_scanMatch", test_scanMatch),
            ("test_scanCount", test_scanCount),
            ("test_scanMatchCount", test_scanMatchCount),
            ("test_touchNone", test_touchNone),
            ("test_touchOne", test_touchOne),
            ("test_touchMulti", test_touchMulti),
            ("test_type", test_type),
            ("test_typeBadKey", test_typeBadKey)
        ]
    }
    
    var exp: XCTestExpectation?
    
    var key1 = "test1"
    var key2 = "test2"
    var key3 = "test3"
    var key4 = "test4"
    
    private func setup(major: Int, minor: Int, micro: Int, callback: () -> Void) {
        connectRedis() {(err) in
            guard err == nil else {
                XCTFail("\(err)")
                return
            }
            redis.info { (info: RedisInfo?, _) in
                if let info = info, info.server.checkVersionCompatible(major: major, minor: minor, micro: micro) {
                    redis.flushdb(callback: { (_, _) in
                        callback()
                    })
                }
            }
        }
    }
    
    private func setup(major: Int, minor: Int, micro: Int) throws -> Bool {
        try connectRedis()
        guard try redis.info().server.checkVersionCompatible(major: major, minor: minor, micro: micro) else {
            return false
        }
        return try redis.flushdb()
    }
        
    func test_setAndGet() {
        setup(major: 1, minor: 0, micro: 0) {
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
        setup(major: 1, minor: 0, micro: 0) {
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
        setup(major: 1, minor: 0, micro: 0) {
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
        setup(major: 1, minor: 0, micro: 0) {
            exp = expectation(description: "Return all keys matching `pattern`.")
            
            redis.mset((key1, "1"), (key2, "2"), (key3, "3"), (key4, "4"), callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                
                redis.keys(pattern: "*1", callback: { (res, err) in
                    XCTAssertNil(err, "\(err)")
                    XCTAssertEqual(res?.count, 1)
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_randomkey() {
        setup(major: 1, minor: 0, micro: 0) {
            exp = expectation(description: "Return a random key from the currently selected database.")
            
            redis.mset((key1, "1"), (key2, "2"), (key3, "3"), (key4, "4"), callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                
                redis.randomkey(callback: { (res, err) in
                    XCTAssertNil(err, "\(err)")
                    XCTAssertNotNil(res)
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_incrDecr() {
        setup(major: 1, minor: 0, micro: 0) {
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
        setup(major: 2, minor: 6, micro: 0) {
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
        setup(major: 1, minor: 0, micro: 0) {
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
        setup(major: 2, minor: 8, micro: 0) {
            exp = expectation(description: "Iterate over some elements.")
            
            redis.mset((key1, "val1"), (key2, "val2"), callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                
                redis.scan(cursor: 0, callback: { (newCursor, res, err) in
                    XCTAssertNil(err, "\(err)")
                    XCTAssertNotNil(newCursor)
                    XCTAssertEqual(res?.count, 2)
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_scanMatch() {
        setup(major: 2, minor: 8, micro: 0) {
            exp = expectation(description: "Iterate over elements matching a pattern.")
            
            redis.mset((key1, "val1"), (key2, "val2"), callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                
                redis.scan(cursor: 0, match: "*1", callback: { (newCursor, res, err) in
                    XCTAssertNil(err, "\(err)")
                    XCTAssertNotNil(newCursor)
                    XCTAssertNotNil(res)
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_scanCount() {
        setup(major: 2, minor: 8, micro: 0) {
            exp = expectation(description: "Iterate over a specified number of elements.")
            
            redis.mset((key1, "val1"), (key2, "val2"), callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                
                redis.scan(cursor: 0, count: 2, callback: { (newCursor, res, err) in
                    XCTAssertNil(err, "\(err)")
                    XCTAssertNotNil(newCursor)
                    XCTAssertNotNil(res)
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_scanMatchCount() {
        setup(major: 2, minor: 8, micro: 0) {
            exp = expectation(description: "Iterate over a specified number of elements matching a pattern.")
            
            redis.mset((key1, "val1"), (key2, "val2"), callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                
                redis.scan(cursor: 0, match: "*1", count: 1, callback: { (newCursor, res, err) in
                    XCTAssertNil(err, "\(err)")
                    XCTAssertNotNil(newCursor)
                    XCTAssertNotNil(res)
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_touchNone() {
        setup(major: 3, minor: 2, micro: 1) {
            exp = expectation(description: "Return 0 for bad key.")
            
            redis.touch(key: key1, callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssertEqual(res, 0)
                exp?.fulfill()
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_touchOne() {
        setup(major: 3, minor: 2, micro: 1) {
            exp = expectation(description: "Alters the last access time of a key(s).")
            
            redis.set(key1, value: "Hello", callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                
                redis.touch(key: key1, callback: { (res, err) in
                    XCTAssertNil(err, "\(err)")
                    XCTAssertEqual(res, 1)
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_touchMulti() {
        setup(major: 3, minor: 2, micro: 1) {
            exp = expectation(description: "Alters the last access time of a key(s).")
            
            redis.mset((key1, "val2"), (key2, "val2"), callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                
                redis.touch(key: key1, keys: key2, callback: { (res, err) in
                    XCTAssertNil(err, "\(err)")
                    XCTAssertEqual(res, 2)
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_type() {
        setup(major: 1, minor: 0, micro: 0) {
            exp = expectation(description: "Returns the string representation of the type of the value stored at key.")
            
            redis.set(key1, value: "Hello", callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssert(res)
                
                redis.type(key: key1, callback: { (res, err) in
                    XCTAssertNil(err, "\(err)")
                    XCTAssertEqual(res, "string")
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_typeBadKey() {
        setup(major: 1, minor: 0, micro: 0) {
            exp = expectation(description: "Return `none` for bad key.")
            
            redis.type(key: key1, callback: { (res, err) in
                XCTAssertNil(err, "\(err)")
                XCTAssertEqual(res, "none")
                exp?.fulfill()
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
}
