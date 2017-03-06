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

public class TestBITFIELDSync: XCTestCase {
    
    static var allTests: [(String, (TestBITFIELDSync) -> () throws -> Void)] {
        return [
            ("test_bitfield_get", test_bitfield_get),
            ("test_bitfield_set", test_bitfield_set),
            ("test_bitfield_incrby", test_bitfield_incrby),
            ("test_bitfield_offset_multiplier", test_bitfield_offset_multiplier),
            ("test_bitfield_wrap", test_bitfield_wrap),
            ("test_bitfield_sat", test_bitfield_sat),
            ("test_bitfield_fail", test_bitfield_fail),
            ("test_bitfield_multi_subcommands", test_bitfield_multi_subcommands),
        ]
    }
    
    var key = "key"
    
    private func setup(major: Int, minor: Int, micro: Int) throws -> Bool {
        try connectRedis()
        guard try redis.info().server.checkVersionCompatible(major: major, minor: minor, micro: micro) else { return false }
        return try redis.flushdb()
    }
    
    func test_bitfield_get() throws {
        guard try setup(major: 3, minor: 2, micro: 0) else { return }
        
        let res = try redis.bitfield(key: key, subcommands: .get("u2", 0))[0]
        XCTAssertNotNil(res)
        XCTAssertEqual(res?.asInteger, 0)
    }
    
    func test_bitfield_set() throws {
        guard try setup(major: 3, minor: 2, micro: 0) else { return }
        
        let res = try redis.bitfield(key: key, subcommands: .set("u2", "0", 1))[0]
        XCTAssertNotNil(res)
        XCTAssertEqual(res?.asInteger, 0)
    }
    
    func test_bitfield_incrby() throws {
        guard try setup(major: 3, minor: 2, micro: 0) else { return }
        
        let res = try redis.bitfield(key: key, subcommands: .incrby("u2", "0", 1))[0]
        XCTAssertNotNil(res)
        XCTAssertEqual(res?.asInteger, 1)
    }
    
    func test_bitfield_offset_multiplier() throws {
        guard try setup(major: 3, minor: 2, micro: 0) else { return }
        
        let res = try redis.bitfield(key: key, subcommands: .incrby("u2", "#0", 1))[0]
        XCTAssertNotNil(res)
        XCTAssertEqual(res?.asInteger, 1)
    }
    
    func test_bitfield_wrap() throws {
        guard try setup(major: 3, minor: 2, micro: 0) else { return }
        
        XCTAssertEqual(try redis.bitfield(key: key, subcommands: .incrby("u1", "0", 1))[0]?.asInteger, 1)
        XCTAssertEqual(try redis.bitfield(key: key, subcommands: .overflow(.WRAP), .incrby("u1", "0", 1))[0]?.asInteger, 0)
    }
    
    func test_bitfield_sat() throws {
        guard try setup(major: 3, minor: 2, micro: 0) else { return }
        
        XCTAssertEqual(try redis.bitfield(key: key, subcommands: .overflow(.SAT), .incrby("u1", "0", 2))[0]?.asInteger, 1)
    }
    
    func test_bitfield_fail() throws {
        guard try setup(major: 3, minor: 2, micro: 0) else { return }
        
        XCTAssertEqual(try redis.bitfield(key: key, subcommands: .overflow(.FAIL), .incrby("u1", "0", 2))[0], RedisResponse.Nil)
    }
    
    func test_bitfield_multi_subcommands() throws {
        guard try setup(major: 3, minor: 2, micro: 0) else { return }
        
        let res = try redis.bitfield(key: key, subcommands: .overflow(.SAT), .set("u2", "0", 1), .get("u2", 0), .incrby("u2", "0", 1))
        XCTAssertEqual(res[0]?.asInteger, 0)
        XCTAssertEqual(res[1]?.asInteger, 1)
        XCTAssertEqual(res[2]?.asInteger, 2)
    }
}
