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

class TestIssueCommand: XCTestCase {
    static var allTests: [(String, (TestIssueCommand) -> () throws -> Void)] {
        return [
            ("test_emptyCommand", test_emptyCommand),
            ("test_SetAndGet", test_SetAndGet),
            ("test_unconnectedHandle", test_unconnectedHandle)
        ]
    }
    
    func test_emptyCommand() {
        let emptyStringArray = [String]()
        let emptyRedisStringArray = [RedisString]()
        
        connectRedis() {(error: NSError?) in
            if error != nil {
                XCTFail("Could not connect to Redis")
                return
            }
            
            redis.issueCommandInArray(emptyStringArray) {(response: RedisResponse) in
                switch response {
                case .Error:
                    redis.issueCommandInArray(emptyRedisStringArray) {(response: RedisResponse) in
                        switch response {
                        case .Error:
                            break
                        default:
                            XCTFail("Failed to receive an error when the command array was empty")
                        }
                    }
                default:
                    XCTFail("Failed to receive an error when the command array was empty")
                }
            }
        }
    }

    func test_SetAndGet() {
        connectRedis() {(error: NSError?) in
            if error != nil {
                XCTFail("Could not connect to Redis")
                return
            }

            let key = "plover"
            let value = "613"

            redis.issueCommand("SET", key, value) {(response: RedisResponse) in
                switch response {
                    case .Error(let error):
                        XCTFail("Failed to SET \(key) to \(value). Error message=\(error)")

                    case .Status(let str):
                        XCTAssertEqual(str, "OK", "SET result value was NOT 'OK'. It was [\(str)]")

                        redis.issueCommand("GET", key) {(response: RedisResponse) in
                            switch response {
                                case .Error(let error):
                                    XCTFail("Failed to GET \(key). Error message=\(error)")

                                case .StringValue(let str):
                                    XCTAssertEqual(str.asString, value, "GET of \(key) result was NOT [\(value)]")

                                default:
                                    XCTFail("Received a RedisResponse of \(response) from a GET")
                            }
                        }

                    default:
                        XCTFail("Received a RedisResponse of \(response) from a SET")
                }
            }
        }
    }
    
    func test_unconnectedHandle() {
        let unconnectedRedis = Redis()
        unconnectedRedis.issueCommand("PING") {(response: RedisResponse) in
            switch response {
            case .Error:
                unconnectedRedis.issueCommand(RedisString("PING")) {(response: RedisResponse) in
                    switch response {
                    case .Error:
                        break
                        
                    default:
                        XCTFail("Didn't return an error when issueing a command with an unconnected Redis handle")
                    }
                }
                
            default:
                XCTFail("Didn't return an error when issueing a command with an unconnected Redis handle")
            }
        }
    }
}
