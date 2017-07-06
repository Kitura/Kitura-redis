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

import SwiftRedis

import Foundation
import XCTest

//Tests the Set operations
public class TestTransactionsPart6: XCTestCase {
    static var allTests: [(String, (TestTransactionsPart6) -> () throws -> Void)] {
        return [
            ("test_keyManipulation", test_keyManipulation),
            ("test_MemberManipulation", test_MemberManipulation),
            ("test_ranges", test_ranges),
            ("tests_Remove", tests_Remove),
        ]
    }
    
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
    
    func test_keyManipulation() {
        setupTests() {
            let multi = redis.multi()
            multi.zadd(self.key1, tuples: (1, self.expVal1), (1, self.expVal2), (1, self.expVal3))
            multi.zadd(self.key2, tuples: (1, self.expVal2), (1, self.expVal4))
            multi.zunionstore(self.key3, numkeys: 2, keys: self.key1, self.key2)
            multi.zinterstore(self.key2, numkeys: 2, keys: self.key1, self.key3)
            
            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 4) {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.IntegerValue(3), "zadd only added \(nestedResponses[0]) tuples not 3")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.IntegerValue(2), "zadd only added \(nestedResponses[1]) tuples not 2")
                    XCTAssertEqual(nestedResponses[2], RedisResponse.IntegerValue(4), "There are only \(nestedResponses[2]) members not 4")
                    XCTAssertEqual(nestedResponses[3], RedisResponse.IntegerValue(3), "There are only \(nestedResponses[3]) members not 3")
                }
            }
        }
    }
    
    func test_MemberManipulation() {
        setupTests() {
            let multi = redis.multi()
            multi.zadd(self.key1, tuples: (1, self.expVal1), (1, self.expVal2), (1, self.expVal3))
            multi.zrem(self.key1, members: self.expVal2)
            multi.zcard(self.key1)
            multi.zincrby(self.key1, increment: 3, member: RedisString(self.expVal1))
            multi.zscore(self.key1, member: self.expVal3)
            
            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 5) {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.IntegerValue(3), "zadd only added \(nestedResponses[0]) tuples")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.IntegerValue(1), "Should have removed \(self.expVal2)")
                    XCTAssertEqual(nestedResponses[2], RedisResponse.IntegerValue(2), "There are only \(nestedResponses[2]) members not 2")
                    XCTAssertEqual(nestedResponses[3], RedisResponse.StringValue(RedisString("4")))
                    XCTAssertEqual(nestedResponses[4], RedisResponse.StringValue(RedisString("1")))
                }
            }
        }
    }
    
    func test_ranges() {
        let expectedRange = [RedisResponse.StringValue(RedisString(self.expVal2)),
                             RedisResponse.StringValue(RedisString(self.expVal3)),
                             RedisResponse.StringValue(RedisString(self.expVal4))]

        let expectedRangeLex = [RedisResponse.StringValue(RedisString("b")),
                                RedisResponse.StringValue(RedisString("c")),
                                RedisResponse.StringValue(RedisString("d")),
                                RedisResponse.StringValue(RedisString("e")),
                                RedisResponse.StringValue(RedisString("f"))]

        let expectedRangeScore = [RedisResponse.StringValue(RedisString(self.expVal2)),
                                  RedisResponse.StringValue(RedisString(self.expVal3)),
                                  RedisResponse.StringValue(RedisString(self.expVal4))]
        
        let expectedRevRange = [RedisResponse.StringValue(RedisString(self.expVal5)),
                                RedisResponse.StringValue(RedisString(self.expVal4)),
                                RedisResponse.StringValue(RedisString(self.expVal3)),
                                RedisResponse.StringValue(RedisString(self.expVal2)),
                                RedisResponse.StringValue(RedisString(self.expVal1))]
        
        let expectedRevRangeLex = [RedisResponse.StringValue(RedisString("c")),
                                RedisResponse.StringValue(RedisString("b")),
                                RedisResponse.StringValue(RedisString("a"))]
        
        setupTests() {
            let multi = redis.multi()
            multi.zadd(self.key1, tuples: (1, self.expVal1), (2, self.expVal2), (3, self.expVal3), (4, self.expVal4), (5, self.expVal5))
            multi.zadd(self.key2, tuples: (1, "a"), (1, "b"), (1, "c"), (1, "d"), (1, "e"), (1, "f"), (1, "g"))
            multi.zrange(self.key1, start: 1, stop: 3)
            multi.zrangebylex(self.key2, min: "[aaa", max: "(g")
            multi.zrangebyscore(self.key1, min: "2", max: "(5")
            multi.zrank(self.key1, member: self.expVal4)
            
            multi.zrevrange(self.key1, start: 0, stop: -1)
            multi.zrevrank(self.key1, member: self.expVal4)
            multi.zrevrangebylex(self.key2, min: "[c", max: "-")
            multi.zrevrangebyscore(self.key1, min: "+inf", max: "-inf")
            
            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 10) {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.IntegerValue(5), "Added only \(nestedResponses[0]) not 5")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.IntegerValue(7), "Added only \(nestedResponses[1]) not 7")
                    XCTAssertEqual(nestedResponses[2], RedisResponse.Array(expectedRange))
                    XCTAssertEqual(nestedResponses[3], RedisResponse.Array(expectedRangeLex))
                    XCTAssertEqual(nestedResponses[4], RedisResponse.Array(expectedRangeScore))
                    XCTAssertEqual(nestedResponses[5], RedisResponse.IntegerValue(3))
                    
                    XCTAssertEqual(nestedResponses[6], RedisResponse.Array(expectedRevRange), "Not equal")
                    XCTAssertEqual(nestedResponses[7], RedisResponse.IntegerValue(1))
                    XCTAssertEqual(nestedResponses[8], RedisResponse.Array(expectedRevRangeLex))
                    XCTAssertEqual(nestedResponses[9], RedisResponse.Array(expectedRevRange))
                }
            }
        }
    }
    
    func tests_Remove() {
        setupTests {
            let multi = redis.multi()
            multi.zadd(self.key1, tuples: (1, "a"), (1, "b"), (1, "c"), (1, "d"), (1, "e"), (1, "f"), (1, "g"))
            multi.zcount(self.key1, min: "-inf", max: "+inf")
            multi.zlexcount(self.key1, min: "[b", max: "[f")
            multi.zremrangebylex(self.key1, min: "[b", max: "[f")
            
            multi.zadd(self.key2, tuples: (1, "a"), (2, "b"), (3, "c"), (4, "d"), (5, "e"), (6, "f"), (7, "g"))
            multi.zremrangebyrank(self.key2, start: 4, stop: 6)
            multi.zcount(self.key2, min: "-inf", max: "+inf")
            
            multi.zadd(self.key3, tuples: (1, "a"), (2, "b"), (3, "c"), (4, "d"), (5, "e"), (6, "f"), (7, "g"))
            multi.zremrangebyscore(self.key3, min: "-inf", max: "(4")
            multi.zcount(self.key3, min: "-inf", max: "+inf")
            
            multi.exec() {(response: RedisResponse) in
                if let nestedResponses = self.baseAsserts(response: response, count: 10){
                    XCTAssertEqual(nestedResponses[0], RedisResponse.IntegerValue(7), "Added only \(nestedResponses[0]) not 7")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.IntegerValue(7), "There were only \(nestedResponses[1]) in \(self.key1)")
                    XCTAssertEqual(nestedResponses[2], RedisResponse.IntegerValue(5), "Returned \(nestedResponses[2]) not 5")
                    XCTAssertEqual(nestedResponses[3], RedisResponse.IntegerValue(5), "Removed \(nestedResponses[3]) not 5")
                    
                    XCTAssertEqual(nestedResponses[4], RedisResponse.IntegerValue(7), "Added only \(nestedResponses[4]) not 7")
                    XCTAssertEqual(nestedResponses[5], RedisResponse.IntegerValue(3), "Removed \(nestedResponses[5]) not 3")
                    XCTAssertEqual(nestedResponses[6], RedisResponse.IntegerValue(4), "There are \(nestedResponses[6]) not 4 in \(self.key2)")
                    
                    XCTAssertEqual(nestedResponses[7], RedisResponse.IntegerValue(7), "Added only \(nestedResponses[7]) not 7")
                    XCTAssertEqual(nestedResponses[8], RedisResponse.IntegerValue(3), "Removed \(nestedResponses[5]) not 3")
                    XCTAssertEqual(nestedResponses[9], RedisResponse.IntegerValue(4), "There are \(nestedResponses[6]) not 4 in \(self.key2)")
                }
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
}
