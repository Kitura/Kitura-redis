/**
 * Copyright IBM Corporation 2016, 2017
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

import XCTest
import SwiftRedis

public class TestBitfield: XCTestCase {
    
    static var allTests: [(String, (TestBitfield) -> () throws -> Void)] {
        return [
            ("test_bitfieldGet", test_bitfieldGet),
            ("test_bitfieldSet", test_bitfieldSet),
            ("test_bitfieldIncrby", test_bitfieldIncrby),
            ("test_bitfieldOffsetMultiplier", test_bitfieldOffsetMultiplier),
            ("test_bitfieldWRAP", test_bitfieldWRAP),
            ("test_bitfieldSAT", test_bitfieldSAT),
            ("test_bitfieldFAIL", test_bitfieldFAIL),
            ("test_bitfieldMultiSubcommands", test_bitfieldMultiSubcommands),
        ]
    }
    
    var key = "key"
    
    func test_bitfieldGet() {
        setup(major: 3, minor: 2, micro: 0) {
            redis.bitfield(key: key, subcommands: .get("u4", 0), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0]?.asInteger, 0)
            })
        }
    }
    
    func test_bitfieldSet() {
        setup(major: 3, minor: 2, micro: 0) {
            redis.bitfield(key: key, subcommands: .set("i5", "4", 1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0]?.asInteger, 0)
            })
        }
    }
    
    func test_bitfieldIncrby() {
        setup(major: 3, minor: 2, micro: 0) {
            redis.bitfield(key: key, subcommands: .incrby("i5", "100", 1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0]?.asInteger, 1)
            })
        }
    }
    
    func test_bitfieldOffsetMultiplier() {
        setup(major: 3, minor: 2, micro: 0) {
            redis.bitfield(key: key, subcommands: .incrby("u8", "#0", 1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0]?.asInteger, 1)
            })
        }
    }
    
    func test_bitfieldWRAP() {
        setup(major: 3, minor: 2, micro: 0) {
            redis.bitfield(key: key, subcommands: .overflow(.WRAP), .incrby("u2", "0", 2), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0]?.asInteger, 2)
                
                redis.bitfield(key: key, subcommands: .overflow(.WRAP), .incrby("u2", "0", 2), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?[0]?.asInteger, 0)
                })
            })
        }
    }
    
    func test_bitfieldSAT() {
        setup(major: 3, minor: 2, micro: 0) {
            redis.bitfield(key: key, subcommands: .overflow(.SAT), .incrby("i4", "100", -900), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0]?.asInteger, -8)
            })
        }
    }
    
    func test_bitfieldFAIL() {
        setup(major: 3, minor: 2, micro: 0) {
            redis.bitfield(key: key, subcommands: .overflow(.FAIL), .incrby("u2", "102", 5), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0], RedisResponse.Nil)
            })
        }
    }
    
    func test_bitfieldMultiSubcommands() {
        setup(major: 3, minor: 2, micro: 0) {
            redis.bitfield(key: key, subcommands: .overflow(.SAT), .set("i2", "1", 3), .incrby("i5", "100", 1), .get("u4", 0), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0]?.asInteger, 0)
                XCTAssertEqual(res?[1]?.asInteger, 1)
                XCTAssertEqual(res?[2]?.asInteger, 2)
            })
        }
    }
}
