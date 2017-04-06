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

// Tests the List transaction operations
public class TestTransactionsPart7: XCTestCase {
    static var allTests: [(String, (TestTransactionsPart7) -> () throws -> Void)] {
        return [
            // Part 1
            ("test_lpushAndLpop", test_lpushAndLpop),
            ("test_binaryLpushAndLpop", test_binaryLpushAndLpop),
            ("test_rpushAndRpop", test_rpushAndRpop),
            ("test_binaryRpushAndRpop", test_binaryRpushAndRpop),
            ("test_lrangeAndLrem", test_lrangeAndLrem),
            
            // Part 2
            ("test_lindexLinsertAndLlen", test_lindexLinsertAndLlen),
            ("test_binaryLindexLinsertAndLlen", test_binaryLindexLinsertAndLlen),
            ("test_lsetAndLtrim", test_lsetAndLtrim),
            ("test_binaryLsetAndLtrim", test_binaryLsetAndLtrim),
            ("test_rpoplpush", test_rpoplpush),
            
            // Part 3
            ("test_blpopBrpopAndBrpoplpushEmptyLists", test_blpopBrpopAndBrpoplpushEmptyLists),
            ("test_blpop", test_blpop),
            ("test_brpop", test_brpop),
            ("test_brpoplpush", test_brpoplpush)
        ]
    }
    
    var key1: String { return "test1" }
    var key2: String { return "test2" }
    var key3: String { return "test3" }
    
    func localSetup(block: () -> Void) {
        connectRedis() {(error: NSError?) in
            if error != nil {
                XCTFail("Could not connect to Redis")
                return
            }
            
            redis.del(self.key1, self.key2, self.key3) {(deleted: Int?, error: NSError?) in
                block()
            }
        }
    }
    
    private func baseAsserts(response: RedisResponse, count: Int) -> [RedisResponse]? {
        switch(response) {
        case .Array(let responses):
            XCTAssertEqual(responses.count, count, "Number of nested responses wasn't \(count), was \(responses.count)")
            for  nestedResponse in responses {
                switch(nestedResponse) {
                case .Error:
                    XCTFail("Nested transaction response was a \(nestedResponse)")
                    return nil
                default:
                    break
                }
            }
            return responses
        default:
            XCTFail("EXEC response wasn't an Array response. Was \(response)")
            return nil
        }
    }
    
    // MARK: - Part 1
    func test_lpushAndLpop() {
        localSetup() {
            let value1 = "rain drop"
            let value2 = "drop top"
            let value3 = "hitmontop"
            
            let multi = redis.multi()
            
            multi.lpush(self.key1, values: value1, value2)
            multi.lpop(self.key1)
            multi.lpushx(self.key1, value: value3)
            multi.lpop(self.key3)
            multi.lpushx(self.key3, value: value3)
            
            multi.exec() { (response: RedisResponse) in
                if let nestedResponses = self.baseAsserts(response: response, count: 5) {
                    let response1 = nestedResponses[0].asInteger
                    let response2 = nestedResponses[1].asString
                    let response3 = nestedResponses[2].asInteger
                    let response4 = nestedResponses[3]
                    let response5 = nestedResponses[4].asInteger
                    
                    // lpush(self.key1, values: value1, value2)
                    XCTAssertNotNil(response1, "Result of lpush was nil, without an error")
                    XCTAssertEqual(response1, 2, "Failed to lpush \(self.key1)")
                    
                    // lpop(self.key1)
                    XCTAssertNotNil(response2, "Result of lpop was nil, but \(self.key1) should exist")
                    XCTAssertEqual(response2, RedisString(value2), "Popped \(String(describing: response2)) for \(self.key1) instead of \(value2)")
                    
                    // lpushx(self.key1, value: value3)
                    XCTAssertNotNil(response3, "Result of lpushx was nil, without an error")
                    XCTAssertEqual(response3, 2, "Failed to lpushx \(self.key1)")
                    
                    // lpop(self.key3)
                    XCTAssertEqual(response4, RedisResponse.Nil, "Result of lpop was not nil, but \(self.key3) does not exist")
                    
                    // lpushx(self.key3, value: value3)
                    XCTAssertNotNil(response5, "Result of lpushx was nil, without an error")
                    XCTAssertEqual(response5, 0, "lpushx to \(self.key3) should have returned 0 (list not found) returned \(String(describing: response5))")
                }
            }
        }
    }
    
