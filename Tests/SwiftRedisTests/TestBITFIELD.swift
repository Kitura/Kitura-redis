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

public class TestBITFIELD: XCTestCase {
    
    static var allTests: [(String, (TestBITFIELD) -> () throws -> Void)] {
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
    
    var exp: XCTestExpectation?
    var key = "key"
    
    private func setup(major: Int, minor: Int, micro: Int, callback: () -> Void) {
        connectRedis() {(err) in
            guard err == nil else {
                XCTFail()
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
    
    func test_bitfieldGet() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return the specified bit field.")
            
            redis.bitfield(key: key, subcommands: .get("u4", 0), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0]?.asInteger, 0)
                exp?.fulfill()
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_bitfieldSet() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return the specified bit field.")
            
            redis.bitfield(key: key, subcommands: .set("i5", "4", 1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0]?.asInteger, 0)
                exp?.fulfill()
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_bitfieldIncrby() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Increment bitfield and return new value.")
            
            redis.bitfield(key: key, subcommands: .incrby("i5", "100", 1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0]?.asInteger, 1)
                exp?.fulfill()
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_bitfieldOffsetMultiplier() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Use # to multiply offset by integer type.")
            
            redis.bitfield(key: key, subcommands: .incrby("u8", "#0", 1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0]?.asInteger, 1)
                exp?.fulfill()
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_bitfieldWRAP() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "On overflows, wraps back to min value, and vise versa.")
            
            redis.bitfield(key: key, subcommands: .overflow(.WRAP), .incrby("u2", "0", 2), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0]?.asInteger, 2)
                
                redis.bitfield(key: key, subcommands: .overflow(.WRAP), .incrby("u2", "0", 2), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?[0]?.asInteger, 0)
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_bitfieldSAT() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "On underflows the value is set to the minimum integer value, and on overflows to the maximum integer value.")
            
            redis.bitfield(key: key, subcommands: .overflow(.SAT), .incrby("i4", "100", -900), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0]?.asInteger, -8)
                exp?.fulfill()
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_bitfieldFAIL() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "No operation is performed on overflows or underflows.")
            
            redis.bitfield(key: key, subcommands: .overflow(.FAIL), .incrby("u2", "102", 5), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0], RedisResponse.Nil)
                exp?.fulfill()
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_bitfieldMultiSubcommands() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Chain multiple subcommands in a BITFIELD command.")
            
            redis.bitfield(key: key, subcommands: .overflow(.SAT), .set("i2", "1", 3), .incrby("i5", "100", 1), .get("u4", 0), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res?[0]?.asInteger, 0)
                XCTAssertEqual(res?[1]?.asInteger, 1)
                XCTAssertEqual(res?[2]?.asInteger, 2)
                exp?.fulfill()
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
}
