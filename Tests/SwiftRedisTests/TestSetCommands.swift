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

public class TestSetCommands: XCTestCase {
    static var allTests: [(String, (TestSetCommands) -> () throws -> Void)] {
        return [
            ("test_ZAdd", test_ZAdd),
            ("test_ZCard", test_ZCard),
            ("test_ZCount", test_ZCount),
            ("test_ZIncrby", test_ZIncrby),
            ("test_ZInterstore", test_ZInterstore),
            ("test_ZLexcount", test_ZLexcount),
            ("test_ZRange", test_ZRange),
            ("test_ZRangebylex", test_ZRangebylex),
            ("test_ZRank", test_ZRank),
            ("test_ZRem", test_ZRem),
            ("test_ZRemrangebylex", test_ZRemrangebylex),
            ("test_ZRemrangebyrank", test_ZRemrangebyrank),
            ("test_ZRemrangebyscore", test_ZRemrangebyscore),
            ("test_ZRevrange", test_ZRevrange),
            ("test_ZRevrangebylex", test_ZRevrangebylex),
            ("test_ZRevrangebyscore", test_ZRevrangebyscore),
            ("test_ZRevrank", test_ZRevrank),
            ("test_ZScore", test_ZScore),
            ("test_ZUnionstore", test_ZUnionstore),
            ("test_flushDB", test_flushDB)
        ]
    }


    let key1 = "test1"
    let key2 = "test2"

    func setupTests(callback: () -> Void) {
        connectRedis() {(error: NSError?) in
            if error != nil {
                XCTFail("Could not connect to Redis")
                return
            }

            redis.del(self.key1, self.key2) {(deleted: Int?, error: NSError?) in
                callback()
            }
        }
    }