    func test_binaryLpushAndLpop() {
        localSetup() {
            let value1 = RedisString("rain drop")
            let value2 = RedisString("drop top")
            let value3 = RedisString("hitmontop")
            
            let multi = redis.multi()
            
            multi.lpush(self.key1, values: value1, value2)
            multi.lpop(self.key1)
            multi.lpushx(self.key1, value: value3)
            multi.lpop(self.key3)
            multi.lpushx(self.key3, value: value3)
            
            multi.exec() { (response: RedisResponse) in
                if let nestedResponses = self.baseAsserts(response: response, count: 5) {
                    let response1 = nestedResponses[0].asInteger
                    let response2 = nestedResponses[1].asString
                    let response3 = nestedResponses[2].asInteger
                    let response4 = nestedResponses[3]
                    let response5 = nestedResponses[4].asInteger
                    
                    // lpush(self.key1, values: value1, value2)
                    XCTAssertNotNil(response1, "Result of lpush was nil, without an error")
                    XCTAssertEqual(response1, 2, "Failed to lpush \(self.key1)")
                    
                    // lpop(self.key1)
                    XCTAssertNotNil(response2, "Result of lpop was nil, but \(self.key1) should exist")
                    XCTAssertEqual(response2, value2, "Popped \(String(describing: response2)) for \(self.key1) instead of \(value2)")
                    
                    // lpushx(self.key1, value: value3)
                    XCTAssertNotNil(response3, "Result of lpushx was nil, without an error")
                    XCTAssertEqual(response3, 2, "Failed to lpushx \(self.key1)")
                    
                    // lpop(self.key3)
                    XCTAssertEqual(response4, RedisResponse.Nil, "Result of lpop was not nil, but \(self.key3) does not exist")
                    
                    // lpushx(self.key3, value: value3)
                    XCTAssertNotNil(response5, "Result of lpushx was nil, without an error")
                    XCTAssertEqual(response5, 0, "lpushx to \(self.key3) should have returned 0 (list not found) returned \(String(describing: response5))")
                }
            }
        }
    }
    
    func test_rpushAndRpop() {
        localSetup() {
            let value1 = "blowing fresh"
            let value2 = "nothing less"
            let value3 = "we da best"
            
            let multi = redis.multi()
            
            multi.rpush(self.key1, values: value1, value2)
            multi.rpop(self.key1)
            multi.rpushx(self.key1, value: value3)
            multi.rpop(self.key3)
            multi.rpushx(self.key3, value: value3)
            
            multi.exec() { (response: RedisResponse) in
                if let nestedResponses = self.baseAsserts(response: response, count: 5) {
                    let response1 = nestedResponses[0].asInteger
                    let response2 = nestedResponses[1].asString
                    let response3 = nestedResponses[2].asInteger
                    let response4 = nestedResponses[3]
                    let response5 = nestedResponses[4].asInteger
                    
                    // rpush(self.key1, values: value1, value2)
                    XCTAssertNotNil(response1, "Result of rpush was nil, without an error")
                    XCTAssertEqual(response1, 2, "Failed to rpush \(self.key1)")
                    
                    // rpop(self.key1)
                    XCTAssertNotNil(response2, "Result of rpop was nil, but \(self.key1) should exist")
                    XCTAssertEqual(response2, RedisString(value2), "Popped \(String(describing: response2)) for \(self.key1) instead of \(value2)")
                    
                    // rpushx(self.key1, value: value3)
                    XCTAssertNotNil(response3, "Result of rpushx was nil, without an error")
                    XCTAssertEqual(response3, 2, "Failed to rpushx \(self.key1)")
                    
                    // rpop(self.key3)
                    XCTAssertEqual(response4, RedisResponse.Nil, "Result of rpop was not nil, but \(self.key3) does not exist")
                    
                    // rpushx(self.key3, value: value3)
                    XCTAssertNotNil(response5, "Result of rpushx was nil, without an error")
                    XCTAssertEqual(response5, 0, "rpushx to \(self.key3) should have returned 0 (list not found) returned \(String(describing: response5))")
                }
            }
        }
    }
    
