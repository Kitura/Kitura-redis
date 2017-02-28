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

public class TestTransactionsPart3: XCTestCase {
    static var allTests: [(String, (TestTransactionsPart3) -> () throws -> Void)] {
        return [
            ("test_keys", test_keys),
            ("test_randomkey", test_randomkey),
//            ("test_scan", test_scan),
            ("test_sort", test_sort),
            ("test_keyManipulation", test_keyManipulation),
            ("test_Move", test_Move),
            ("test_expiration", test_expiration),
            ("test_touch", test_touch),
            ("test_type", test_type)
        ]
    }

    var exp: XCTestExpectation?
    
    let key1 = "test1"
    let key2 = "test2"
    let key3 = "test3"
    let key4 = "test4"
    let key5 = "test5"

    let expVal1 = "Hi ho, hi ho"
    let expVal2 = "it's off to test"
    let expVal3 = "we go"
    let expVal4 = "Testing"
    let expVal5 = "testing 1 2 3"
    
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

    private func setupTests(callback: () -> Void) {
        connectRedis() {(error: NSError?) in
            if error != nil {
                XCTFail("Could not connect to Redis")
                return
            }
            
            redis.del(self.key1, self.key2, self.key3, self.key4) {(deleted: Int?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                
                callback()
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
    
    func test_keys() {
        setup(major: 1, minor: 0, micro: 0) { 
            exp = expectation(description: "Returns all keys matching `pattern`.")
            
            let multi = redis.multi()
            multi.mset((key1, "1"), (key2, "2"), (key3, "3"), (key4, "4"))
            multi.keys(pattern: "*1")
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 2) {
                    XCTAssertEqual(responses[0].asStatus, "OK")
                    XCTAssertEqual((responses[1].asArray)?[0].asString, RedisString(self.key1))
                    self.exp?.fulfill()
                }
                
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_randomkey() {
        setup(major: 1, minor: 0, micro: 0) { 
            exp = expectation(description: "Return a random key from the currently selected database.")
            
            let multi = redis.multi()
            multi.mset((key1, "1"))
            multi.randomkey()
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 2) {
                    XCTAssertEqual(responses[0].asStatus, "OK")
                    XCTAssertEqual(responses[1].asString, RedisString(self.key1))
                    self.exp?.fulfill()
                }
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_scan() {
        setup(major: 2, minor: 8, micro: 0) { 
            exp = expectation(description: "Iterate the set of keys in the currently selected Redis database.")
            
            let multi = redis.multi()
            multi.mset((key1, "val1"), (key2, "val2"))
            multi.scan(cursor: 0, match: "*1", count: 1)
            multi.scan(cursor: 0, match: "*1")
            multi.scan(cursor: 0, count: 1)
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 4) {
                    XCTAssertEqual(responses[0].asStatus, "OK")
                    XCTAssertEqual((responses[1].asArray)?[0].asString, RedisString("3"))
                    XCTAssertEqual(((responses[1].asArray)?[1].asArray)?[0].asString, RedisString(self.key1))
                    XCTAssertEqual((responses[2].asArray)?[0].asString, RedisString("0"))
                    XCTAssertEqual(((responses[1].asArray)?[1].asArray)?[0].asString, RedisString(self.key1))
                    XCTAssertEqual((responses[3].asArray)?[0].asString, RedisString("3"))
                    XCTAssertEqual(((responses[1].asArray)?[1].asArray)?[0].asString, RedisString(self.key1))
                    self.exp?.fulfill()
                }
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }

    func test_sort() {
        setup(major: 1, minor: 0, micro: 0) { 
            exp = expectation(description: "Returns or stores the elements contained in the list, set or sorted set at key.")
            
            let val1 = "1"
            let val2 = "2"
            let val3 = "3"
            let w1 = "1"
            let w2 = "2"
            let w3 = "3"
            let obj1 = "1"
            let obj2 = "2"
            let obj3 = "3"
            
            let multi = redis.multi()
            multi.lpush(key1, values: val1, val2, val3)
            multi.mset(("weight_1", w1), ("weight_2", w2), ("weight_3", w3), ("object_1", obj1), ("object_2", obj2), ("object_3", obj3))
            multi.sort(key: key1, by: "weight_*")
            multi.sort(key: key1, limit: (0, 1))
            multi.sort(key: key1, get: "object_*")
            multi.sort(key: key1, desc: true)
            multi.sort(key: key1, alpha: true)
            multi.sort(key: key1, store: key2)
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 8) {
                    
                    // lpush
                    XCTAssertEqual(responses[0].asInteger, 3)
                    
                    // mset
                    XCTAssertEqual(responses[1].asStatus, "OK")
                    
                    // sort by
                    XCTAssertEqual((responses[2].asArray)?[0].asString, RedisString(val1))
                    XCTAssertEqual((responses[2].asArray)?[1].asString, RedisString(val2))
                    XCTAssertEqual((responses[2].asArray)?[2].asString, RedisString(val3))
                    
                    // sort limit
                    XCTAssertEqual((responses[3].asArray)?[0].asString, RedisString(val1))
                    
                    // sort get
                    XCTAssertEqual((responses[4].asArray)?[0].asString, RedisString(obj1))
                    XCTAssertEqual((responses[4].asArray)?[1].asString, RedisString(obj2))
                    XCTAssertEqual((responses[4].asArray)?[2].asString, RedisString(obj3))
                    
                    // sort desc
                    XCTAssertEqual((responses[5].asArray)?[0].asString, RedisString(val3))
                    XCTAssertEqual((responses[5].asArray)?[1].asString, RedisString(val2))
                    XCTAssertEqual((responses[5].asArray)?[2].asString, RedisString(val1))
                    
                    // sort alpha
                    XCTAssertEqual((responses[6].asArray)?[0].asString, RedisString(val1))
                    XCTAssertEqual((responses[6].asArray)?[1].asString, RedisString(val2))
                    XCTAssertEqual((responses[6].asArray)?[2].asString, RedisString(val3))

                    // sort store
                    XCTAssertEqual(responses[7].asInteger, 3)
                    
                    self.exp?.fulfill()
                }
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_keyManipulation() {
        setupTests() {
            let multi = redis.multi()
            multi.mset((self.key1, self.expVal1), (self.key2, self.expVal2))
            multi.rename(self.key1, newKey: self.key3).get(self.key3)
            multi.rename(self.key3, newKey: self.key2, exists: false)
            multi.rename(self.key3, newKey: self.key4, exists: false)
            multi.exists(self.key1).exists(self.key4)

            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 7) {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.Status("OK"), "mset didn't return an 'OK'")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.Status("OK"), "Failed to rename \(self.key1) to \(self.key3)")
                    XCTAssertEqual(nestedResponses[2], RedisResponse.StringValue(RedisString(self.expVal1)), "\(self.key3) should have been equal to \(self.expVal1). Was \(nestedResponses[2].asString?.asString)")
                    XCTAssertEqual(nestedResponses[3], RedisResponse.IntegerValue(0), "Shouldn't have renamed \(self.key3) to \(self.key2)")
                    XCTAssertEqual(nestedResponses[4], RedisResponse.IntegerValue(1), "Should have renamed \(self.key3) to \(self.key4)")
                    XCTAssertEqual(nestedResponses[5], RedisResponse.IntegerValue(0), "\(self.key1) shouldn't exist")
                    XCTAssertEqual(nestedResponses[6], RedisResponse.IntegerValue(1), "\(self.key4) should exist")
                }
            }
        }
    }

    func test_Move() {
        setupTests() {
            let multi = redis.multi()
            multi.select(1).set(self.key1, value: self.expVal1).move(self.key1, toDB: 0)
            multi.get(self.key1).select(0).get(self.key1)
            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 6) {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.Status("OK"), "Select(1) didn't return an 'OK'")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.Status("OK"), "set didn't return an 'OK'")
                    XCTAssertEqual(nestedResponses[2], RedisResponse.IntegerValue(1), "Should have moved \(self.key1) to DB 0")
                    XCTAssertEqual(nestedResponses[3], RedisResponse.Nil, "\(self.key1) should no longer exist in DB 1")
                    XCTAssertEqual(nestedResponses[4], RedisResponse.Status("OK"), "Select(0) didn't return an 'OK'")
                    XCTAssertEqual(nestedResponses[5], RedisResponse.StringValue(RedisString(self.expVal1)), "\(self.key1) should have been equal to \(self.expVal1). Was \(nestedResponses[5].asString?.asString)")
                }
            }
        }
    }

    func test_expiration() {
        setupTests() {
            let expiration = 1.850

            let multi = redis.multi()
            multi.set(self.key1, value: self.expVal1).ttl(self.key1)
            multi.expire(self.key1, inTime: expiration).ttl(self.key1).persist(self.key1)
            let timeFromNow = 120.0
            let date = NSDate(timeIntervalSinceNow: timeFromNow)
            multi.expire(self.key1, atDate: date).ttl(self.key1)

            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 7) {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.Status("OK"), "set didn't return an 'OK'")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.IntegerValue(-1), "\(self.key1) shouldn't have an expiration. It has \(nestedResponses[1].asInteger)")
                    XCTAssertEqual(nestedResponses[2], RedisResponse.IntegerValue(1), "Expiration for \(self.key1) wasn't set")
                    var intResponse = nestedResponses[3].asInteger
                    XCTAssertNotNil(intResponse, "ttl for \(self.key1) was nil")
                    var expectedAsInt = Int64(expiration*1000.0)
                    XCTAssert(expectedAsInt-1000 <= intResponse!  &&  intResponse! <= expectedAsInt+1000, "ttl for \(self.key1) should be approximately \(expectedAsInt). It was \(intResponse!)")
                    XCTAssertEqual(nestedResponses[4], RedisResponse.IntegerValue(1), "Expiration for \(self.key1) wasn't reset")
                    XCTAssertEqual(nestedResponses[5], RedisResponse.IntegerValue(1), "Expiration for \(self.key1) wasn't set")
                    intResponse = nestedResponses[6].asInteger
                    XCTAssertNotNil(intResponse, "ttl for \(self.key1) was nil")
                    expectedAsInt = Int64(timeFromNow*1000.0)
                    XCTAssert(expectedAsInt-1000 <= intResponse!  &&  intResponse! <= expectedAsInt+1000, "ttl for \(self.key1) should be approximately \(expectedAsInt). It was \(intResponse!)")
                }
            }
        }
    }
    
    func test_touch() {
        setup(major: 3, minor: 2, micro: 1) { 
            exp = expectation(description: "Alters the last access time of a `key`(s). A key is ignored if it does not exist.")
            
            let multi = redis.multi()
            multi.set(key1, value: "1")
            multi.touch(key: key1)
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 2) {
                    XCTAssertEqual(responses[0].asStatus, "OK")
                    XCTAssertEqual(responses[1].asInteger, 1)
                    self.exp?.fulfill()
                }
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_type() {
        setup(major: 1, minor: 0, micro: 0) {
            exp = expectation(description: "Returns the string representation of the type of the value stored at `key`. The different types that can be returned are: string, list, set, zset and hash.")
            
            let multi = redis.multi()
            multi.set(key1, value: "1")
            multi.type(key: key1)
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 2) {
                    XCTAssertEqual(responses[0].asStatus, "OK")
                    XCTAssertEqual(responses[1].asStatus, "string")
                    self.exp?.fulfill()
                }
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
}
