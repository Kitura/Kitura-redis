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

public class TestSetCommandsPart2: XCTestCase {
    static var allTests : [(String, (TestSetCommandsPart2) -> () throws -> Void)] {
        return [
            ("test_sadd", test_sadd),
            ("test_sadd_redis", test_sadd_redis),
            ("test_scard", test_scard),
            ("test_scard_redis", test_scard_redis),
            ("test_sdiff", test_sdiff),
            ("test_sdiff_redis", test_sdiff_redis),
            ("test_smebers", test_smembers),
            ("test_smebers_redis", test_smembers_redis),
            ("test_sdiffstore", test_sdiffstore),
            ("test_sdiffstore_redis", test_sdiffstore_redis),
            ("test_sinter", test_sinter),
            ("test_sinter_redis", test_sinter_redis),
            ("test_sinterstore", test_sinterstore),
            ("test_sinterstore_redis", test_sinterstore_redis),
            ("test_sismember", test_sismember),
            ("test_sismember_redis", test_sismember_redis),
            ("test_smove", test_smove),
            ("test_smove_redis", test_smove_redis),
            ("test_spop", test_spop),
            ("test_spop_redis", test_spop_redis),
            ("test_srandmember", test_srandmember),
            ("test_srandmember_redis", test_srandmember_redis),
            ("test_srem", test_srem),
            ("test_srem_redis", test_srem_redis),
            ("test_sunion", test_sunion),
            ("test_sunion_redis", test_sunion_redis),
            ("test_sscan", test_sscan),
            ("test_sscan_redis", test_sscan_redis),
        ]
    }
    
    let key1 = "key1"
    let key2 = "key2"
    let key3 = "key3"
    let key4 = "key4"
    let redisKey1 = RedisString("rediskey1")
    let redisKey2 = RedisString("rediskey2")
    let redisKey3 = RedisString("rediskey3")
    let redisKey4 = RedisString("rediskey4")
    
    let member1 = "its over 9000"
    let member2 = "What up doc?"
    let member3 = "insert reference here"
    let member4 = "insert test string here"
    let redismember1 = RedisString("redis is over 9000")
    let redismember2 = RedisString("What up doc? Just redis")
    let redismember3 = RedisString("insert reference with redis here")
    let redismember4 = RedisString("insert redisstring here")
    
    let redisVersions = ["2.6", "2.8", "3.0"]
    
    func setupTests(callback: () -> Void) {
        connectRedis() {(error: NSError?) in
            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
            
            redis.del(self.key1, self.key2, self.key3, self.key4) {(deleted: Int?, error: NSError?) in
                callback()
            }
        }
    }
    
    func setupRedisTests(callback: () -> Void) {
        connectRedis() {(error: NSError?) in
            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
            
            redis.del(self.redisKey1, self.redisKey2, self.redisKey3, self.redisKey4) {(deleted: Int?, error: NSError?) in
                callback()
            }
        }
    }
    