    func test_binaryRpushAndRpop() {
        localSetup() {
            let value1 = RedisString("blowing fresh")
            let value2 = RedisString("nothing less")
            let value3 = RedisString("we da best")
            
            let multi = redis.multi()
            
            multi.rpush(self.key1, values: value1, value2)
            multi.rpop(self.key1)
            multi.rpushx(self.key1, value: value3)
            multi.rpop(self.key3)
            multi.rpushx(self.key3, value: value3)
            
            multi.exec() { (response: RedisResponse) in
                if let nestedResponses = self.baseAsserts(response: response, count: 5) {
                    let response1 = nestedResponses[0].asInteger
                    let response2 = nestedResponses[1].asString
                    let response3 = nestedResponses[2].asInteger
                    let response4 = nestedResponses[3]
                    let response5 = nestedResponses[4].asInteger
                    
                    // rpush(self.key1, values: value1, value2)
                    XCTAssertNotNil(response1, "Result of rpush was nil, without an error")
                    XCTAssertEqual(response1, 2, "Failed to rpush \(self.key1)")
                    
                    // rpop(self.key1)
                    XCTAssertNotNil(response2, "Result of rpop was nil, but \(self.key1) should exist")
                    XCTAssertEqual(response2, value2, "Popped \(String(describing: response2)) for \(self.key1) instead of \(value2)")
                    
                    // rpushx(self.key1, value: value3)
                    XCTAssertNotNil(response3, "Result of rpushx was nil, without an error")
                    XCTAssertEqual(response3, 2, "Failed to rpushx \(self.key1)")
                    
                    // rpop(self.key3)
                    XCTAssertEqual(response4, RedisResponse.Nil, "Result of rpop was not nil, but \(self.key3) does not exist")
                    
                    // rpushx(self.key3, value: value3)
                    XCTAssertNotNil(response5, "Result of rpushx was nil, without an error")
                    XCTAssertEqual(response5, 0, "rpushx to \(self.key3) should have returned 0 (list not found) returned \(String(describing: response5))")
                }
            }
        }
    }
    
    func test_lrangeAndLrem() {
        localSetup() {
            let value1 = "testing 1 2 3"
            let value2 = "over the hill and through the woods"
            let value3 = "to grandmothers house we go"
            let value4 = "singing away we go"
            let binaryValue1 = RedisString(value1)
            let binaryValue2 = RedisString(value2)
            let binaryValue3 = RedisString(value3)
            let binaryValue4 = RedisString(value4)
            
            let multi = redis.multi()
            
            multi.lpush(self.key1, values: value1, value2, value3, value4)
            multi.lrange(self.key1, start: 1, end: 2)
            multi.lrem(self.key1, count: 3, value: value3)
            multi.lpush(self.key2, values: binaryValue4, binaryValue3, binaryValue2, binaryValue1)
            multi.lrange(self.key2, start: 1, end: 2)
            multi.lrem(self.key1, count: 3, value: binaryValue2)
            
            multi.exec() { (response: RedisResponse) in
                if let nestedResponses = self.baseAsserts(response: response, count: 6) {
                    let response2 = nestedResponses[1].asArray
                    let response3 = nestedResponses[2].asInteger
                    let response5 = nestedResponses[4].asArray
                    let response6 = nestedResponses[5].asInteger
                    
                    // lrange(self.key1, start: 1, end: 2)
                    XCTAssertNotNil(response2, "Result of lrange was nil, without an error")
                    XCTAssertEqual(response2?.count, 2, "Number of values returned by lrange was \(String(describing: response2?.count)) should have been 2")
                    XCTAssertEqual(response2?[0].asString, RedisString(value3), "Returned value #1 was \(String(describing: response2?[0])) should have been \(value3)")
                    XCTAssertEqual(response2?[1].asString, RedisString(value2), "Returned value #2 was \(String(describing: response2?[1])) should have been \(value2)")
                    
                    // lrem(self.key1, count: 3, value: value3)
                    XCTAssertNotNil(response3, "Result of lrem was nil, without an error")
                    XCTAssertEqual(response3, 1, "Number of values removed by lrem was \(String(describing: response3)) should have been 1")
                    
                    //(self.key2, values: binaryValue4, binaryValue3, binaryValue2, binaryValue1)
                    XCTAssertNotNil(response5, "Result of lrange was nil, without an error")
                    XCTAssertEqual(response5?.count, 2, "Number of values returned by lrange was \(String(describing: response5?.count)) should have been 2")
                    XCTAssertEqual(response5?[0].asString, binaryValue2, "Returned value #1 was \(String(describing: response5?[0])) should have been \(binaryValue2)")
                    XCTAssertEqual(response5?[1].asString, binaryValue3, "Returned value #2 was \(String(describing: response5?[1])) should have been \(binaryValue3)")
                    
                    // lrem(self.key1, count: 3, value: binaryValue2)
                    XCTAssertNotNil(response6, "Result of lrem was nil, without an error")
                    XCTAssertEqual(response6, 1, "Number of values removed by lrem was \(String(describing: response6)) should have been 1")
                }
            }
        }
    }
    
