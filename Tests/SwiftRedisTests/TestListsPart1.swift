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


public class TestListsPart1: XCTestCase {
    static var allTests: [(String, (TestListsPart1) -> () throws -> Void)] {
        return [
            ("test_lpush_lpop", test_lpush_lpop),
            ("test_binary_lpush_lpop", test_binary_lpush_lpop),
            ("test_rpush_rpop", test_rpush_rpop),
            ("test_binary_rpush_rpop", test_binary_rpush_rpop),
            ("test_lrange_lrem", test_lrange_lrem)
        ]
    }

    let key1 = "key1"
    let key2 = "key2"
    let key3 = "key3"
    let val1 = "val1"
    let val2 = "val2"
    let val3 = "val3"
    let bval1 = RedisString("bval1")
    let bval2 = RedisString("bval2")
    let bval3 = RedisString("bval3")

    private func setup(major: Int, minor: Int, micro: Int) throws -> Bool {
        try connectRedis()
        guard try redis.info().server.checkVersionCompatible(major: major, minor: minor, micro: micro) else { return false }
        return try redis.flushdb()
    }
    
    func test_lpush_lpop() throws {
        guard try setup(major: 2, minor: 2, micro: 0) else { return }
        
        XCTAssertEqual(try redis.lpush(key: key1, value: val1, values: val2), 2)
        
        let res = try redis.lpop(key: key1)
        XCTAssertNotNil(res)
        XCTAssertEqual(res?.asString, val2)
        
        XCTAssertEqual(try redis.lpushx(key: key1, value: val3), 2)
        
        XCTAssertNil(try redis.lpop(key: key3))
        
        XCTAssertEqual(try redis.lpushx(key: key3, value: val3), 0)
    }
    
    func test_binary_lpush_lpop() throws {
        guard try setup(major: 2, minor: 2, micro: 0) else { return }
        
        XCTAssertEqual(try redis.lpush(key: key2, value: bval2, values: bval1), 2)
        
        let res = try redis.lpop(key: key2)
        XCTAssertNotNil(res)
        XCTAssertEqual(res, bval1)
        
        XCTAssertEqual(try redis.lpushx(key: key2, value: bval3), 2)
        
        XCTAssertNil(try redis.lpop(key: key3))
        
        XCTAssertEqual(try redis.lpushx(key: key3, value: bval3), 0)
    }
    
    func test_rpush_rpop() throws {
        guard try setup(major: 2, minor: 2, micro: 0) else { return }
        
        XCTAssertEqual(try redis.rpush(key: key1, value: val1, values: val2), 2)
        
        let res = try redis.rpop(key: key1)
        XCTAssertNotNil(res)
        XCTAssertEqual(res?.asString, val2)
        
        XCTAssertEqual(try redis.rpushx(key: key1, value: val3), 2)
        
        XCTAssertNil(try redis.rpop(key: key3))

        XCTAssertEqual(try redis.rpushx(key: key3, value: val3), 0)
    }
    
    func test_binary_rpush_rpop() throws {
        guard try setup(major: 2, minor: 2, micro: 0) else { return }
        
        XCTAssertEqual(try redis.rpush(key: key2, value: bval2, values: bval1), 2)
        
        let res = try redis.rpop(key: key2)
        XCTAssertNotNil(res)
        XCTAssertEqual(res, bval1)
        
        XCTAssertEqual(try redis.rpushx(key: key2, value: bval3), 2)
        
        XCTAssertNil(try redis.rpop(key: key3))
        
        XCTAssertEqual(try redis.rpushx(key: key3, value: bval3), 0)
    }
    
    func test_lrange_lrem() throws {
        guard try setup(major: 1, minor: 0, micro: 0) else { return }
        
        let val1 = "testing 1 2 3"
        let val2 = "over the hill and through the woods"
        let val3 = "to grandmothers house we go"
        let val4 = "singing away we go"
        let bval1 = RedisString("testing 1 2 3")
        let bval2 = RedisString("over the hill and through the woods")
        let bval3 = RedisString("to grandmothers house we go")
        let bval4 = RedisString("singing away we go")
        
        XCTAssertEqual(try redis.lpush(key: key1, value: val1, values: val2, val3, val4), 4)
        
        var res = try redis.lrange(key: key1, start: 1, stop: 2)
        XCTAssertEqual(res.count, 2)
        XCTAssertEqual(res[0].asString, val3)
        XCTAssertEqual(res[1].asString, val2)
        
        XCTAssertEqual(try redis.lrem(key: key1, count: 3, value: val3), 1)
        
        XCTAssertEqual(try redis.lpush(key: key2, value: bval4, values: bval3, bval2, bval1), 4)
        
        res = try redis.lrange(key: key2, start: 1, stop: 2)
        XCTAssertEqual(res.count, 2)
        XCTAssertEqual(res[0], bval2)
        XCTAssertEqual(res[1], bval3)
        
        XCTAssertEqual(try redis.lrem(key: key1, count: 3, value: bval2), 1)
    }
}
