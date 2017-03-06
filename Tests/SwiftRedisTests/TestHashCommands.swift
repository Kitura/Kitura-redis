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

public class TestHashCommands: XCTestCase {
    static var allTests: [(String, (TestHashCommands) -> () throws -> Void)] {
        return [
            ("test_hash_set_and_get", test_hash_set_and_get),
            ("test_incr", test_incr),
            ("test_bulk_commands", test_bulk_commands),
            ("test_binary_safe_hset_and_hmset", test_binary_safe_hset_and_hmset),
            ("test_hscan", test_hscan),
            ("test_hscan_match", test_hscan_match),
            ("test_hscan_count", test_hscan_count),
            ("test_hscan_match_count", test_hscan_match_count)
        ]
    }
    
    let key = "key"
    let field1 = "f1"
    let field2 = "f2"
    let field3 = "f3"
    let field4 = "f4"
    let val1 = "val1"
    let val2 = "val2"
    
    private func setup(major: Int, minor: Int, micro: Int) throws -> Bool {
        try connectRedis()
        guard try redis.info().server.checkVersionCompatible(major: major, minor: minor, micro: micro) else { return false }
        return try redis.flushdb()
    }
    
    func test_hash_set_and_get() throws {
        guard try setup(major: 2, minor: 0, micro: 0) else { return }
        
        let expVal1 = "testing, testing, 1 2 3"
        let expVal2 = "hi hi, hi ho, its off to test we go"
        
        XCTAssert(try redis.hset(key: key, field: field1, value: expVal1))
        XCTAssertFalse(try redis.hset(key: key, field: field1, value: expVal2))
        XCTAssertEqual(try redis.hget(key: key, field: field1)?.asString, expVal2)
        XCTAssertFalse(try redis.hexists(key: key, field: field2))
        XCTAssert(try redis.hset(key: key, field: field2, value: expVal1))
        XCTAssertEqual(try redis.hlen(key: key), 2)
        XCTAssertFalse(try redis.hset(key: key, field: field1, value: expVal2, exists: false))
        XCTAssertEqual(try redis.hdel(key: key, field: field1, fields: field2), 2)
        XCTAssertNil(try redis.hget(key: key, field: field1))
        XCTAssert(try redis.hset(key: key, field: field1, value: expVal1, exists: false))
    }
    
    func test_incr() throws {
        guard try setup(major: 3, minor: 2, micro: 0) else { return }
        
        let incInt = 10
        let incFloat: Float = 8.5
        let expVal1 = "testing, testing, 1 2 3"
        
        XCTAssertEqual(try redis.hincrby(key: key, field: field3, increment: incInt), incInt)
        XCTAssertEqual(try redis.hincrbyfloat(key: key, field: field2, increment: incFloat).asDouble, Double(incFloat))
        XCTAssert(try redis.hset(key: key, field: field1, value: expVal1))
        XCTAssertEqual(try redis.hstrlen(key: key, field: field1), expVal1.characters.count)
    }
    
    func test_bulk_commands() throws {
        guard try setup(major: 2, minor: 0, micro: 0) else { return }
        
        let expVal1 = "Hi ho, hi ho"
        let expVal2 = "it's off to test"
        let expVal3 = "we go"
        
        XCTAssert(try redis.hmset(key: key, fieldValuePair: (field1, expVal1), fieldValuePairs: (field2, expVal2), (field3, expVal3)))
        XCTAssertEqual(try redis.hget(key: key, field: field1)?.asString, expVal1)
        
        let hmget = try redis.hmget(key: key, field: field1, fields: field2, field4, field3)
        XCTAssertEqual(hmget.count, 4)
        XCTAssertEqual(hmget[0]?.asString, expVal1)
        XCTAssertEqual(hmget[1]?.asString, expVal2)
        XCTAssertNil(hmget[2])
        XCTAssertEqual(hmget[3]?.asString, expVal3)
        
        XCTAssertEqual(try redis.hkeys(key: key).count, 3)
        XCTAssertEqual(try redis.hvals(key: key).count, 3)
        
        let hmgetall = try redis.hgetall(key: key)
        XCTAssertEqual(hmgetall.count, 3)
        
        let fieldNames = [self.field1, self.field2, self.field3]
        let fieldValues = [expVal1, expVal2, expVal3]
        for i in 0..<fieldNames.count {
            let field = hmgetall[fieldNames[i]]
            XCTAssertEqual(field?.asString, fieldValues[i])
        }
    }

    func test_binary_safe_hset_and_hmset() throws {
        guard try setup(major: 2, minor: 0, micro: 0) else { return }
        
        var bytes: [UInt8] = [0xff, 0x00, 0xfe, 0x02]
        let expData1 = Data(bytes: bytes, count: bytes.count)

        XCTAssert(try redis.hset(key: key, field: field1, value: RedisString(expData1)))
    
        bytes = [0x00, 0x01, 0x02, 0x03, 0x04]
        let expData2 = Data(bytes: bytes, count: bytes.count)
        bytes = [0xf0, 0xf1, 0xf2, 0xf3, 0xf4]
        let expData3 = Data(bytes: bytes, count: bytes.count)
        XCTAssert(try redis.hmset(key: key, fieldValuePair: (field2, RedisString(expData2)), fieldValuePairs: (field3, RedisString(expData3))))
        
        let res = try redis.hgetall(key: key)
        XCTAssertEqual(res.count, 3)
        
        let fieldNames = [self.field1, self.field2, self.field3]
        let fieldValues = [expData1, expData2, expData3]
        for i in 0..<fieldNames.count {
            let field = res[fieldNames[i]]
            XCTAssertEqual(field!.asData, fieldValues[i])
        }
    }

    func test_hscan() throws {
        guard try setup(major: 2, minor: 8, micro: 0) else { return }
        
        XCTAssert(try redis.hmset(key: key, fieldValuePair: (field1, val1), fieldValuePairs: (field2, val2)))
        XCTAssertEqual(try redis.hscan(key: key, cursor: 0).1.count, 4)
    }
    
    func test_hscan_match() throws {
        guard try setup(major: 2, minor: 8, micro: 0) else { return }

        XCTAssert(try redis.hmset(key: key, fieldValuePair: (field1, val1), fieldValuePairs: (field2, val2)))
        XCTAssertNotNil(try redis.hscan(key: key, cursor: 0, match: "link*"))
    }
    
    func test_hscan_count() throws {
        guard try setup(major: 2, minor: 8, micro: 0) else { return }
        
        XCTAssert(try redis.hmset(key: key, fieldValuePair: (field1, val1), fieldValuePairs: (field2, val2)))
        XCTAssertNotNil(try redis.hscan(key: key, cursor: 0, count: 1))
    }

    func test_hscan_match_count() throws {
        guard try setup(major: 2, minor: 8, micro: 0) else { return }
        
        XCTAssert(try redis.hmset(key: key, fieldValuePair: (field1, val1), fieldValuePairs: (field2, val2)))
        XCTAssertNotNil(try redis.hscan(key: key, cursor: 0, match: "link*", count: 1))
    }
}
