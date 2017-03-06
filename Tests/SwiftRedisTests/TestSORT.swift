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
    import Dispatch
#else
    import Darwin
#endif

import Foundation
import XCTest

public class TestSORT: XCTestCase {
    
    static var allTests: [(String, (TestSORT) -> () throws -> Void)] {
        return [
            ("test_sort", test_sort),
            ("test_sortDesc", test_sortDesc),
            ("test_sortAlpha", test_sortAlpha),
            ("test_sortLimit", test_sortLimit),
            ("test_sortMultiModifiers", test_sortMultiModifiers),
            ("test_sortBy", test_sortBy),
            ("test_sortByNoSort", test_sortByNoSort),
            ("test_sortGet", test_sortGet),
            ("test_sortGetMulti", test_sortGetMulti),
            ("test_sortStore", test_sortStore),
            ("test_sortByGetHashes", test_sortByGetHashes),
        ]
    }
    
    var exp: XCTestExpectation?
    
    var key1 = "1"
    var key2 = "2"
    var key3 = "3"
    
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
    
    func test_sort() {
        setup(major: 1, minor: 0, micro: 0) {
            exp = expectation(description: "Return sorted list at `key`.")
            
            let val1 = "20"
            let val2 = "5"
            let val3 = "90"
            redis.lpush(key1, values: val1, val2, val3) { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 3)
                
                redis.sort(key: key1, callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?[0]?.asString, val2)
                    XCTAssertEqual(res?[1]?.asString, val1)
                    XCTAssertEqual(res?[2]?.asString, val3)
                    exp?.fulfill()
                })
            }
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_sortDesc() {
        setup(major: 1, minor: 0, micro: 0) {
            exp = expectation(description: "Return list at `key` sorted in descending order.")
            
            let val1 = "20"
            let val2 = "5"
            let val3 = "90"
            redis.lpush(key1, values: val1, val2, val3) { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 3)
                
                redis.sort(key: key1, desc: true, callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?[0]?.asString, val3)
                    XCTAssertEqual(res?[1]?.asString, val1)
                    XCTAssertEqual(res?[2]?.asString, val2)
                    exp?.fulfill()
                })
            }
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_sortAlpha() {
        setup(major: 1, minor: 0, micro: 0) {
            exp = expectation(description: "Return lexicograpically sorted list at `key`.")
            
            let val1 = "red"
            let val2 = "blue"
            let val3 = "green"
            redis.lpush(key1, values: val1, val2, val3) { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 3)
                
                redis.sort(key: key1, alpha: true, callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?[0]?.asString, val2)
                    XCTAssertEqual(res?[1]?.asString, val3)
                    XCTAssertEqual(res?[2]?.asString, val1)
                    exp?.fulfill()
                })
            }
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_sortLimit() {
        setup(major: 1, minor: 0, micro: 0) {
            exp = expectation(description: "Return sorted list with `offset` and `count`.")
            
            let val1 = "20"
            let val2 = "5"
            let val3 = "90"
            let val4 = "35"
            let val5 = "600"
            redis.lpush(key1, values: val1, val2, val3, val4, val5) { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 5)
                
                redis.sort(key: key1, limit: (1, 3), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?[0]?.asString, val1)
                    XCTAssertEqual(res?[1]?.asString, val4)
                    XCTAssertEqual(res?[2]?.asString, val3)
                    exp?.fulfill()
                })
            }
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_sortMultiModifiers() {
        setup(major: 1, minor: 0, micro: 0) {
            exp = expectation(description: "SORT with many modifiers.")
            
            let val1 = "red"
            let val2 = "blue"
            let val3 = "green"
            redis.lpush(key1, values: val1, val2, val3) { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 3)
                
                redis.sort(key: key1, limit: (0, 10), desc: true, alpha: true, callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?[0]?.asString, val1)
                    XCTAssertEqual(res?[1]?.asString, val3)
                    XCTAssertEqual(res?[2]?.asString, val2)
                    exp?.fulfill()
                })
            }
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_sortBy() {
        setup(major: 1, minor: 0, micro: 0) {
            exp = expectation(description: "Sort by external keys.")
            
            let val1 = "1"
            let val2 = "2"
            let val3 = "3"
            redis.lpush(key1, values: val1, val2, val3) { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 3)
                
                redis.mset(("weight_1", "40"), ("weight_2", "5"), ("weight_3", "210"), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssert(res)
                    
                    redis.sort(key: key1, by: "weight_*", callback: { (res, err) in
                        XCTAssertNil(err)
                        XCTAssertEqual(res?[0]?.asString, val2)
                        XCTAssertEqual(res?[1]?.asString, val1)
                        XCTAssertEqual(res?[2]?.asString, val3)
                        exp?.fulfill()
                    })
                })
            }
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_sortByNoSort() {
        setup(major: 1, minor: 0, micro: 0) {
            exp = expectation(description: "Give bad key to return unsorted list.")
            
            let val1 = "345"
            let val2 = "8"
            let val3 = "90"
            redis.lpush(key1, values: val1, val2, val3) { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 3)
                
                redis.sort(key: key1, by: "nosort", callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?[0]?.asString, val3)
                    XCTAssertEqual(res?[1]?.asString, val2)
                    XCTAssertEqual(res?[2]?.asString, val1)
                    exp?.fulfill()
                })
            }
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_sortGet() {
        setup(major: 1, minor: 0, micro: 0) {
            exp = expectation(description: "Sort by external keys and retrieve external keys.")
            
            let val1 = "1"
            let val2 = "2"
            let val3 = "3"
            redis.lpush(key1, values: val1, val2, val3) { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 3)
                
                let obj1 = "baby"
                let obj2 = "watermelon"
                let obj3 = "panda"
                redis.mset(("weight_1", "40"), ("weight_2", "5"), ("weight_3", "210"), ("object_1", obj1), ("object_2", obj2), ("object_3", obj3), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssert(res)
                    
                    redis.sort(key: key1, by: "weight_*", get: "object_*", callback: { (res, err) in
                        XCTAssertNil(err)
                        XCTAssertEqual(res?[0]?.asString, obj2)
                        XCTAssertEqual(res?[1]?.asString, obj1)
                        XCTAssertEqual(res?[2]?.asString, obj3)
                        exp?.fulfill()
                    })
                })
            }
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_sortGetMulti() {
        setup(major: 1, minor: 0, micro: 0) {
            exp = expectation(description: "Sort by external keys and retrieve multiple external keys.")
            
            let val1 = "1"
            let val2 = "2"
            let val3 = "3"
            redis.lpush(key1, values: val1, val2, val3) { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 3)
                
                let obj1 = "baby"
                let obj2 = "watermelon"
                let obj3 = "panda"
                redis.mset(("weight_1", "40"), ("weight_2", "5"), ("weight_3", "210"), ("object_1", obj1), ("object_2", obj2), ("object_3", obj3), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssert(res)
                    
                    redis.sort(key: key1, by: "weight_*", get: "object_*", "#", callback: { (res, err) in
                        XCTAssertNil(err)
                        XCTAssertEqual(res?[0]?.asString, obj2)
                        XCTAssertEqual(res?[1]?.asString, val2)
                        XCTAssertEqual(res?[2]?.asString, obj1)
                        XCTAssertEqual(res?[3]?.asString, val1)
                        XCTAssertEqual(res?[4]?.asString, obj3)
                        XCTAssertEqual(res?[5]?.asString, val3)
                        exp?.fulfill()
                    })
                })
            }
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_sortStore() {
        setup(major: 1, minor: 0, micro: 0) {
            exp = expectation(description: "Sort list and store at `store key`.")
            
            let val1 = "20"
            let val2 = "5"
            let val3 = "90"
            redis.lpush(key1, values: val1, val2, val3) { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 3)
                
                let store = "store"
                redis.sort(key: key1, store: store, callback: { (res, err) in
                    XCTAssertNil(err)
                    let res0 = res?[0]?.asInteger
                    XCTAssertEqual(res0, 3)
                    
                    redis.sort(key: store, by: "nosort", callback: { (res, err) in
                        XCTAssertNil(err)
                        let res0 = res?[0]?.asString
                        let res1 = res?[1]?.asString
                        let res2 = res?[2]?.asString
                        XCTAssertEqual(res0, val2)
                        XCTAssertEqual(res1, val1)
                        XCTAssertEqual(res2, val3)
                        exp?.fulfill()
                    })
                })
            }
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_sortByGetHashes() {
        setup(major: 1, minor: 0, micro: 0) {
            exp = expectation(description: "Sort list and use BY and GET options against hash fields.")
            
            let val1 = "1"
            let val2 = "2"
            let val3 = "3"
            redis.lpush(key1, values: val1, val2, val3) { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 3)
                
                let obj1 = "baby"
                let obj2 = "watermelon"
                let obj3 = "panda"
                let dispatchGroup = DispatchGroup()
                for _ in 0...5 {
                    dispatchGroup.enter()
                }
                redis.hmset("weight_1", fieldValuePairs: ("kg", "20"), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssert(res)
                    dispatchGroup.leave()
                })
                redis.hmset("weight_2", fieldValuePairs: ("kg", "5"), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssert(res)
                    dispatchGroup.leave()
                })
                redis.hmset("weight_3", fieldValuePairs: ("kg", "250"), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssert(res)
                    dispatchGroup.leave()
                })
                redis.hmset("object_1", fieldValuePairs: ("name", obj1), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssert(res)
                    dispatchGroup.leave()
                })
                redis.hmset("object_2", fieldValuePairs: ("name", obj2), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssert(res)
                    dispatchGroup.leave()
                })
                redis.hmset("object_3", fieldValuePairs: ("name", obj3), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssert(res)
                    dispatchGroup.leave()
                })
                dispatchGroup.wait()
                
                redis.sort(key: key1, by: "weight_*->kg", get: "object_*->name", callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?[0]?.asString, obj2)
                    XCTAssertEqual(res?[1]?.asString, obj1)
                    XCTAssertEqual(res?[2]?.asString, obj3)
                    exp?.fulfill()
                })
            }
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
}