    func test_ZAdd() {
        let expectation1 = expectation(description: "Add score(s) and member(s) to the set")

        setupTests {
            redis.zadd(self.key1, tuples: (1, "one"), (2, "two"), (3, "three")) {
                (result: Int?, error: NSError?) in

                XCTAssertNil(error)
                XCTAssertNotNil(result)

                redis.zrange(self.key1, start: 0, stop: 2, callback: {
                    (resultList: [RedisString?]?, zRangeError: NSError?) in

                    XCTAssertNil(zRangeError)

                    XCTAssertEqual(resultList?[0], RedisString("one"), "The first element of the list should be \(RedisString("one")). It was \(resultList?[0])")

                    XCTAssertEqual(resultList?[1], RedisString("two"), "The first element of the list should be \(RedisString("two")). It was \(resultList?[1])")

                    XCTAssertEqual(resultList?[2], RedisString("three"), "The first element of the list should be \(RedisString("three")). It was \(resultList?[2])")

                    XCTAssertEqual(resultList?.count, 3, "The size of the list should be 3. It was \(resultList?.count)")
                    expectation1.fulfill()
                })

            }
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }

    func test_ZCard() {
        let expectation1 = expectation(description: "Returns the sorted set cardinality of the sorted set ")
        setupTests {
            redis.zadd(self.key1, tuples: (1, "one"), (2, "two"), (3, "three")) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in

                XCTAssertNil(error)
                XCTAssertNotNil(retrievedTotalElementAdded)
                XCTAssertEqual(retrievedTotalElementAdded, 3)

                redis.zcard(self.key1, callback: {
                    (retrievedTotalElements: Int?, zCardError: NSError?) in

                    XCTAssertNil(zCardError)
                    XCTAssertEqual(retrievedTotalElements, 3, "The cardinality of the sorted set should be 3. It was \(retrievedTotalElements)")
                    expectation1.fulfill()
                })
            }
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }

    func test_ZCount() {
        let expectation1 = expectation(description: "Counts the number of members in the set")
        setupTests {
            redis.zadd(self.key1, tuples: (1, "one"), (2, "two"), (3, "three")) {
                (totalElementAdd: Int?, error: NSError?) in

                XCTAssertNil(error)
                XCTAssertNotNil(totalElementAdd)
                XCTAssertEqual(totalElementAdd, 3)

                redis.zcount(self.key1, min: "-inf", max: "+inf", callback: {
                    (totalElements: Int?, error: NSError?) in

                    XCTAssertNil(error)
                    XCTAssertNotNil(totalElements)
                    XCTAssertEqual(totalElements, 3, "The number of items should be 3, there were \(totalElements)")

                    expectation1.fulfill()
                })
            }
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }

    func test_ZIncrby() {
        let expectation1 = expectation(description: "Increment the score of a member")
        setupTests {
            redis.zadd(self.key1, tuples: (1, "one"), (2, "two"), (3, "three")) {
                (totalElementAdd: Int?, error: NSError?) in

                XCTAssertNil(error)
                XCTAssertNotNil(totalElementAdd)
                XCTAssertEqual(totalElementAdd, 3)

                redis.zincrby(self.key1, increment: 3, member: "one", callback: {
                    (newScore: RedisString?, error: NSError?) in

                    XCTAssertNil(error)
                    XCTAssertNotNil(newScore)
                    XCTAssertEqual(newScore, RedisString("4"), "New score should be 3 but is \(newScore)")

                    expectation1.fulfill()
                })
            }
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }

    //TODO: add options
    func test_ZInterstore() {
        let expectation1 = expectation(description: "Intersect and store sets")
        setupTests {
            redis.zadd(self.key1, tuples: (1, "one"), (2, "two"), (3, "three")) {
                (totalElementAdd: Int?, error: NSError?) in

                XCTAssertNil(error)
                XCTAssertNotNil(totalElementAdd)
                XCTAssertEqual(totalElementAdd, 3)

                redis.zadd(self.key2, tuples: (1, "one"), (2, "two")) {
                    (totalElementAdd: Int?, error: NSError?) in

                    XCTAssertNil(error)
                    XCTAssertNotNil(totalElementAdd)
                    XCTAssertEqual(totalElementAdd, 2)

                    redis.zinterstore("test3", numkeys: 2, keys: self.key1, self.key2, callback: {
                        (totalStored: Int?, error: NSError?) in

                        XCTAssertNil(error)
                        XCTAssertNotNil(totalStored)
                        XCTAssertEqual(totalStored, 2)

                        expectation1.fulfill()
                    })
                }
            }
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }

    func test_ZLexcount() {
        let expectation1 = expectation(description: "Counts the number of members in the set")
        setupTests {
            redis.zadd(self.key1, tuples: (1, "one"), (2, "two"), (3, "three")) {
                (totalElementAdd: Int?, error: NSError?) in

                XCTAssertNil(error)
                XCTAssertNotNil(totalElementAdd)
                XCTAssertEqual(totalElementAdd, 3)

                redis.zlexcount(self.key1, min: "-", max: "+", callback: {
                    (totalLexCount: Int?, error: NSError?) in

                    XCTAssertNil(error)
                    XCTAssertNotNil(totalLexCount)
                    XCTAssertEqual(totalLexCount, 3)

                    expectation1.fulfill()
                })
            }
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }

    func test_ZRange() {
        let expectation1 = expectation(description: "Returns the specified range of elements from the sorted set")
        setupTests {
            redis.zadd(self.key1, tuples: (1, "one"), (2, "two"), (3, "three")) {
                (totalElementAdd: Int?, error: NSError?) in

                XCTAssertNil(error)
                XCTAssertNotNil(totalElementAdd)
                XCTAssertEqual(totalElementAdd, 3)

                redis.zrange(self.key1, start: 2, stop: 3, callback: {
                    (resultList: [RedisString?]?, zRangeError: NSError?) in

                    XCTAssertNil(zRangeError)
                    XCTAssertEqual(resultList?.count, 1, "The number of element(s) return from the specific range should be 1. It was \(resultList?.count)")
                    expectation1.fulfill()

                })
            }
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }

    func test_ZRangebylex() {
        let expectation1 = expectation(description: "Returns the specified lexicographical range of elements from the sorted set ")
        setupTests {
            redis.zadd(self.key1, tuples: (0, "a"), (0, "b"), (0, "c"), (0, "d"), (0, "e"), (0, "f"), (0, "g")) {
                (totalElementAdd: Int?, error: NSError?) in

                XCTAssertNil(error)
                XCTAssertNotNil(totalElementAdd)
                XCTAssertEqual(totalElementAdd, 7)

                redis.zrangebylex(self.key1, min: "-", max: "[c", callback: {
                    (resultList: [RedisString?]?, error: NSError?) in

                    let expectedList = [RedisString("a"), RedisString("b"), RedisString("c")]

                    XCTAssertNil(error)
                    XCTAssertNotNil(resultList)

                    if let resultList = resultList {
                        if resultList.count == 3 {
                            XCTAssertEqual(resultList[0], expectedList[0])
                            XCTAssertEqual(resultList[1], expectedList[1])
                            XCTAssertEqual(resultList[2], expectedList[2])
                        } else {
                            XCTFail("Not enough results, there were \(resultList.count)")
                        }
                    }

                    redis.zrangebylex(self.key1, min: "-", max: "(c", callback: {
                        (resultList: [RedisString?]?, error: NSError?) in

                        let expectedList = [RedisString("a"), RedisString("b"), RedisString("c")]

                        XCTAssertNil(error)
                        XCTAssertNotNil(resultList)

                        if let resultList = resultList {
                            if resultList.count == 2 {
                                XCTAssertEqual(resultList[0], expectedList[0])
                                XCTAssertEqual(resultList[1], expectedList[1])
                            } else {
                                XCTFail("Not enough results, there were \(resultList.count)")
                            }
                        }

                        redis.zrangebylex(self.key1, min: "[aaa", max: "(g", callback: {
                            (resultList: [RedisString?]?, error: NSError?) in

                            let expectedList = [RedisString("b"), RedisString("c"), RedisString("d"), RedisString("e"), RedisString("f")]

                            XCTAssertNil(error)
                            XCTAssertNotNil(resultList)

                            if let resultList = resultList {
                                if resultList.count == 5 {
                                    XCTAssertEqual(resultList[0], expectedList[0])
                                    XCTAssertEqual(resultList[1], expectedList[1])
                                    XCTAssertEqual(resultList[2], expectedList[2])
                                    XCTAssertEqual(resultList[3], expectedList[3])
                                    XCTAssertEqual(resultList[4], expectedList[4])
                                } else {
                                    XCTFail("Not enough results, there were \(resultList.count)")
                                }
                            }

                            expectation1.fulfill()
                        })
                    })
                })
            }
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }

    func test_ZRank() {
        let expectation1 = expectation(description: "Returns the index of the member specified")
        setupTests {
            redis.zadd(self.key1, tuples: (1, "one"), (2, "two"), (3, "three")) {
                (totalElementAdd: Int?, error: NSError?) in

                XCTAssertNil(error)
                XCTAssertNotNil(totalElementAdd)
                XCTAssertEqual(totalElementAdd, 3)

                redis.zrank(self.key1, member: "three", callback: {
                    (memberRank: Int?, error: NSError?) in

                    XCTAssertNil(error)
                    XCTAssertNotNil(memberRank)
                    XCTAssertEqual(memberRank, 2, "The rank should be 2, it was \(memberRank)")

                    redis.zrank(self.key1, member: "four", callback: {
                        (memberRank: Int?, error: NSError?) in

                        XCTAssertNil(error)
                        XCTAssertNil(memberRank)

                        expectation1.fulfill()
                    })
                })
            }
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }

    func test_ZRem() {
        let expectation1 = expectation(description: "Removes the specified members from the set")
        setupTests {
            redis.zadd(self.key1, tuples: (1, "one"), (2, "two"), (3, "three")) {
                (totalElementAdd: Int?, error: NSError?) in

                XCTAssertNil(error)
                XCTAssertNotNil(totalElementAdd)
                XCTAssertEqual(totalElementAdd, 3)

                redis.zrem(self.key1, members: "two", "three", callback: {
                    (totalElementRem: Int?, zRemError: NSError?) in

                    XCTAssertNil(zRemError)
                    XCTAssertEqual(totalElementRem, 2, "The number of items deleted in the set should be 2. It was \(totalElementRem)")
                    expectation1.fulfill()
                })
            }
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }

    func test_ZRemrangebylex() {
        let expectation1 = expectation(description: "Removes all members in the set between the given lexicographical range")
        setupTests {
            redis.zadd(self.key1, tuples: (0, "a"), (0, "b"), (0, "c"), (0, "d"), (0, "e")) {
                (totalElementAdd: Int?, error: NSError?) in

                XCTAssertNil(error)
                XCTAssertNotNil(totalElementAdd)
                XCTAssertEqual(totalElementAdd, 5)

                redis.zadd(self.key1, tuples: (0, "foo"), (0, "zap"), (0, "zip"), (0, "ALPHA"), (0, "alpha")) {
                    (totalElementAdd: Int?, error: NSError?) in

                    XCTAssertNil(error)
                    XCTAssertNotNil(totalElementAdd)
                    XCTAssertEqual(totalElementAdd, 5)

                    redis.zremrangebylex(self.key1, min: "[alpha", max: "[omega", callback: {
                        (totalRemoved: Int?, error: NSError?) in

                        XCTAssertNil(error)
                        XCTAssertNotNil(totalRemoved)
                        XCTAssertEqual(totalRemoved, 6)

                        expectation1.fulfill()
                    })
                }
            }
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }

    func test_ZRemrangebyrank() {
        let expectation1 = expectation(description: "Removes all members in the set between the given indexes")
        setupTests {
            redis.zadd(self.key1, tuples: (1, "one"), (2, "two"), (3, "three")) {
                (totalElementAdd: Int?, error: NSError?) in

                XCTAssertNil(error)
                XCTAssertNotNil(totalElementAdd)
                XCTAssertEqual(totalElementAdd, 3)

                redis.zremrangebyrank(self.key1, start: 0, stop: 1, callback: {
                    (totalRemoved: Int?, error: NSError?) in

                    XCTAssertNil(error)
                    XCTAssertNotNil(totalRemoved)
                    XCTAssertEqual(totalRemoved, 2)

                    expectation1.fulfill()
                })
            }
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }

    func test_ZRemrangebyscore() {
        let expectation1 = expectation(description: "Remove all members in the set between the given scores")
        setupTests {
            redis.zadd(self.key1, tuples: (1, "one"), (2, "two"), (3, "three")) {
                (totalElementAdd: Int?, error: NSError?) in

                XCTAssertNil(error)
                XCTAssertNotNil(totalElementAdd)
                XCTAssertEqual(totalElementAdd, 3)

                redis.zremrangebyscore(self.key1, min: "-inf", max: "(2", callback: {
                    (totalRemoved: Int?, error: NSError?) in

                    XCTAssertNil(error)
                    XCTAssertNotNil(totalRemoved)
                    XCTAssertEqual(totalRemoved, 1)

                    expectation1.fulfill()
                })
            }
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }

    func test_ZRevrange() {
        let expectation1 = expectation(description: "Returns the range of members, by index, from high to low")
        let expectedResults = [RedisString("one"), RedisString("two"), RedisString("three")]
        setupTests {
            redis.zadd(self.key1, tuples: (1, "one"), (2, "two"), (3, "three")) {
                (totalElementAdd: Int?, error: NSError?) in

                XCTAssertNil(error)
                XCTAssertNotNil(totalElementAdd)
                XCTAssertEqual(totalElementAdd, 3)

                redis.zrevrange(self.key1, start: 0, stop: -1, callback: {
                    (reversedList: [RedisString?]?, error: NSError?) in

                    XCTAssertNil(error)
                    XCTAssertNotNil(reversedList)
                    if let reversedList = reversedList {
                        if reversedList.count == 3 {
                            XCTAssertEqual(reversedList[0], expectedResults[2])
                            XCTAssertEqual(reversedList[1], expectedResults[1])
                            XCTAssertEqual(reversedList[2], expectedResults[0])
                        }
                    }

                    expectation1.fulfill()
                })
            }
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }

    func test_ZRevrangebylex() {
        let expectation1 = expectation(description: "Returns the range of members, by lexicographical range, ordered from higher to lower strings")
        let expectedResult = [RedisString("a"), RedisString("b"), RedisString("c"), RedisString("d"), RedisString("e"), RedisString("f"), RedisString("g")]
        setupTests {
            redis.zadd(self.key1, tuples: (0, "a"), (0, "b"), (0, "c"), (0, "d"), (0, "e"), (0, "f"), (0, "g")) {
                (totalElementAdd: Int?, error: NSError?) in

                XCTAssertNil(error)
                XCTAssertNotNil(totalElementAdd)
                XCTAssertEqual(totalElementAdd, 7)

                redis.zrevrangebylex(self.key1, min: "[c", max: "-", callback: {
                    (resultList: [RedisString?]?, error: NSError?) in

                    XCTAssertNil(error)
                    XCTAssertNotNil(resultList)
                    if let resultList = resultList {
                        if resultList.count == 3 {
                            XCTAssertEqual(resultList[0], expectedResult[2])
                            XCTAssertEqual(resultList[1], expectedResult[1])
                            XCTAssertEqual(resultList[2], expectedResult[0])
                        }
                    }

                    redis.zrevrangebylex(self.key1, min: "(c", max: "-", callback: {
                        (resultList: [RedisString?]?, error: NSError?) in

                        XCTAssertNil(error)
                        XCTAssertNotNil(resultList)
                        if let resultList = resultList {
                            if resultList.count == 2 {
                                XCTAssertEqual(resultList[0], expectedResult[1])
                                XCTAssertEqual(resultList[1], expectedResult[0])
                            }
                        }

                        redis.zrevrangebylex(self.key1, min: "(g", max: "[aaa", callback: {
                            (resultList: [RedisString?]?, error: NSError?) in

                            XCTAssertNil(error)
                            XCTAssertNotNil(resultList)
                            if let resultList = resultList {
                                if resultList.count == 5 {
                                    XCTAssertEqual(resultList[0], expectedResult[5])
                                    XCTAssertEqual(resultList[1], expectedResult[4])
                                    XCTAssertEqual(resultList[2], expectedResult[3])
                                    XCTAssertEqual(resultList[3], expectedResult[2])
                                    XCTAssertEqual(resultList[4], expectedResult[1])
                                }
                            }
                            expectation1.fulfill()
                        })
                    })
                })
            }
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }

    func test_ZRevrangebyscore() {
        let expectation1 = expectation(description: "Returns the range of members, by score, from high to low")
        let expectedResult = [RedisString("one"), RedisString("two"), RedisString("three")]
        setupTests {
            redis.zadd(self.key1, tuples: (1, "one"), (2, "two"), (3, "three")) {
                (totalElementAdd: Int?, error: NSError?) in

                XCTAssertNil(error)
                XCTAssertNotNil(totalElementAdd)
                XCTAssertEqual(totalElementAdd, 3)

                redis.zrevrangebyscore(self.key1, min: "+inf", max: "-inf", callback: {
                    (resultList: [RedisString?]?, error: NSError?) in

                    XCTAssertNil(error)
                    XCTAssertNotNil(resultList)
                    if let resultList = resultList {
                        if resultList.count == 3 {
                            XCTAssertEqual(resultList[0], expectedResult[2])
                            XCTAssertEqual(resultList[1], expectedResult[1])
                            XCTAssertEqual(resultList[2], expectedResult[0])
                        }
                    }

                    expectation1.fulfill()
                })
            }
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }

    func test_ZRevrank() {
        let expectation1 = expectation(description: "Get the score of a member where scores are sorted from high to low")
        setupTests {
            redis.zadd(self.key1, tuples: (1, "one"), (2, "two"), (3, "three")) {
                (totalElementAdd: Int?, error: NSError?) in

                XCTAssertNil(error)
                XCTAssertNotNil(totalElementAdd)
                XCTAssertEqual(totalElementAdd, 3)

                redis.zrevrank(self.key1, member: "one", callback: {
                    (memberScore: Int?, error: NSError?) in

                    XCTAssertNil(error)
                    XCTAssertNotNil(memberScore)
                    XCTAssertEqual(memberScore, 2)

                    redis.zrevrank(self.key1, member: "four", callback: {
                        (memberScore: Int?, error: NSError?) in

                        XCTAssertNil(error)
                        XCTAssertNil(memberScore)

                        expectation1.fulfill()
                    })
                })
            }
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }

    func test_ZScore() {
        let expectation1 = expectation(description: "Get the score of a member")
        setupTests {
            redis.zadd(self.key1, tuples: (1, "one")) {
                (totalElementAdd: Int?, error: NSError?) in

                XCTAssertNil(error)
                XCTAssertNotNil(totalElementAdd)
                XCTAssertEqual(totalElementAdd, 1)

                redis.zscore(self.key1, member: "one", callback: {
                    (memberScore: RedisString?, error: NSError?) in

                    XCTAssertNil(error)
                    XCTAssertNotNil(memberScore)
                    XCTAssertEqual(memberScore, RedisString("1"))

                    expectation1.fulfill()
                })
            }
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }

    func test_ZUnionstore() {
        let expectation1 = expectation(description: "Store the result of a union in a set")
        setupTests {
            redis.zadd(self.key1, tuples: (1, "one"), (2, "two")) {
                (totalElementAdd: Int?, error: NSError?) in

                XCTAssertNil(error)
                XCTAssertNotNil(totalElementAdd)
                XCTAssertEqual(totalElementAdd, 2)

                redis.zadd(self.key2, tuples: (1, "one"), (2, "two"), (3, "three")) {
                    (totalElementAdd: Int?, error: NSError?) in

                    XCTAssertNil(error)
                    XCTAssertNotNil(totalElementAdd)
                    XCTAssertEqual(totalElementAdd, 3)

                    redis.zunionstore("out", numkeys: 2, keys: self.key1, self.key2, callback: {
                        (totalElementsUnion: Int?, error: NSError?) in

                        XCTAssertNil(error)
                        XCTAssertNotNil(totalElementsUnion)
                        XCTAssertEqual(totalElementsUnion, 3)

                        expectation1.fulfill()
                    })
                }
            }
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }

    func test_flushDB() {
        let expectation1 = expectation(description: "Delete all the keys of the currently selected DB")
        setupTests {
            redis.zadd(self.key1, tuples: (1, "one"), (2, "two")) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in

                XCTAssertNil(error)
                XCTAssertNotNil(retrievedTotalElementAdded)
                XCTAssertEqual(retrievedTotalElementAdded, 2)

            }
            redis.flushdb() {
                (result: Bool?, flushError: NSError?) in

                XCTAssertNotNil(result)
                XCTAssertTrue(result!)
                XCTAssertNil(flushError)


                redis.zcard(self.key1, callback: {
                    (retrievedTotalElements: Int?, zCardError: NSError?) in

                    XCTAssertNil(zCardError)
                    XCTAssertEqual(retrievedTotalElements, 0, "The cardinality of the sorted set should be 0. It was \(retrievedTotalElements)")
                })
            }
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }


}