    // MARK: - Part 2
    func test_lindexLinsertAndLlen() {
        localSetup() {
            let value1 = "cash me"
            let value2 = "oussah"
            let value3 = "howbowda"
            
            let multi = redis.multi()
            
            multi.lpush(self.key1, values: value1, value3)
            multi.linsert(self.key1, before: true, pivot: value3, value: value2)
            multi.llen(self.key1)
            multi.lindex(self.key1, index: 2)
            
            multi.exec() { (response: RedisResponse) in
                if let nestedResponses = self.baseAsserts(response: response, count: 4) {
                    let response2 = nestedResponses[1].asInteger
                    let response3 = nestedResponses[2].asInteger
                    let response4 = nestedResponses[3].asString
                    
                    // linsert(self.key1, before: true, pivot: value3, value: value2)
                    XCTAssertNotNil(response2, "Result of linsert was nil, but \(self.key1) should exist")
                    XCTAssertEqual(response2, 3, "Returned \(String(describing: response2)) for \(self.key1) instead of 3")
                    
                    // llen(self.key1)
                    XCTAssertNotNil(response3, "Result of llen was nil, but \(self.key1) should exist")
                    XCTAssertEqual(response3, 3, "Returned \(String(describing: response3)) for \(self.key1) instead of 3")
                    
                    // lindex(self.key1, index: 2)
                    XCTAssertNotNil(response4, "Result of lindex was nil, but \(self.key1) should exist")
                    XCTAssertEqual(response4, RedisString(value1), "Result of lindex was \(String(describing: response4)). It should have been \(value1)")
                }
            }
        }
    }
    
    func test_binaryLindexLinsertAndLlen() {
        localSetup() {
            let value1 = RedisString("cash me")
            let value2 = RedisString("oussah")
            let value3 = RedisString("howbowda")
            
            let multi = redis.multi()
            
            multi.lpush(self.key1, values: value1, value3)
            multi.linsert(self.key1, before: true, pivot: value3, value: value2)
            multi.llen(self.key1)
            multi.lindex(self.key1, index: 2)
            
            multi.exec() { (response: RedisResponse) in
                if let nestedResponses = self.baseAsserts(response: response, count: 4) {
                    let response2 = nestedResponses[1].asInteger
                    let response3 = nestedResponses[2].asInteger
                    let response4 = nestedResponses[3].asString
                    
                    // linsert(self.key1, before: true, pivot: value3, value: value2)
                    XCTAssertNotNil(response2, "Result of linsert was nil, but \(self.key1) should exist")
                    XCTAssertEqual(response2, 3, "Returned \(String(describing: response2)) for \(self.key1) instead of 3")
                    
                    // llen(self.key1)
                    XCTAssertNotNil(response3, "Result of llen was nil, but \(self.key1) should exist")
                    XCTAssertEqual(response3, 3, "Returned \(String(describing: response3)) for \(self.key1) instead of 3")
                    
                    // lindex(self.key1, index: 2)
                    XCTAssertNotNil(response4, "Result of lindex was nil, but \(self.key1) should exist")
                    XCTAssertEqual(response4, value1, "Result of lindex was \(String(describing: response4)). It should have been \(value1)")
                }
            }
        }
    }
    
    func test_lsetAndLtrim() {
        localSetup() {
            let value1 = "testing 1 2 3"
            let value2 = "over the hill and through the woods"
            let value3 = "to grandmothers house we go"
            
            let multi = redis.multi()
            
            multi.lpush(self.key1, values: value1, value3)
            multi.lset(self.key1, index: 1, value: value2)
            multi.lindex(self.key1, index: 1)
            multi.ltrim(self.key1, start: 0, end: 0)
            multi.llen(self.key1)
            
            multi.exec() { (response: RedisResponse) in
                if let nestedResponses = self.baseAsserts(response: response, count: 5) {
                    let response2 = nestedResponses[1].asStatus
                    let response3 = nestedResponses[2].asString
                    let response4 = nestedResponses[3].asStatus
                    let response5 = nestedResponses[4].asInteger
                    
                    // lset(self.key1, index: 1, value: value2)
                    XCTAssertEqual(response2, "OK", "lset failed")
                    
                    // lindex(self.key1, index: 1)
                    XCTAssertNotNil(response3, "Returned values of lindex was nil, even though no error occurred.")
                    XCTAssertEqual(response3, RedisString(value2), "lindex returned \(String(describing: response3)). It should have returned \(value2)")
                    
                    // ltrim(self.key1, start: 0, end: 0)
                    XCTAssertEqual(response4, "OK", "lset failed")
                    
                    // llen(self.key1)
                    XCTAssertNotNil(response5, "Returned values of llen was nil, even though no error occurred.")
                    XCTAssertEqual(response5, 1, "The length of the list was \(String(describing: response5)). It should have been 1.")
                }
            }
        }
    }
    
