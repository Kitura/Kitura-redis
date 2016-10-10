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
public class TestTransactionsPart5: XCTestCase {
    static var allTests: [(String, (TestTransactionsPart5) -> () throws -> Void)] {
        return [
            ("test_keyUnion", test_keyUnion),
            ("test_Move", test_Move),
            ("test_Diffstorespop", test_Diffstorespop)
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
    
    func test_keyUnion() {
        setupTests() {
            let multi = redis.multi()
            multi.sadd(self.key1, members: self.expVal1)
            multi.sadd(self.key2, members: self.expVal2)
            multi.sunion(self.key1, self.key2)
            
            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 3) {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.IntegerValue(1), "sadd didn't return an 'OK'")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.IntegerValue(1), "sadd didn't return an 'OK'")
                    XCTAssertNotNil(nestedResponses[2], "Union failed")
                }
            }
        }
    }
    
    func test_Move() {
        setupTests() {
            let multi = redis.multi()
            multi.sadd(self.key1, members: self.expVal1, self.expVal2, self.expVal3)
            multi.sadd(self.key1, members: self.expVal2, self.expVal4)
            multi.srem(self.key1, members: self.expVal2)
            multi.smove(source: self.key1, destination: self.key2, member: self.expVal1)
            multi.scard(self.key2)
            
            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 5) {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.IntegerValue(3), "Added only \(nestedResponses[0]) not 3")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.IntegerValue(1), "set didn't return an 'OK'")
                    XCTAssertEqual(nestedResponses[2], RedisResponse.IntegerValue(1), "Should have removed \(self.expVal2)")
                    XCTAssertEqual(nestedResponses[3], RedisResponse.IntegerValue(1), "\(self.expVal2) should no longer exist in \(self.key1)")
                    XCTAssertEqual(nestedResponses[4], RedisResponse.IntegerValue(1), "There should be 1 member in \(self.key2)")
                }
            }
        }
    }
    
    func test_Diffstorespop() {
        setupTests() {
            let multi = redis.multi()
            multi.sadd(self.key1, members: self.expVal1, self.expVal2, self.expVal3)
            multi.sadd(self.key2, members: self.expVal2, self.expVal4)
            multi.sdiffstore(destination: self.key3, keys: self.key1, self.key2)
            multi.spop(self.key3)
            
            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 4) {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.IntegerValue(3), "Added only \(nestedResponses[0]) not 3")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.IntegerValue(2), "Added only \(nestedResponses[1]) not 2")
                    XCTAssertEqual(nestedResponses[2], RedisResponse.IntegerValue(2), "Added only \(nestedResponses[2]) not 2")
                    XCTAssertNotNil(nestedResponses[3], "Nothing was popped")
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
