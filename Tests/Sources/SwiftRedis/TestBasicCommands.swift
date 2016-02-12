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


public struct TestBasicCommands: XCTestCase {
    public var allTests : [(String, () throws -> Void)] {
        return [
            ("test_setAndGet", test_setAndGet),
            ("test_SetExistOptions", test_SetExistOptions),
            ("test_SetExpireOptions", test_SetExpireOptions),
            ("test_incrDecr", test_incrDecr),
            ("test_incrFloats", test_incrFloats)
        ]
    }
    
    var key1: String { return "test1" }
    var key2: String { return "test2" }
    var key3: String { return "test3" }
    var key4: String { return "test4" }
    
    func localSetup(block: () -> Void) {
        connectRedis() {(error: NSError?) in
            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
        
            redis.del(self.key1, self.key2, self.key3, self.key4) {(deleted: Int?, error: NSError?) in
                block()
            }
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
}