    func test_binaryLsetAndLtrim() {
        localSetup() {
            let value1 = RedisString("testing 1 2 3")
            let value2 = RedisString("over the hill and through the woods")
            let value3 = RedisString("to grandmothers house we go")
            
            let multi = redis.multi()
            
            multi.lpush(self.key1, values: value1, value3)
            multi.lset(self.key1, index: 1, value: value2)
            multi.lindex(self.key1, index: 1)
            multi.ltrim(self.key1, start: 0, end: 0)
            multi.llen(self.key1)
            
            multi.exec() { (response: RedisResponse) in
                if let nestedResponses = self.baseAsserts(response: response, count: 5) {
                    let response2 = nestedResponses[1].asStatus
                    let response3 = nestedResponses[2].asString
                    let response4 = nestedResponses[3].asStatus
                    let response5 = nestedResponses[4].asInteger
                    
                    // lset(self.key1, index: 1, value: value2)
                    XCTAssertEqual(response2, "OK", "lset failed")
                    
                    // lindex(self.key1, index: 1)
                    XCTAssertNotNil(response3, "Returned values of lindex was nil, even though no error occurred.")
                    XCTAssertEqual(response3, value2, "lindex returned \(String(describing: response3)). It should have returned \(value2)")
                    
                    // ltrim(self.key1, start: 0, end: 0)
                    XCTAssertEqual(response4, "OK", "lset failed")
                    
                    // llen(self.key1)
                    XCTAssertNotNil(response5, "Returned values of llen was nil, even though no error occurred.")
                    XCTAssertEqual(response5, 1, "The length of the list was \(String(describing: response5)). It should have been 1.")
                }
            }
        }
    }
    
    func test_rpoplpush() {
        localSetup() {
            let value1 = "testing 1 2 3"
            let value2 = "over the hill and through the woods"
            let value3 = "to grandmothers house we go"
            
            let multi = redis.multi()
            
            multi.rpush(self.key1, values: value1, value2, value3)
            multi.rpoplpush(self.key1, destination: self.key2)
            multi.llen(self.key1)
            multi.llen(self.key2)
            
            multi.exec() { (response: RedisResponse) in
                if let nestedResponses = self.baseAsserts(response: response, count: 4) {
                    let response2 = nestedResponses[1].asString
                    let response3 = nestedResponses[2].asInteger
                    let response4 = nestedResponses[3].asInteger
                    
                    // rpoplpush(self.key1, destination: self.key2)
                    XCTAssertNotNil(response2, "Returned values of rpoplpush was nil, even though no error occurred.")
                    XCTAssertEqual(response2, RedisString(value3), "rpoplpush returned \(String(describing: response2)). It should have returned \(value3)")
                    
                    // llen(self.key1)
                    XCTAssertNotNil(response3, "Returned values of llen was nil, even though no error occurred.")
                    XCTAssertEqual(response3, 2, "The length of the list \(self.key1) was \(String(describing: response3)). It should have been 2.")
                    
                    // llen(self.key2)
                    XCTAssertNotNil(response4, "Returned values of llen was nil, even though no error occurred.")
                    XCTAssertEqual(response4, 1, "The length of the list \(self.key2) was \(String(describing: response4)). It should have been 1.")
                }
            }
        }
    }
    
    // MARK: - Part 3
    
    // SEE NOTE IN RedisMulti+List.swift
    
    func test_blpopBrpopAndBrpoplpushEmptyLists() {
        localSetup() {
            let multi = redis.multi()
            
            multi.blpop(self.key1, self.key2, timeout: 4.0)
            multi.brpop(self.key3, self.key1, timeout: 5.0)
            multi.brpoplpush(self.key2, destination: self.key2, timeout: 3.0)
            
            multi.exec() { (response: RedisResponse) in
                if let nestedResponses = self.baseAsserts(response: response, count: 3) {
                    let response1 = nestedResponses[0]
                    let response2 = nestedResponses[1]
                    let response3 = nestedResponses[2]
                    
                    XCTAssertEqual(response1, RedisResponse.Nil, "A blpop that timed out should have returned nil. It returned \(response1)")
                    XCTAssertEqual(response2, RedisResponse.Nil, "A brpop that timed out should have returned nil. It returned \(response2)")
                    XCTAssertEqual(response3, RedisResponse.Nil, "A brpoplpush that timed out should have returned nil. It returned \(response3)")
                }
            }
        }
    }
    
