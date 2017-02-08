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
            ("test_blpopBrpopAndBrpoplpushEmptyLists", test_blpopBrpopAndBrpoplpushEmptyLists)
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
