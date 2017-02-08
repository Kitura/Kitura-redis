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
            
            // Part 2
            ("test_lindexLinsertAndLlen", test_lindexLinsertAndLlen),
            
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
    
    // MARK: - Part 2
    func test_lindexLinsertAndLlen() {
        localSetup() {
            let value1 = "cash me oussah"
            let value2 = "howbowda"
            let value3 = "to grandmothers house we go"
            
            redis.lpush(self.key1, values: value1, value2) {(numberSet: Int?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                
                let multi = redis.multi()
                
                multi.lindex(self.key1, index: 0)
                multi.lindex(self.key1, index: 1)
                
                multi.exec() {(response: RedisResponse) in
                    if let nestedResponses = self.baseAsserts(response: response, count: 2) {
                        XCTAssertEqual(nestedResponses[0].asString, RedisString(value2), "Result of lindex was \(nestedResponses[0].asString), instead of \(value2).")
                        XCTAssertEqual(nestedResponses[1].asString, RedisString(value1), "Result of lindex was \(nestedResponses[1].asString). Instead of \(value1).")
                    }
                }
                
//                redis.linsert(self.key1, before: true, pivot: value3, value: value2) {(listSize: Int?, error: NSError?) in
//                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
//                    XCTAssertNotNil(listSize, "Result of linsert was nil, but \(self.key1) should exist")
//                    XCTAssertEqual(listSize!, 3, "Returned \(listSize!) for \(self.key1) instead of 3")
//                    
//                    
//                    redis.llen(self.key1) {(listSize: Int?, error: NSError?) in
//                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
//                        XCTAssertNotNil(listSize, "Result of llen was nil, but \(self.key1) should exist")
//                        XCTAssertEqual(listSize!, 3, "Returned \(listSize!) for \(self.key1) instead of 3")
//                        
//                        redis.lindex(self.key1, index: 2) {(retrievedValue: RedisString?, error: NSError?) in
//                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
//                            XCTAssertNotNil(retrievedValue, "Result of lindex was nil, but \(self.key1) should exist")
//                            XCTAssertEqual(retrievedValue!, RedisString(value1), "Result of lindex was \(retrievedValue!). It should have been \(value1)")
//                        }
//                    }
//                }
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