    func test_blpop() {
        localSetup() {
            let value1 = "testing 1 2 3"
            
            let multi = redis.multi()
            
            multi.lpush(self.key2, values: value1)
            multi.blpop(self.key1, self.key2, self.key3, timeout: 4.0)
            
            multi.exec() { (response: RedisResponse) in
                if let nestedResponses = self.baseAsserts(response: response, count: 2) {
                    
                    let response1 = nestedResponses[0].asInteger
                    let response2 = nestedResponses[1].asArray
                    
                    // lpush(self.key2, values: value1)
                    XCTAssertNotNil(response1, "Result of lpush was nil, but \(self.key2) should exist")
                    
                    // blpop(self.key1, self.key2, self.key3, timeout: 4.0)
                    XCTAssertNotNil(response2, "blpop should not have returned nil.")
                    XCTAssertEqual(response2?.count, 2, "blpop should have returned an array of two elements. It returned an array of \(String(describing: response2?.count)) elements")
                    XCTAssertEqual(response2?[0].asString, RedisString(self.key2), "blpop's return value element #0 should have been \(self.key2). It was \(String(describing: response2?[0]))")
                    XCTAssertEqual(response2?[1].asString, RedisString(value1), "blpop's return value element #1 should have been \(value1). It was \(String(describing: response2?[1]))")
                }
            }
        }
    }
    
    func test_brpop() {
        localSetup() {
            let value2 = "over the hill and through the woods"
            
            let multi = redis.multi()
            
            multi.lpush(self.key3, values: value2)
            multi.brpop(self.key1, self.key2, self.key3, timeout: 4.0)
            
            multi.exec() { (response: RedisResponse) in
                if let nestedResponses = self.baseAsserts(response: response, count: 2) {
                    
                    let response1 = nestedResponses[0].asInteger
                    let response2 = nestedResponses[1].asArray
                    
                    // lpush(self.key3, values: value2)
                    XCTAssertNotNil(response1, "Result of lpush was nil, but \(self.key1) should exist")
                    
                    // brpop(self.key1, self.key2, self.key3, timeout: 4.0)
                    XCTAssertNotNil(response2, "brpop should not have returned nil.")
                    XCTAssertEqual(response2?.count, 2, "brpop should have returned an array of two elements. It returned an array of \(String(describing: response2?.count)) elements")
                    XCTAssertEqual(response2?[0].asString, RedisString(self.key3), "brpop's return value element #0 should have been \(self.key3). It was \(String(describing: response2?[0]))")
                    XCTAssertEqual(response2?[1].asString, RedisString(value2), "brpop's return value element #1 should have been \(value2). It was \(String(describing: response2?[1]))")
                }
            }
        }
    }
    
    func test_brpoplpush() {
        localSetup() {
            let value1 = "wet one"
            let value2 = "tsunami two"
            
            let multi = redis.multi()
            
            multi.lpush(self.key1, values: value1, value2)
            multi.brpoplpush(self.key1, destination: self.key2, timeout: 4.0)
            multi.brpoplpush(self.key1, destination: self.key2, timeout: 4.0)
            
            multi.exec() { (response: RedisResponse) in
                if let nestedResponses = self.baseAsserts(response: response, count: 3) {
                    let response2 = nestedResponses[1].asString
                    let response3 = nestedResponses[2].asString
                    
                    // brpoplpush(self.key1, destination: self.key2, timeout: 4.0)
                    XCTAssertNotNil(response2, "brpoplpush should not have returned nil.")
                    XCTAssertEqual(response2, RedisString(value1), "brpoplpush's return value  should have been \(value1). It was \(String(describing: response2))")
                    
                    // brpoplpush(self.key1, destination: self.key2, timeout: 4.0)
                    XCTAssertNotNil(response3, "brpoplpush should not have returned nil.")
                    XCTAssertEqual(response3, RedisString(value2), "brpoplpush's return value  should have been \(value2). It was \(String(describing: response3))")
                }
            }
        }
    }
}
