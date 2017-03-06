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

public class TestBinarySafeCommandsSync: XCTestCase {
    static var allTests: [(String, (TestBinarySafeCommandsSync) -> () throws -> Void)] {
        return [
            ("test_set_with_binary", test_set_with_binary),
            ("test_set_exist_options_with_binary", test_set_exist_options_with_binary)
        ]
    }

    let key1 = "key1"
    let key2 = "key2"
    let key3 = "key3"
    let key4 = "key4"
    let key5 = "key5"

    private func setup(major: Int, minor: Int, micro: Int) throws -> Bool {
        try connectRedis()
        guard try redis.info().server.checkVersionCompatible(major: major, minor: minor, micro: micro) else { return false }
        return try redis.flushdb()
    }
    
    func test_set_with_binary() throws {
        guard try setup(major: 1, minor: 0, micro: 0) else { return }
        
        var bytes: [UInt8] = [0xff, 0x00, 0xfe, 0x02]
        let expData = Data(bytes: bytes, count: bytes.count)
        XCTAssert(try redis.set(key: key1, value: RedisString(expData)))
        
        bytes = [0x00, 0x01, 0x02, 0x03, 0x04]
        let newData = Data(bytes: bytes, count: bytes.count)
        XCTAssertEqual(try redis.getset(key: key1, value: RedisString(newData))?.asData, expData)
        
        XCTAssertEqual(try redis.get(key: key1)?.asData, newData)
    }
    
    func test_set_exist_options_with_binary() throws {
        guard try setup(major: 2, minor: 6, micro: 12) else { return }
        
        var bytes: [UInt8] = [0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77]
        let expectedValue = Data(bytes: bytes, count: bytes.count)
        bytes = [0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa]
        let newValue = Data(bytes: bytes, count: bytes.count)

        XCTAssertFalse(try redis.set(key: key2, value: RedisString(expectedValue), exists: true))
        XCTAssertNil(try redis.get(key: key2))
        XCTAssert(try redis.set(key: key2, value: RedisString(expectedValue)))
        XCTAssertEqual(try redis.get(key: key2)?.asData, expectedValue)
        XCTAssertFalse(try redis.set(key: key2, value: RedisString(newValue), exists: false))
        XCTAssertEqual(try redis.del(key: key2), 1)
        XCTAssert(try redis.set(key: key2, value: RedisString(newValue)))
        XCTAssertEqual(try redis.get(key: key2)?.asData, newValue)
    }
}
