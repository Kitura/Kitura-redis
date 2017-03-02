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
            ("test_empty", test_empty),
            ("test_incr_decr", test_incr_decr),
            ("test_incr_floats", test_incr_floats),
            ("test_keys", test_keys),
            ("test_randomkey", test_randomkey),
            ("test_scan", test_scan),
            ("test_set_and_get", test_set_and_get),
            ("test_set_exist_options", test_set_exist_options),
            ("test_set_expire_options", test_set_expire_options),
            ("test_touch", test_touch),
            ("test_type", test_type)
        ]
    }
    
    var key1 = "test1"
    var key2 = "test2"
    var key3 = "test3"
    var key4 = "test4"
    
    private func setup(major: Int, minor: Int, micro: Int) throws -> Bool {
        try connectRedis()
        guard try redis.info().server.checkVersionCompatible(major: major, minor: minor, micro: micro) else { return false }
        return try redis.flushdb()
    }
    
    func test_empty() throws {
        guard try setup(major: 1, minor: 0, micro: 0) else { return }
        
        let emptyValue = ""
        
        XCTAssert(try redis.set(key: key1, value: emptyValue))
        XCTAssertEqual(try redis.get(key: key1)?.asString, emptyValue)
    }
    
    func test_incr_decr() throws {
        guard try setup(major: 1, minor: 0, micro: 0) else { return }
        
        var theValue = 101
        
        XCTAssert(try redis.set(key: key1, value: String(theValue)))
        
        var newValue = try redis.incr(key: key1)
        XCTAssertEqual(newValue, theValue + 1)
        theValue = newValue
        
        newValue = try redis.decr(key: key1)
        XCTAssertEqual(newValue, theValue - 1)
        theValue = newValue
        
        XCTAssertEqual(try redis.decr(key: key2), -1)
        
        newValue = try redis.incr(key: key1, by: 10)
        XCTAssertEqual(newValue, theValue + 10)
        theValue = newValue
        
        newValue = try redis.decr(key: key1, by: 5)
        XCTAssertEqual(newValue, theValue - 5)
    }
    
    func test_incr_floats() throws {
        guard try setup(major: 2, minor: 6, micro: 0) else { return }
        
        let theValue: Double = 84.75
        
        XCTAssert(try redis.set(key: key3, value: String(theValue)))
        
        let incValue: Float = 12.5
        XCTAssertEqual(try redis.incr(key: key3, byFloat: incValue).asDouble, theValue + Double(incValue))
    }
    
    func test_keys() throws {
        guard try setup(major: 1, minor: 0, micro: 0) else { return }
        
        XCTAssert(try redis.mset(pair: (key1, "1"), pairs: (key2, "2"), (key3, "3")))
        XCTAssertEqual(try redis.keys(pattern: "*1").count, 1)
    }
    
    func test_randomkey() throws {
        guard try setup(major: 1, minor: 0, micro: 0) else { return }
        
        XCTAssert(try redis.mset(pair: (key1, "1"), pairs: (key2, "2"), (key3, "3")))
        XCTAssertNotNil(try redis.randomkey())
    }
    
    func test_scan() throws {
        guard try setup(major: 2, minor: 8, micro: 0) else { return }
        
        XCTAssert(try redis.mset(pair: (key1, "val1"), pairs: (key2, "val2")))
        XCTAssertEqual(try redis.scan(cursor: 0).1.count, 2)
        XCTAssertGreaterThan(try redis.scan(cursor: 0, match: "*", count: 1).1.count, 0)
        XCTAssertGreaterThan(try redis.scan(cursor: 0, match: "*").1.count, 0)
        XCTAssertGreaterThan(try redis.scan(cursor: 0, count: 1).1.count, 0)
    }
    
    func test_set_and_get() throws {
        guard try setup(major: 1, minor: 0, micro: 0) else { return }
        
        let expectedValue = "testing 1 2 3"
        let newValue = "xyzzy-plover"
        
        XCTAssert(try redis.set(key: key1, value: expectedValue))
        XCTAssertEqual(try redis.get(key: key1)?.asString, expectedValue)
        XCTAssertEqual(try redis.getset(key: key1, value: newValue)?.asString, expectedValue)
        XCTAssertEqual(try redis.get(key: key1)?.asString, newValue)
    }
    
    func test_set_exist_options() throws {
        guard try setup(major: 1, minor: 0, micro: 0) else { return }
        
        let expectedValue = "hi ho, hi ho, it's off to test we go"
        let newValue = "A testing we go, a testing we go"
    
        XCTAssertFalse(try redis.set(key: key2, value: expectedValue, exists: true))
        XCTAssertNil(try redis.get(key: key2))
        XCTAssert(try redis.set(key: key2, value: expectedValue, exists: false))
        XCTAssertEqual(try redis.get(key: key2)?.asString, expectedValue)
        XCTAssertFalse(try redis.set(key: key2, value: newValue, exists: false))
        XCTAssertEqual(try redis.del(key: key2), 1)
        XCTAssert(try redis.set(key: key2, value: newValue, exists: false))
        XCTAssertEqual(try redis.get(key: key2)?.asString, newValue)
    }
    
    func test_set_expire_options() throws {
        guard try setup(major: 1, minor: 0, micro: 0) else { return }

        let expectedValue = "hi ho, hi ho, it's off to test we go"
        
        XCTAssert(try redis.set(key: key3, value: expectedValue, expiresIn: 2.75))
        XCTAssertEqual(try redis.get(key: key3)?.asString, expectedValue)
        usleep(3000000)
        XCTAssertNil(try redis.get(key: key3))
    }

    
    func test_touch() throws {
        guard try setup(major: 3, minor: 2, micro: 1) else { return }
        
        XCTAssert(try redis.mset(pair: (key1, "val1"), pairs: (key2, "val2")))
        XCTAssertEqual(try redis.touch(key: "bad key"), 0)
        XCTAssertEqual(try redis.touch(key: key1), 1)
        XCTAssertEqual(try redis.touch(key: key1, keys: key2), 2)
    }
    
    func test_type() throws {
        guard try setup(major: 1, minor: 0, micro: 0) else { return }
        
        XCTAssert(try redis.set(key: key1, value: "val1"))
        XCTAssertEqual(try redis.type(key: key1), "string")
        XCTAssertEqual(try redis.type(key: "bad key"), "none")
    }
}