    func test_sadd() {
        let expectation1 = expectation(description: "Add the specified members to the set stored at key")
        setupTests {
            
            redis.sadd(self.key1, members: self.member1, self.member2, self.member3) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                
                XCTAssertNil(error)
                XCTAssertNotNil(retrievedTotalElementAdded)
                XCTAssertEqual(retrievedTotalElementAdded, 3)
                
                    redis.sadd(self.key1, members: self.member1, self.member4) {
                    (retrievedTotalElementAdded: Int?, error: NSError?) in
                    
                    XCTAssertNil(error)
                    XCTAssertNotNil(retrievedTotalElementAdded)
                    XCTAssertEqual(retrievedTotalElementAdded, 1)
                    
                    expectation1.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_sadd_redis() {
        let expectation1 = expectation(description: "Add the specified members to the set stored at key")
        setupRedisTests {
            redis.sadd(self.redisKey1, members: self.redismember1, self.redismember2, self.redismember3) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                
                XCTAssertNil(error)
                XCTAssertNotNil(retrievedTotalElementAdded)
                XCTAssertEqual(retrievedTotalElementAdded, 3)
                
                    redis.sadd(self.redisKey1, members: self.redismember1, self.redismember4) {
                    (retrievedTotalElementAdded: Int?, error: NSError?) in
                    
                    XCTAssertNil(error)
                    XCTAssertNotNil(retrievedTotalElementAdded)
                    XCTAssertEqual(retrievedTotalElementAdded, 1)
                    
                    expectation1.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_scard() {
        let expectation1 = expectation(description: "Returns the set cardinality of the set stored at key")
        setupTests {
            
            redis.sadd(self.key1, members: self.member1, self.member2, self.member3) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                
                XCTAssertNil(error)
                XCTAssertNotNil(retrievedTotalElementAdded)
                XCTAssertEqual(retrievedTotalElementAdded, 3)
                
                    redis.scard(self.key1) {
                    (retrievedTotalElementAdded: Int?, error: NSError?) in
                    
                    XCTAssertNil(error)
                    XCTAssertNotNil(retrievedTotalElementAdded)
                    XCTAssertEqual(retrievedTotalElementAdded, 3)
                    
                    expectation1.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_scard_redis() {
        let expectation1 = expectation(description: "Returns the set cardinality of the set stored at key")
        setupRedisTests {
            
            redis.sadd(self.redisKey1, members: self.redismember1, self.redismember2, self.redismember3) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                
                XCTAssertNil(error)
                XCTAssertNotNil(retrievedTotalElementAdded)
                XCTAssertEqual(retrievedTotalElementAdded, 3)
                
                    redis.scard(self.redisKey1) {
                    (retrievedTotalElementAdded: Int?, error: NSError?) in
                    
                    XCTAssertNil(error)
                    XCTAssertNotNil(retrievedTotalElementAdded)
                    XCTAssertEqual(retrievedTotalElementAdded, 3)
                    
                    expectation1.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_sdiff() {
        let expectation1 = expectation(description: "Returns the members of the set resulting from the difference between the first set and all the successive sets.")
        
        setupTests {
            redis.sadd(self.key1, members: self.member1, self.member2, self.member3, self.member4) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                
                XCTAssertNil(error)
                XCTAssertNotNil(retrievedTotalElementAdded)
                XCTAssertEqual(retrievedTotalElementAdded, 4)
                
                    redis.sadd(self.key2, members: self.member1, self.member4) {
                    (retrievedTotalElementAdded: Int?, error: NSError?) in
                    
                    XCTAssertNil(error)
                    XCTAssertNotNil(retrievedTotalElementAdded)
                    XCTAssertEqual(retrievedTotalElementAdded, 2)
                    
                        redis.sdiff(keys: self.key1, self.key2) {
                        (retrievedArrayMembers: [RedisString?]?, error: NSError?) in
                        
                        XCTAssertNil(error)
                        XCTAssertNotNil(retrievedArrayMembers)
                        XCTAssertEqual(retrievedArrayMembers!.count, 2)
                        
                        expectation1.fulfill()
                    }
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_sdiff_redis() {
        let expectation1 = expectation(description: "Returns the members of the set resulting from the difference between the first set and all the successive sets.")
        
        setupRedisTests {
            
            redis.sadd(self.redisKey1, members: self.redismember1, self.redismember2, self.redismember3, self.redismember4) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                
                XCTAssertNil(error)
                XCTAssertNotNil(retrievedTotalElementAdded)
                XCTAssertEqual(retrievedTotalElementAdded, 4)
                
                    redis.sadd(self.redisKey2, members: self.redismember1, self.redismember4) {
                    (retrievedTotalElementAdded: Int?, error: NSError?) in
                    
                    XCTAssertNil(error)
                    XCTAssertNotNil(retrievedTotalElementAdded)
                    XCTAssertEqual(retrievedTotalElementAdded, 2)
                    
                        redis.sdiff(keys: self.redisKey1, self.redisKey2) {
                        (retrievedArrayMembers: [RedisString?]?, error: NSError?) in
                        
                        XCTAssertNil(error)
                        XCTAssertNotNil(retrievedArrayMembers)
                        XCTAssertEqual(retrievedArrayMembers!.count, 2)
                        
                        expectation1.fulfill()
                    }
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_smembers() {
        let expectation1 = expectation(description: "Returns all the members of the set value stored at a key.")
        setupTests {
            redis.sadd(self.key1, members: self.member1, self.member2) {
                (retrievedTotalElementsAdded: Int?, error: NSError?) in
                
                XCTAssertNil(error)
                
                    redis.smembers(self.key1) {
                    (retrievedMembers: [RedisString?]?, error: NSError?) in
                    
                    XCTAssertNil(error)
                    XCTAssertNotNil(retrievedMembers)
                    
                    redis.scard(self.key1) {
                        (retrievedTotalCount: Int?, error: NSError?) in
                        
                        XCTAssertEqual(retrievedTotalCount, 2)
                        
                        expectation1.fulfill()
                    }
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_smembers_redis() {
        let expectation1 = expectation(description: "Returns all the members of the set value stored at a key.")
        setupRedisTests {
            
            redis.sadd(self.redisKey1, members: self.redismember1, self.redismember2) {
                (retrievedTotalElementsAdded: Int?, error: NSError?) in
                
                XCTAssertNil(error)
                
                    redis.smembers(self.redisKey1) {
                    (retrievedMembers: [RedisString?]?, error: NSError?) in
                    
                    XCTAssertNil(error)
                    XCTAssertNotNil(retrievedMembers)
                    
                    redis.scard(self.redisKey1) {
                        (retrievedTotalCount: Int?, error: NSError?) in
                        
                        XCTAssertEqual(retrievedTotalCount, 2)
                        
                        expectation1.fulfill()
                    }
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_sdiffstore() {
        let expectation1 = expectation(description: "Stores the members of the set resulting from the difference between the first set and all the successive sets in a specified set.")

        setupTests {
            redis.sadd(self.key1, members: self.member1, self.member2, self.member3, self.member4) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                
                XCTAssertNil(error)
                
                    redis.sadd(self.key2, members: self.member1, self.member4) {
                    (retrievedTotalElementAdded: Int?, error: NSError?) in
                    
                    XCTAssertNil(error)
                    
                        redis.smembers(self.key2) {
                        (retrievedMembers: [RedisString?]?, error: NSError?) in
                        XCTAssertNil(error)
                        
                            redis.sdiffstore(destination: self.key3, keys: self.key1, self.key2) {
                            (retrievedTotalElementAdded: Int?, error: NSError?) in
                            
                            XCTAssertNil(error)
                            XCTAssertNotNil(retrievedTotalElementAdded)
                            XCTAssertEqual(retrievedTotalElementAdded!, 2)
                            
                            expectation1.fulfill()
                        }
                    }
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_sdiffstore_redis() {
        let expectation1 = expectation(description: "Stores the members of the set resulting from the difference between the first set and all the successive sets in a specified set.")
        
        setupRedisTests {
            
            redis.sadd(self.redisKey1, members: self.redismember1, self.redismember2, self.redismember3, self.redismember4) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                
                XCTAssertNil(error)
                
                    redis.sadd(self.redisKey2, members: self.redismember1, self.redismember4) {
                    (retrievedTotalElementAdded: Int?, error: NSError?) in
                    
                    XCTAssertNil(error)
                    
                        redis.smembers(self.redisKey2) {
                        (retrievedMembers: [RedisString?]?, error: NSError?) in
                        XCTAssertNil(error)
                        
                            redis.sdiffstore(destination: self.redisKey3, keys: self.redisKey1, self.redisKey2) {
                            (retrievedTotalElementAdded: Int?, error: NSError?) in
                            
                            XCTAssertNil(error)
                            XCTAssertNotNil(retrievedTotalElementAdded)
                            XCTAssertEqual(retrievedTotalElementAdded!, 2)
                            
                            expectation1.fulfill()
                        }
                    }
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_sinter() {
        let expectation1 = expectation(description: "Returns the members of the set resulting from the intersection of all the given sets.")
        setupTests {
            redis.sadd(self.key1, members: self.member1, self.member2, self.member3 ) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                
                XCTAssertNil(error)
                
                    redis.sadd(self.key2, members: self.member3, self.member4) {
                    (retrievedTotalElementAdded: Int?, error: NSError?) in
                    
                    XCTAssertNil(error)
                    
                        redis.sinter(self.key1, self.key2) {
                        (retrievedMembers: [RedisString?]?, error: NSError?) in
                        
                        XCTAssertNil(error)
                        XCTAssertNotNil(retrievedMembers)
                        XCTAssertEqual(retrievedMembers!.count, 1)
                        
                        expectation1.fulfill()
                    }
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_sinter_redis() {
        let expectation1 = expectation(description: "Returns the members of the set resulting from the intersection of all the given sets.")
        setupRedisTests {
            
            redis.sadd(self.redisKey1, members: self.redismember1, self.redismember2, self.redismember3 ) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                
                XCTAssertNil(error)
                
                    redis.sadd(self.redisKey2, members: self.redismember3, self.redismember4) {
                    (retrievedTotalElementAdded: Int?, error: NSError?) in
                    
                    XCTAssertNil(error)
                    
                        redis.sinter(self.redisKey1, self.redisKey2) {
                        (retrievedMembers: [RedisString?]?, error: NSError?) in
                        
                        XCTAssertNil(error)
                        XCTAssertNotNil(retrievedMembers)
                        XCTAssertEqual(retrievedMembers!.count, 1)
                        
                        
                        expectation1.fulfill()
                    }
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_sinterstore() {
        let expectation1 = expectation(description: "Stores the members of the set resulting from the intersection of all the given sets in another set.")
        setupTests {
            redis.sadd(self.key1, members: self.member1, self.member2, self.member3) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                XCTAssertNil(error)
                XCTAssertEqual(retrievedTotalElementAdded, 3)
                
                    redis.sadd(self.key2, members: self.member3, self.member4) {
                    (retrievedTotalElementAdded: Int?, error: NSError?) in
                    XCTAssertNil(error)
                    XCTAssertEqual(retrievedTotalElementAdded, 2)
                    
                        redis.sinterstore(self.key3, keys: self.key1, self.key2) {
                        (retrievedTotalMembers: Int?, error: NSError?) in
                        
                        XCTAssertNil(error)
                        XCTAssertNotNil(retrievedTotalMembers)
                        XCTAssertEqual(retrievedTotalMembers, 1)
                        
                        redis.scard(self.key3) {
                            (retrievedTotalElements: Int?, error: NSError?) in
                            
                            XCTAssertNil(error)
                            XCTAssertEqual(retrievedTotalElements, 1, "There should only be 1 member in the set \(self.key3), there are in fact \(retrievedTotalElements!)")
                            
                            expectation1.fulfill()
                        }

                    }
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_sinterstore_redis() {
        let expectation1 = expectation(description: "Stores the members of the set resulting from the intersection of all the given sets in another set.")
        setupRedisTests {
            
            redis.sadd(self.redisKey1, members: self.redismember1, self.redismember2, self.redismember3) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                XCTAssertNil(error)
                XCTAssertEqual(retrievedTotalElementAdded, 3)
                
                    redis.sadd(self.redisKey2, members: self.redismember3, self.redismember4) {
                    (retrievedTotalElementAdded: Int?, error: NSError?) in
                    XCTAssertNil(error)
                    XCTAssertEqual(retrievedTotalElementAdded, 2)
                    
                        redis.sinterstore(self.redisKey3, keys: self.redisKey1, self.redisKey2) {
                        (retrievedTotalMembers: Int?, error: NSError?) in
                        
                        XCTAssertNil(error)
                        XCTAssertNotNil(retrievedTotalMembers)
                        XCTAssertEqual(retrievedTotalMembers, 1)
                        
                        redis.scard(self.redisKey3) {
                            (retrievedTotalElements: Int?, error: NSError?) in
                            
                            XCTAssertNil(error)
                            XCTAssertEqual(retrievedTotalElements, 1, "There should only be 1 member in the set \(self.redisKey3), there are in fact \(retrievedTotalElements!)")
                            
                            expectation1.fulfill()
                        }
                        
                    }
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_sismember() {
        let expectation1 = expectation(description: "Returns 1 member is a member of the set stored at the key, else  returns 2")
        setupTests {
            redis.sadd(self.key1, members: self.member1, self.member2) {
                (retrievedTotalElementsAdded: Int?, error: NSError?) in
                
                XCTAssertNil(error)
                
                    redis.sismember(self.key1, member: self.member1) {
                    (isMember: Bool?, error: NSError?) in
                    
                    XCTAssertNil(error)
                    XCTAssertNotNil(isMember)
                    if let isMember = isMember {
                        XCTAssertTrue(isMember, "Member '\(self.member1)' should be a member of set '\(self.key1)'")
                    }
                    
                        redis.sismember(self.key1, member: self.member3) {
                        (isMember: Bool?, error: NSError?) in
                        
                        XCTAssertNil(error)
                        XCTAssertNotNil(isMember)
                        if let isMember = isMember {
                            XCTAssertFalse(isMember, "Member '\(self.member3)' should not be a member of set '\(self.key1)'")
                        }
                        
                        expectation1.fulfill()
                    }
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_sismember_redis() {
        let expectation1 = expectation(description: "Returns 1 member is a member of the set stored at the key, else  returns 2")
        setupRedisTests {
            redis.sadd(self.redisKey1, members: self.redismember1, self.redismember2) {
                (retrievedTotalElementsAdded: Int?, error: NSError?) in
                
                XCTAssertNil(error)
                
                    redis.sismember(self.redisKey1, member: self.redismember1) {
                    (isMember: Bool?, error: NSError?) in
                    
                    XCTAssertNil(error)
                    XCTAssertNotNil(isMember)
                    if let isMember = isMember {
                        XCTAssertTrue(isMember, "Member '\(self.redismember1)' should be a member of set '\(self.redisKey1)'")
                    }
                    
                        redis.sismember(self.redisKey1, member: self.redismember3) {
                        (isMember: Bool?, error: NSError?) in
                        
                        XCTAssertNil(error)
                        XCTAssertNotNil(isMember)
                        if let isMember = isMember {
                            XCTAssertFalse(isMember, "Member '\(self.redismember3)' should not be a member of set '\(self.redisKey1)'")
                        }
                        
                        expectation1.fulfill()
                    }
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_smove() {
        let expectation1 = expectation(description: "Move memer from the set at source to the set at destination")
        setupTests {
            redis.sadd(self.key1, members: self.member1, self.member2) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                XCTAssertNil(error)
                XCTAssertEqual(retrievedTotalElementAdded, 2)
                
                    redis.sadd(self.key2, members: self.member3) {
                    (retrievedTotalElementAdded: Int?, error: NSError?) in
                    XCTAssertNil(error)
                    XCTAssertEqual(retrievedTotalElementAdded, 1)
                    
                        redis.smove(source: self.key1, destination: self.key2, member: self.member1) {
                        (hasMoved: Bool?, error: NSError?) in
                        
                        XCTAssertNil(error)
                        XCTAssertNotNil(hasMoved)
                        if let hasMoved = hasMoved {
                            XCTAssertTrue(hasMoved)
                        }
                        
                        redis.scard(self.key1) {
                            (retrievedTotalMembers: Int?, error: NSError?) in
                            XCTAssertNil(error)
                            XCTAssertEqual(retrievedTotalMembers, 1, "There should be 1 member but there are \(retrievedTotalMembers) member(s)")
                            
                                redis.scard(self.key2) {
                                (retrievedTotalMembers: Int?, error: NSError?) in
                                XCTAssertNil(error)
                                XCTAssertEqual(retrievedTotalMembers, 2, "There should be 2 members but there are \(retrievedTotalMembers) member(s)")
                                
                                expectation1.fulfill()
                            }
                        }
                    }
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_smove_redis() {
        let expectation1 = expectation(description: "Move memer from the set at source to the set at destination")
        setupRedisTests {
            
            redis.sadd(self.redisKey1, members: self.redismember1, self.redismember2) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                XCTAssertNil(error)
                XCTAssertEqual(retrievedTotalElementAdded, 2)
                
                    redis.sadd(self.redisKey2, members: self.redismember3) {
                    (retrievedTotalElementAdded: Int?, error: NSError?) in
                    XCTAssertNil(error)
                    XCTAssertEqual(retrievedTotalElementAdded, 1)
                    
                        redis.smove(source: self.redisKey1, destination: self.redisKey2, member: self.redismember1) {
                        (hasMoved: Bool?, error: NSError?) in
                        
                        XCTAssertNil(error)
                        XCTAssertNotNil(hasMoved)
                        if let hasMoved = hasMoved {
                            XCTAssertTrue(hasMoved)
                        }
                        
                        redis.scard(self.redisKey1) {
                            (retrievedTotalMembers: Int?, error: NSError?) in
                            XCTAssertNil(error)
                            XCTAssertEqual(retrievedTotalMembers, 1, "There should be 1 member but there are \(retrievedTotalMembers) member(s)")
                            
                                redis.scard(self.redisKey2) {
                                (retrievedTotalMembers: Int?, error: NSError?) in
                                XCTAssertNil(error)
                                XCTAssertEqual(retrievedTotalMembers, 2, "There should be 2 members but there are \(retrievedTotalMembers) member(s)")
                                
                                expectation1.fulfill()
                            }
                        }
                    }
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_spop() {
        let expectation1 = expectation(description: "Removes and returns one or more random elements from the set value store at key.")
        setupTests {
            redis.sadd(self.key1, members: self.member1, self.member2, self.member3) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                XCTAssertNil(error)
                XCTAssertEqual(retrievedTotalElementAdded, 3)
                
                    redis.spop(self.key1) {
                    (memberPopped: RedisString?, error: NSError?) in
                    
                    XCTAssertNil(error, "Error: \(error)")
                    XCTAssertNotNil(memberPopped)
                    
                    redis.scard(self.key1) {
                        (retrievedTotalMembers: Int?, error: NSError?) in
                        XCTAssertNil(error)
                        XCTAssertEqual(retrievedTotalMembers, 2, "There should be 2 members but there are \(retrievedTotalMembers) member(s)")
                        
                            redis.info() {
                            (info: RedisInfo?, error: NSError?) in
                            
                            if let info = info {

                                if info.server.checkVersionCompatible(major: 3, minor: 2) {
                                    redis.sadd(self.key2, members: self.member1, self.member2, self.member3) {
                                        (retrievedTotalElementAdded: Int?, error: NSError?) in
                                        XCTAssertNil(error)
                                        XCTAssertEqual(retrievedTotalElementAdded, 3)
                                        
                                            redis.spop(self.key2, count: 2) {
                                            (memberPopped: [RedisString?]?, error: NSError?) in
                                            
                                            XCTAssertNil(error, "Error: \(error)")
                                            XCTAssertNotNil(memberPopped)
                                            
                                            redis.scard(self.key2) {
                                                (retrievedTotalMembers: Int?, error: NSError?) in
                                                XCTAssertNil(error)
                                                XCTAssertEqual(retrievedTotalMembers, 1, "There should be 1 member but there are \(retrievedTotalMembers) member(s)")
                                                
                                                expectation1.fulfill()
                                            }
                                        }
                                    }
                                }
                            } else {
                                expectation1.fulfill()
                            }
                        }
                    }
                }
            }
        }
        waitForExpectations(timeout: 10, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_spop_redis() {
        let expectation1 = expectation(description: "Removes and returns one or more random elements from the set value store at key.")
        setupRedisTests {
            
            redis.sadd(self.redisKey1, members: self.redismember1, self.redismember2, self.redismember3) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                XCTAssertNil(error)
                XCTAssertEqual(retrievedTotalElementAdded, 3)
                
                    redis.spop(self.redisKey1) {
                    (memberPopped: RedisString?, error: NSError?) in
                    
                    XCTAssertNil(error)
                    XCTAssertNotNil(memberPopped)
                    
                    redis.scard(self.redisKey1) {
                        (retrievedTotalMembers: Int?, error: NSError?) in
                        XCTAssertNil(error)
                        XCTAssertEqual(retrievedTotalMembers, 2, "There should be 2 members but there are \(retrievedTotalMembers) member(s)")
                            
                            redis.info() {
                            (info: RedisInfo?, error: NSError?) in
                            
                            if let info = info {
                                
                                if info.server.checkVersionCompatible(major: 3, minor: 2) {
                                    
                                    redis.sadd(self.redisKey2, members: self.redismember1, self.redismember2, self.redismember3) {
                                        (retrievedTotalElementAdded: Int?, error: NSError?) in
                                        XCTAssertNil(error)
                                        XCTAssertEqual(retrievedTotalElementAdded, 3)
                                        
                                            redis.spop(self.redisKey2, count: 2) {
                                            (memberPopped: [RedisString?]?, error: NSError?) in
                                            
                                            XCTAssertNil(error)
                                            XCTAssertNotNil(memberPopped)
                                            
                                            redis.scard(self.redisKey2) {
                                                (retrievedTotalMembers: Int?, error: NSError?) in
                                                XCTAssertNil(error)
                                                XCTAssertEqual(retrievedTotalMembers, 1, "There should be 1 member but there are \(retrievedTotalMembers) member(s)")
                                                
                                                expectation1.fulfill()
                                            }
                                        }
                                    }
                                } else {
                                    expectation1.fulfill()
                                }
                            }
                        }
                    }
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_srandmember() {
        let expectation1 = expectation(description: "Return a random element from the set value stored at key")
        setupTests {
            redis.sadd(self.key1, members: self.member1, self.member2, self.member3) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                XCTAssertNil(error)
                XCTAssertEqual(retrievedTotalElementAdded, 3)
                
                    redis.srandmember(self.key1) {
                    (retrievedMember: RedisString?, error: NSError?) in
                    
                    XCTAssertNil(error)
                    XCTAssertNotNil(retrievedMember)
                    
                    expectation1.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_srandmember_redis() {
        let expectation1 = expectation(description: "Return a random element from the set value stored at key")
        setupRedisTests {
            
            redis.sadd(self.redisKey1, members: self.redismember1, self.redismember2, self.redismember3) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                XCTAssertNil(error)
                XCTAssertEqual(retrievedTotalElementAdded, 3)
                
                    redis.srandmember(self.redisKey1) {
                    (retrievedMember: RedisString?, error: NSError?) in
                    
                    XCTAssertNil(error)
                    XCTAssertNotNil(retrievedMember)
                    
                    expectation1.fulfill()
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_srem() {
        let expectation1 = expectation(description: "Removed the specified members from the set stored at a key")
        setupTests {
            redis.sadd(self.key1, members: self.member1, self.member2, self.member3) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                XCTAssertNil(error)
                XCTAssertEqual(retrievedTotalElementAdded, 3)
                
                redis.srem(self.key1, members: self.member3, self.member2) {
                (totalMembersRemoved: Int?, error: NSError?) in
                
                XCTAssertNil(error)
                XCTAssertNotNil(totalMembersRemoved)
                XCTAssertEqual(totalMembersRemoved, 2)
                
                    redis.scard(self.key1) {
                        (totalMembers: Int?, error: NSError?) in
                        XCTAssertEqual(totalMembers, 1)
                        
                        expectation1.fulfill()
                    }
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_srem_redis() {
        let expectation1 = expectation(description: "Removed the specified members from the set stored at a key")
        setupRedisTests {
            
            redis.sadd(self.redisKey1, members: self.redismember1, self.redismember2, self.redismember3) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                XCTAssertNil(error)
                XCTAssertEqual(retrievedTotalElementAdded, 3)
                
                redis.srem(self.redisKey1, members: self.redismember3, self.redismember2) {
                (totalMembersRemoved: Int?, error: NSError?) in
                
                XCTAssertNil(error)
                XCTAssertNotNil(totalMembersRemoved)
                XCTAssertEqual(totalMembersRemoved, 2)
                
                    redis.scard(self.redisKey1) {
                        (totalMembers: Int?, error: NSError?) in
                        XCTAssertEqual(totalMembers, 1)
                        
                        expectation1.fulfill()
                    }
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_sunion() {
        let expectation1 = expectation(description: "Unions all the sets given")
        setupTests {
            
            redis.sadd(self.key1, members: self.member1, self.member2) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                XCTAssertNil(error)
                XCTAssertEqual(retrievedTotalElementAdded, 2)
                
                    redis.sadd(self.key2, members: self.member3) {
                    (retrievedTotalElementAdded: Int?, error: NSError?) in
                    XCTAssertNil(error)
                    XCTAssertEqual(retrievedTotalElementAdded, 1)
                    
                        redis.sadd(self.key3, members: self.member1, self.member3, self.member4) {
                        (retrievedTotalElementAdded: Int?, error: NSError?) in
                        XCTAssertNil(error)
                        XCTAssertEqual(retrievedTotalElementAdded, 3)
                        
                            redis.sunion(self.key1, self.key2, self.key3) {
                            (retrievedMemberList: [RedisString?]?, error: NSError?) in
                            
                            XCTAssertNil(error)
                            XCTAssertNotNil(retrievedMemberList)
                            XCTAssertEqual(retrievedMemberList!.count, 4)
                            
                            expectation1.fulfill()
                        }
                    }
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }


    func test_sunion_redis() {
        let expectation1 = expectation(description: "Unions all the sets given")
        setupRedisTests {
            
            redis.sadd(self.redisKey1, members: self.redismember1, self.redismember2) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                XCTAssertNil(error)
                XCTAssertEqual(retrievedTotalElementAdded, 2)
                
                redis.sadd(self.redisKey2, members: self.redismember3) {
                    (retrievedTotalElementAdded: Int?, error: NSError?) in
                    XCTAssertNil(error)
                    XCTAssertEqual(retrievedTotalElementAdded, 1)
                    
                        redis.sadd(self.redisKey3, members: self.redismember1, self.redismember3, self.redismember4) {
                        (retrievedTotalElementAdded: Int?, error: NSError?) in
                        XCTAssertNil(error)
                        XCTAssertEqual(retrievedTotalElementAdded, 3)
                        
                            redis.sunion(self.redisKey1, self.redisKey2, self.redisKey3) {
                            (retrievedMemberList: [RedisString?]?, error: NSError?) in
                            
                            XCTAssertNil(error)
                            XCTAssertNotNil(retrievedMemberList)
                            XCTAssertEqual(retrievedMemberList!.count, 4)
                            
                            expectation1.fulfill()
                        }
                    }
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_sunionstore() {
        let expectation1 = expectation(description: "Unions all the sets given")
        setupTests {
            redis.sadd(self.key1, members: self.member1, self.member2) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                XCTAssertNil(error)
                XCTAssertEqual(retrievedTotalElementAdded, 2)
                
                    redis.sadd(self.key2, members: self.member3) {
                    (retrievedTotalElementAdded: Int?, error: NSError?) in
                    XCTAssertNil(error)
                    XCTAssertEqual(retrievedTotalElementAdded, 1)
                    
                        redis.sadd(self.key3, members: self.member1, self.member3, self.member4) {
                        (retrievedTotalElementAdded: Int?, error: NSError?) in
                        XCTAssertNil(error)
                        XCTAssertEqual(retrievedTotalElementAdded, 3)
                        
                            redis.sunionstore(self.key4, keys: self.key1, self.key2, self.key3) {
                            (retrievedMemberList: Int?, error: NSError?) in
                            
                            XCTAssertNil(error)
                            XCTAssertNotNil(retrievedMemberList)
                            
                            redis.scard(self.key4) {
                                (totalMembers: Int?, error: NSError?) in
                                XCTAssertEqual(totalMembers, 4)
                                
                                expectation1.fulfill()
                            }
                        }
                    }
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_sunionstore_redis() {
        let expectation1 = expectation(description: "Unions all the sets given")
        setupRedisTests {
            
            redis.sadd(self.redisKey1, members: self.redismember1, self.redismember2) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                XCTAssertNil(error)
                XCTAssertEqual(retrievedTotalElementAdded, 2)
                
                    redis.sadd(self.redisKey2, members: self.redismember3) {
                    (retrievedTotalElementAdded: Int?, error: NSError?) in
                    XCTAssertNil(error)
                    XCTAssertEqual(retrievedTotalElementAdded, 1)
                    
                        redis.sadd(self.redisKey3, members: self.redismember1, self.redismember3, self.redismember4) {
                        (retrievedTotalElementAdded: Int?, error: NSError?) in
                        XCTAssertNil(error)
                        XCTAssertEqual(retrievedTotalElementAdded, 3)
                        
                            redis.sunionstore(self.redisKey4, keys: self.redisKey1, self.redisKey2, self.redisKey3) {
                            (retrievedMemberList: Int?, error: NSError?) in
                            
                            XCTAssertNil(error)
                            XCTAssertNotNil(retrievedMemberList)
                            
                            redis.scard(self.redisKey4) {
                                (totalMembers: Int?, error: NSError?) in
                                XCTAssertEqual(totalMembers, 4)
                            }
                            
                            expectation1.fulfill()
                        }
                    }
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_sscan() {
        let expectation1 = expectation(description: "Incrementally iterate over a collection of sets.")
        setupTests {
            redis.sadd(self.key1, members: self.member1, self.member2, self.member3, self.member4) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                XCTAssertNil(error)
                XCTAssertEqual(retrievedTotalElementAdded, 4)
                
                    redis.sscan(self.key1, cursor: 0) {
                    (cursor: RedisString?, retrievedResults: [RedisString?]?, error: NSError?) in
                    
                    XCTAssertNil(error)
                    XCTAssertEqual(retrievedResults!.count, 4)
                    
                        redis.sadd(self.key2, members: "1", "2", "3", "foo", "foobar", "feelsgoodman") {
                        (retrievedTotalElementAdded: Int?, error: NSError?) in
                        XCTAssertNil(error)
                        XCTAssertEqual(retrievedTotalElementAdded, 6)
                        
                            redis.sscan(self.key2, cursor: 0, match: "f*") {
                            (cursor: RedisString?, retrievedResults: [RedisString?]?, error: NSError?) in
                            
                            XCTAssertNil(error)
                            XCTAssertNotNil(cursor)
                            XCTAssertNotNil(retrievedResults)
                            
                                redis.sscan(self.key2, cursor: 0, count: 3) {
                                (cursor: RedisString?, retrievedResults: [RedisString?]?, error: NSError?) in
                                
                                XCTAssertNil(error)
                                XCTAssertNotNil(cursor)
                                XCTAssertNotNil(retrievedResults)
                                
                                    redis.sscan(self.key2, cursor: 0, match: "f*", count: 3) {
                                    (cursor: RedisString?, retrievedResults: [RedisString?]?, error: NSError?) in
                                    
                                    XCTAssertNil(error)
                                    XCTAssertNotNil(cursor)
                                    XCTAssertNotNil(retrievedResults)
                                    
                                    expectation1.fulfill()
                                }
                            }
                        }
                    }
                }
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_sscan_redis() {
        let expectation1 = expectation(description: "Incrementally iterate over a collection of sets.")
        setupRedisTests {

            redis.sadd(self.redisKey1, members: self.redismember1, self.redismember2, self.redismember3, self.redismember4) {
                (retrievedTotalElementAdded: Int?, error: NSError?) in
                XCTAssertNil(error)
                XCTAssertEqual(retrievedTotalElementAdded, 4)
            
                redis.sscan(self.redisKey1, cursor: 0) {
                    (cursor: RedisString?, retrievedResults: [RedisString?]?, error: NSError?) in
                    
                    XCTAssertNil(error)
                    XCTAssertEqual(retrievedResults!.count, 4)
                    
                        redis.sadd(self.redisKey2, members: RedisString("1"), RedisString("2"),
                               RedisString("3"), RedisString("foo"), RedisString("foobar"), RedisString("feelsgoodman")) {
                                (retrievedTotalElementAdded: Int?, error: NSError?) in
                                XCTAssertNil(error)
                                XCTAssertEqual(retrievedTotalElementAdded, 6)
                                
                                redis.sscan(self.redisKey2, cursor: 0, match: RedisString("f*")) {
                                    (cursor: RedisString?, retrievedResults: [RedisString?]?, error: NSError?) in
                                    
                                    XCTAssertNil(error)
                                    XCTAssertNotNil(cursor)
                                    XCTAssertNotNil(retrievedResults)
                                    
                                    redis.sscan(self.redisKey2, cursor: 0, count: 3) {
                                        (cursor: RedisString?, retrievedResults: [RedisString?]?, error: NSError?) in
                                        
                                        XCTAssertNil(error)
                                        XCTAssertNotNil(cursor)
                                        XCTAssertNotNil(retrievedResults)
                                        
                                        redis.sscan(self.redisKey2, cursor: 0, match: RedisString("f*"), count: 3) {
                                            (cursor: RedisString?, retrievedResults: [RedisString?]?, error: NSError?) in
                                            
                                            XCTAssertNil(error)
                                            XCTAssertNotNil(cursor)
                                            XCTAssertNotNil(retrievedResults)
                                            
                                            expectation1.fulfill()
                                        }
                                    }
                                }
                    }
                }
            }
            
            
            
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_info() {
        let expectation1 = expectation(description: "Shows some information about the redis server")
        
        redis.info() {
            (info: RedisInfo?, error: NSError?) in
            
            XCTAssertNil(error)
            XCTAssertNotNil(info)
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }

    
}
