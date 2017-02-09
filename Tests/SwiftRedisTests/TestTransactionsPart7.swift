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

//Tests the Set operations
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
            
            // Part 3
            ("test_blpopBrpopAndBrpoplpushEmptyLists", test_blpopBrpopAndBrpoplpushEmptyLists),
            ("test_blpop", test_blpop)
        ]
    }
    
    let secondConnection = Redis()
    
    let queue = DispatchQueue(label: "unblocker", attributes: DispatchQueue.Attributes.concurrent)
    
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
    
    func extendedSetup(block: () -> Void) {
        localSetup() {
            let password = read(fileName: "password.txt")
            let host = read(fileName: "host.txt")
            
            self.secondConnection.connect(host: host, port: 6379) {(error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                
                self.secondConnection.auth(password) {(error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    
                    block()
                }
            }
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
            
            multi.exec() {(response: RedisResponse) in
                if let nestedResponses = self.baseAsserts(response: response, count: 5) {
                    let response1 = nestedResponses[0].asInteger
                    let response2 = nestedResponses[1].asString
                    let response3 = nestedResponses[2].asInteger
                    let response4 = nestedResponses[3]
                    let response5 = nestedResponses[4].asInteger
                    
                    XCTAssertEqual(response1, 2, "Failed to lpush \(self.key1)")
                    XCTAssertEqual(response2, RedisString(value2), "Popped \(response2) for \(self.key1) instead of \(value2)")
                    XCTAssertEqual(response3, 2, "Failed to lpushx \(self.key1)")
                    XCTAssertEqual(response4, RedisResponse.Nil, "Result of lpop was not nil, but \(self.key3) does not exist")
                    XCTAssertEqual(response5, 0, "lpushx to \(self.key3) should have returned 0 (list not found) returned \(response5)")
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
            
            multi.exec() {(response: RedisResponse) in
                if let nestedResponses = self.baseAsserts(response: response, count: 5) {
                    let response1 = nestedResponses[0].asInteger
                    let response2 = nestedResponses[1].asString
                    let response3 = nestedResponses[2].asInteger
                    let response4 = nestedResponses[3]
                    let response5 = nestedResponses[4].asInteger
                    
                    XCTAssertEqual(response1, 2, "Failed to lpush \(self.key1)")
                    XCTAssertEqual(response2, value2, "Popped \(response2) for \(self.key1) instead of \(value2)")
                    XCTAssertEqual(response3, 2, "Failed to lpushx \(self.key1)")
                    XCTAssertEqual(response4, RedisResponse.Nil, "Result of lpop was not nil, but \(self.key3) does not exist")
                    XCTAssertEqual(response5, 0, "lpushx to \(self.key3) should have returned 0 (list not found) returned \(response5)")
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
            
            multi.exec() {(response: RedisResponse) in
                if let nestedResponses = self.baseAsserts(response: response, count: 5) {
                    let response1 = nestedResponses[0].asInteger
                    let response2 = nestedResponses[1].asString
                    let response3 = nestedResponses[2].asInteger
                    let response4 = nestedResponses[3]
                    let response5 = nestedResponses[4].asInteger
                    
                    XCTAssertEqual(response1, 2, "Failed to rpush \(self.key1)")
                    XCTAssertEqual(response2, RedisString(value2), "Popped \(response2) for \(self.key1) instead of \(value2)")
                    XCTAssertEqual(response3, 2, "Failed to rpushx \(self.key1)")
                    XCTAssertEqual(response4, RedisResponse.Nil, "Result of rpop was not nil, but \(self.key3) does not exist")
                    XCTAssertEqual(response5, 0, "rpushx to \(self.key3) should have returned 0 (list not found) returned \(response5)")
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
            
            multi.exec() {(response: RedisResponse) in
                if let nestedResponses = self.baseAsserts(response: response, count: 5) {
                    let response1 = nestedResponses[0].asInteger
                    let response2 = nestedResponses[1].asString
                    let response3 = nestedResponses[2].asInteger
                    let response4 = nestedResponses[3]
                    let response5 = nestedResponses[4].asInteger
                    
                    XCTAssertEqual(response1, 2, "Failed to rpush \(self.key1)")
                    XCTAssertEqual(response2, value2, "Popped \(response2) for \(self.key1) instead of \(value2)")
                    XCTAssertEqual(response3, 2, "Failed to rpushx \(self.key1)")
                    XCTAssertEqual(response4, RedisResponse.Nil, "Result of rpop was not nil, but \(self.key3) does not exist")
                    XCTAssertEqual(response5, 0, "rpushx to \(self.key3) should have returned 0 (list not found) returned \(response5)")
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
            let binaryValue1 = RedisString("testing 1 2 3")
            let binaryValue2 = RedisString("over the hill and through the woods")
            let binaryValue3 = RedisString("to grandmothers house we go")
            let binaryValue4 = RedisString("singing away we go")
            
            redis.lpush(self.key1, values: value1, value2, value3, value4) {(numberSet: Int?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                
                redis.lrange(self.key1, start: 1, end: 2) {(returnedValues: [RedisString?]?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(returnedValues, "Result of lrange was nil, without an error")
                    XCTAssertEqual(returnedValues!.count, 2, "Number of values returned by lrange was \(returnedValues!.count) should have been 2")
                    XCTAssertEqual(returnedValues![0], RedisString(value3), "Returned value #1 was \(returnedValues![0]) should have been \(value3)")
                    XCTAssertEqual(returnedValues![1], RedisString(value2), "Returned value #2 was \(returnedValues![1]) should have been \(value2)")
                    
                    redis.lrem(self.key1, count: 3, value: value3) {(removedValues: Int?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(removedValues, "Result of lrem was nil, without an error")
                        XCTAssertEqual(removedValues!, 1, "Number of values removed by lrem was \(removedValues!) should have been 1")
                        
                        redis.lpush(self.key2, values: binaryValue4, binaryValue3, binaryValue2, binaryValue1) {(numberSet: Int?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            
                            redis.lrange(self.key2, start: 1, end: 2) {(returnedValues: [RedisString?]?, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssertNotNil(returnedValues, "Result of lrange was nil, without an error")
                                XCTAssertEqual(returnedValues!.count, 2, "Number of values returned by lrange was \(returnedValues!.count) should have been 2")
                                XCTAssertEqual(returnedValues![0], binaryValue2, "Returned value #1 was \(returnedValues![0]) should have been \(binaryValue2)")
                                XCTAssertEqual(returnedValues![1], binaryValue3, "Returned value #2 was \(returnedValues![1]) should have been \(binaryValue3)")
                                
                                redis.lrem(self.key1, count: 3, value: binaryValue2) {(removedValues: Int?, error: NSError?) in
                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                    XCTAssertNotNil(removedValues, "Result of lrem was nil, without an error")
                                    XCTAssertEqual(removedValues!, 1, "Number of values removed by lrem was \(removedValues!) should have been 1")
                                }
                            }
                        }
                    }
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
            
            redis.lpush(self.key1, values: value3, value1) {(numberSet: Int?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                
                let multi = redis.multi()
                
                multi.linsert(self.key1, before: true, pivot: value3, value: value2)
                multi.llen(self.key1)
                multi.lindex(self.key1, index: 0)
                
                multi.exec() {(response: RedisResponse) in
                    if let nestedResponses = self.baseAsserts(response: response, count: 3) {
                        let response1 = nestedResponses[0].asInteger
                        let response2 = nestedResponses[1].asInteger
                        let response3 = nestedResponses[2].asString
                        XCTAssertEqual(response1, 3, "LINSERT returned \(response1), should be 3")
                        XCTAssertEqual(response2, 3, "LLET returned \(response2), should be 3")
                        XCTAssertEqual(response3, RedisString(value1), "LINDEX returned \(response3), should be \(value1).")
                    }
                }
            }
        }
    }
    
    func test_binaryLindexLinsertAndLlen() {
        localSetup() {
            let value1 = RedisString("cash me")
            let value2 = RedisString("ousside")
            let value3 = RedisString("howbowda")
            
            redis.lpush(self.key1, values: value3, value1) {(numberSet: Int?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                
                let multi = redis.multi()
                
                multi.linsert(self.key1, before: true, pivot: value3, value: value2)
                multi.llen(self.key1)
                multi.lindex(self.key1, index: 0)
                
                multi.exec() {(response: RedisResponse) in
                    if let nestedResponses = self.baseAsserts(response: response, count: 3) {
                        let response1 = nestedResponses[0].asInteger
                        let response2 = nestedResponses[1].asInteger
                        let response3 = nestedResponses[2].asString
                        XCTAssertEqual(response1, 3, "LINSERT returned \(response1), should be 3")
                        XCTAssertEqual(response2, 3, "LLET returned \(response2), should be 3")
                        XCTAssertEqual(response3, value1, "LINDEX returned \(response3), should be \(value1).")
                    }
                }
            }
        }
    }
    
    // MARK: - Part 3
    func test_blpopBrpopAndBrpoplpushEmptyLists() {
        localSetup() {
            let multi = redis.multi()
            
            multi.blpop(self.key1, self.key2, timeout: 4.0)
            multi.blpop(self.key1, self.key2, timeout: 4.0)
            
            multi.exec() {(response: RedisResponse) in
                if let nestedResponses = self.baseAsserts(response: response, count: 2) {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.Nil, "A blpop that timed out should have returned nil. It returned \(nestedResponses[0])")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.Nil, "A blpop that timed out should have returned nil. It returned \(nestedResponses[1])")
                }
            }
        }
    }
    
    func test_blpop() {
        extendedSetup() {
            let value1 = "testing 1 2 3"
            let value2 = "above and beyond"
            
            self.queue.async { [unowned self] in
                sleep(2)   // Wait a bit to let the main test block
                self.secondConnection.lpush(self.key2, values: value1, value2) {(listSize: Int?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(listSize, "Result of lpush was nil, but \(self.key2) should exist")
                }
            }
            
            let multi = redis.multi()
            
            multi.blpop(self.key2, timeout: 4.0)
            multi.blpop(self.key2, timeout: 4.0)
            
            // It looks like BLPOP in a transcation block always returns nil.
            // The Redis docs say something similar.
            multi.exec() {(response: RedisResponse) in
//                if let nestedResponses = self.baseAsserts(response: response, count: 2) {
                    //                    XCTAssertEqual(nestedResponses[0], RedisResponse.Nil, "A blpop that timed out should have returned nil. It returned \(nestedResponses[0])")
                    //                    XCTAssertEqual(nestedResponses[1], RedisResponse.Nil, "A blpop that timed out should have returned nil. It returned \(nestedResponses[1])")
//                }
            }
            
            redis.blpop(self.key1, self.key2, self.key3, timeout: 4.0) {(retrievedValue: [RedisString?]?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssertNotNil(retrievedValue, "blpop should not have returned nil.")
                XCTAssertEqual(retrievedValue!.count, 2, "blpop should have returned an array of two elements. It returned an array of \(retrievedValue!.count) elements")
                XCTAssertEqual(retrievedValue![0], RedisString(self.key2), "blpop's return value element #0 should have been \(self.key2). It was \(retrievedValue![0])")
                XCTAssertEqual(retrievedValue![1], RedisString(value2), "blpop's return value element #1 should have been \(value2). It was \(retrievedValue![1])")
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
}
