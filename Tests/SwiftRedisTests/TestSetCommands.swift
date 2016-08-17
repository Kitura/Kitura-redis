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
    static var allTests : [(String, (TestSetCommands) -> () throws -> Void)] {
        return [
            ("test_ZAdd", test_ZAdd),
            ("test_ZRem", test_ZRem),
            ("test_ZRemrangebyscore", test_ZRemrangebyscore),
            ("test_ZRange", test_ZRange),
            ("test_ZCard",test_ZCard),
            ("test_flushDB", test_flushDB)
        ]
    }
    
    
    let key1 = "test1"
    
    func setupTests(callback: () -> Void) {
        connectRedis() {(error: NSError?) in
            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
            
            redis.del(self.key1) {(deleted: Int?, error: NSError?) in
                callback()
            }
        }
    }
    
    func test_ZAdd() {
        let expectation1 = expectation(description: "Add score(s) and member(s) to the set")
        
        setupTests {
            redis.zadd(self.key1, tuples: (1,"one"), (2,"two"), (3, "three")) {
                (result: Int?, error: NSError?) in
                
                XCTAssertNil(error)
                XCTAssertNotNil(result)
                
                redis.zrange(self.key1, start: 0, stop: 2, callback: {
                    (resultList:[RedisString?]?, zRangeError: NSError?) in
                    
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
    
    func test_ZRem() {
        let expectation1 = expectation(description: "Removes the specified members fromt the set")
        setupTests {
            redis.zadd(self.key1, tuples: (1,"one"), (2,"two"), (3, "three")) {
                (totalElementAdd: Int?, error: NSError?) in
                
                XCTAssertNil(error)
                XCTAssertNotNil(totalElementAdd)
                XCTAssertEqual(totalElementAdd, 3)
        
                redis.zrem(self.key1,  members: "two", "three", callback: {
                    (totalElementRem: Int?, zRemError: NSError?) in
                    
                    XCTAssertNil(zRemError)
                    XCTAssertEqual(totalElementRem, 2, "The number of items deleted in the set should be 2. It was \(totalElementRem)")
                    expectation1.fulfill()
                })
            }
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }
    
    
    func test_ZRemrangebyscore() {
        let expectation1 = expectation(description: "Removes all elements from the sorted set")
        setupTests {
            redis.zadd(self.key1, tuples: (1,"one"), (2,"two"), (3, "three")) {
                (totalElementAdd: Int?, error: NSError?) in
                
                XCTAssertNil(error)
                XCTAssertNotNil(totalElementAdd)
                XCTAssertEqual(totalElementAdd, 3)
                
                redis.zremrangebyscore(self.key1, min: "-inf", max: "(2", callback: {
                    (numberElementRem:Int?, ZRemRangeByScoreError: NSError?) in
                    
                    XCTAssertNil(ZRemRangeByScoreError)
                    XCTAssertEqual(numberElementRem, 1, "The number of elements removed from the set should be 1. It was \(numberElementRem)")
                    expectation1.fulfill()
                })
            }
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_ZRange() {
        let expectation1 = expectation(description: "Returns the specified range of elements from the sorted set")
        setupTests {
            redis.zadd(self.key1, tuples: (1,"one"), (2,"two"), (3, "three")) {
                (totalElementAdd: Int?, error: NSError?) in
                
                XCTAssertNil(error)
                XCTAssertNotNil(totalElementAdd)
                XCTAssertEqual(totalElementAdd, 3)
                
                redis.zrange(self.key1, start: 2, stop: 3, callback: {
                    (resultList:[RedisString?]?, zRangeError: NSError?) in
                    
                    XCTAssertNil(zRangeError)
                    XCTAssertEqual(resultList?.count, 1, "The number of element(s) return from the specific range should be 1. It was \(resultList?.count)")
                    expectation1.fulfill()
                    
                })
            }
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_ZCard() {
        let expectation1 = expectation(description: "Returns the sorted set cardinality of the sorted set ")
        setupTests {
            redis.zadd(self.key1, tuples: (1,"one"), (2,"two"), (3, "three")) {
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
    
    func test_flushDB() {
        let expectation1 = expectation(description: "Delete all the keys of the currently selected DB")
        setupTests {
            redis.zadd(self.key1, tuples: (1,"one"), (2,"two")) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                
                XCTAssertNil(error)
                XCTAssertNotNil(retrievedTotalElementAdded)
                XCTAssertEqual(retrievedTotalElementAdded, 2)
                
            }
            redis.flushdb(){
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
