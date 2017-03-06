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

public class TestSORTSync: XCTestCase {
    
    static var allTests: [(String, (TestSORTSync) -> () throws -> Void)] {
        return [
            ("test_sort", test_sort),
            ("test_sort_desc", test_sort_desc),
            ("test_sort_alpha", test_sort_alpha),
            ("test_sort_limit", test_sort_limit),
            ("test_sort_by", test_sort_by),
            ("test_sort_by_bad_key", test_sort_by_bad_key),
            ("test_sort_get", test_sort_get),
            ("test_sort_store", test_sort_store),
            ("test_sort_by_get_hashes", test_sort_by_get_hashes)
        ]
    }
    
    let key1 = "key1"
    let key2 = "key2"
    let key3 = "key3"
    
    let val1 = "1"
    let val2 = "2"
    let val3 = "3"
    
    let weight1 = "weight1"
    let weight2 = "weight2"
    let weight3 = "weight3"
    
    let obj1 = "obj1"
    let obj2 = "obj2"
    let obj3 = "obj3"
    
    private func setup(major: Int, minor: Int, micro: Int) throws -> Bool {
        try connectRedis()
        guard try redis.info().server.checkVersionCompatible(major: major, minor: minor, micro: micro) else { return false }
        return try redis.flushdb()
    }
    
    func test_sort() throws {
        guard try setup(major: 1, minor: 0, micro: 0) else { return }
        
        XCTAssertEqual(try redis.lpush(key: key1, value: val1, values: val2, val3), 3)
        
        let res = try redis.sort(key: key1)
        XCTAssertEqual(res[0]?.asString, val1)
        XCTAssertEqual(res[1]?.asString, val2)
        XCTAssertEqual(res[2]?.asString, val3)
    }
    
    func test_sort_desc() throws {
        guard try setup(major: 1, minor: 0, micro: 0) else { return }
        
        XCTAssertEqual(try redis.lpush(key: key1, value: val1, values: val2, val3), 3)
        
        let res = try redis.sort(key: key1, desc: true)
        XCTAssertEqual(res[0]?.asString, val3)
        XCTAssertEqual(res[1]?.asString, val2)
        XCTAssertEqual(res[2]?.asString, val1)
    }
    
    func test_sort_alpha() throws {
        guard try setup(major: 1, minor: 0, micro: 0) else { return }
        
        XCTAssertEqual(try redis.lpush(key: key1, value: val1, values: val2, val3), 3)
        
        let res = try redis.sort(key: key1, alpha: true)
        XCTAssertEqual(res[0]?.asString, val1)
        XCTAssertEqual(res[1]?.asString, val2)
        XCTAssertEqual(res[2]?.asString, val3)
    }
    
    func test_sort_limit() throws {
        guard try setup(major: 1, minor: 0, micro: 0) else { return }
        
        XCTAssertEqual(try redis.lpush(key: key1, value: val1, values: val2, val3), 3)
        
        let res = try redis.sort(key: key1, limit: (1, 2))
        XCTAssertEqual(res[0]?.asString, val2)
        XCTAssertEqual(res[1]?.asString, val3)
    }
    
    func test_sort_by() throws {
        guard try setup(major: 1, minor: 0, micro: 0) else { return }
        
        XCTAssertEqual(try redis.lpush(key: key1, value: val1, values: val2, val3), 3)
        XCTAssert(try redis.mset(keyValuePair: (weight1, val1), keyValuePairs: (weight2, val2), (weight3, val3)))
        
        let res = try redis.sort(key: key1, by: "weight*")
        XCTAssertEqual(res[0]?.asString, val1)
        XCTAssertEqual(res[1]?.asString, val2)
        XCTAssertEqual(res[2]?.asString, val3)
    }
    
    func test_sort_by_bad_key() throws {
        guard try setup(major: 1, minor: 0, micro: 0) else { return }
        
        XCTAssertEqual(try redis.lpush(key: key1, value: val1, values: val2, val3), 3)
        
        let res = try redis.sort(key: key1, by: "bad key")
        XCTAssertEqual(res[0]?.asString, val3)
        XCTAssertEqual(res[1]?.asString, val2)
        XCTAssertEqual(res[2]?.asString, val1)
    }
    
    func test_sort_get() throws {
        guard try setup(major: 1, minor: 0, micro: 0) else { return }

        XCTAssertEqual(try redis.lpush(key: key1, value: val1, values: val2, val3), 3)
        XCTAssert(try redis.mset(keyValuePair: (weight1, val1), keyValuePairs: (weight2, val2), (weight3, val3), (obj1, obj1), (obj2, obj2), (obj3, obj3)))
        
        let res = try redis.sort(key: key1, by: "weight*", get: "obj*")
        XCTAssertEqual(res[0]?.asString, obj1)
        XCTAssertEqual(res[1]?.asString, obj2)
        XCTAssertEqual(res[2]?.asString, obj3)
    }
    
    func test_sort_store() throws {
        guard try setup(major: 1, minor: 0, micro: 0) else { return }
        
        XCTAssertEqual(try redis.lpush(key: key1, value: val1, values: val2, val3), 3)
        XCTAssertEqual(try redis.sort(key: key1, store: key2)[0]?.asInteger, 3)
    }
    
    func test_sort_by_get_hashes() throws {
        guard try setup(major: 1, minor: 0, micro: 0) else { return }
        
        XCTAssertEqual(try redis.lpush(key: key1, value: val1, values: val2, val3), 3)
        XCTAssert(try redis.hmset(key: weight1, fieldValuePair: ("kg", val1)))
        XCTAssert(try redis.hmset(key: weight2, fieldValuePair: ("kg", val2)))
        XCTAssert(try redis.hmset(key: weight3, fieldValuePair: ("kg", val3)))
        XCTAssert(try redis.hmset(key: obj1, fieldValuePair: ("name", obj1)))
        XCTAssert(try redis.hmset(key: obj2, fieldValuePair: ("name", obj2)))
        XCTAssert(try redis.hmset(key: obj3, fieldValuePair: ("name", obj3)))
    
        let res = try redis.sort(key: key1, by: "weight*->kg", get: "obj*->name")
        XCTAssertEqual(res[0]?.asString, obj1)
        XCTAssertEqual(res[1]?.asString, obj2)
        XCTAssertEqual(res[2]?.asString, obj3)
    }
}
