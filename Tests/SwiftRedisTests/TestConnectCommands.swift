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

public class TestConnectCommands: XCTestCase {
    static var allTests: [(String, (TestConnectCommands) -> () throws -> Void)] {
        return [
            ("test_connectFailure", test_connectFailure),
            ("test_info", test_info),
            ("test_pingAndEcho", test_pingAndEcho),
            ("test_select", test_select)
        ]
    }
    
    func test_connectFailure() {
        let expectation1 = expectation(description: "Tests a connection failure to a redis server")
        
        let failingRedis = Redis()
        failingRedis.connect(host: "localhostx", port: 6379) {(error: NSError?) in
            XCTAssertNotNil(error, "Connected to Redis when it shouldn't have")
            expectation1.fulfill()
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }
    
    func test_info() {
        let expectation1 = expectation(description: "Shows some information about the redis server")
        
        connectRedis() {(error: NSError?) in
            if error != nil {
                XCTFail("Could not connect to Redis")
                return
            }
            
            redis.info() {
                (info: RedisInfo?, error: NSError?) in
                
                XCTAssertNil(error)
                XCTAssertNotNil(info)
                
                if let theInfo = info {
                    print("The Redis server version is \(theInfo.server.redis_version)")
                }
                
                expectation1.fulfill()
            }
        }
        waitForExpectations(timeout: 5, handler: {error in XCTAssertNil(error, "Timeout") })
    }

    func test_pingAndEcho() {
        connectRedis() {(error: NSError?) in
            if error != nil {
                XCTFail("Could not connect to Redis")
                return
            }

            redis.ping() {(error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")

                /* Changed for Redis 2.8.0
                let pingText = "Hello, hello, hello, hi there"
                redis.ping(pingText) {(error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                */
                    let echoText = "Echo, echo, echo......"
                    redis.echo(echoText) {(text: RedisString?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(text, "Received a nil for echo text")
                        XCTAssertEqual(text!.asString, echoText, "Echo returned '\(text!)'. Should have returned '\(echoText)'.")
                    }
               /* } */
            }
        }
    }

    func selectTestSetup(callback: () -> Void) {
        connectRedis() {(error: NSError?) in
            if error != nil {
                XCTFail("Could not connect to Redis")
                return
            }

            redis.select(1) {(error: NSError?) in
                redis.del(self.key) {(count: Int?, error: NSError?) in
                    redis.select(0) {(error: NSError?) in
                        callback()
                    }
                }
            }
        }
    }

    let key = "selectKey"

    func test_select() {
        selectTestSetup() {
            let expectedValue = "testing 1 2 3"
            let newValue = "xyzzy-plover"

            redis.set(self.key, value: expectedValue) {(wasSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssert(wasSet, "Failed to set \(self.key)")

                redis.select(99) {(error: NSError?) in
                    XCTAssertNotNil(error, "Database 99 shouldn't have been selected")

                    redis.select(1) {(error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")

                        redis.get(self.key) {(returnedValue: RedisString?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertNil(returnedValue, "Returned value was not nil. Was '\(returnedValue)'")

                            redis.set(self.key, value: newValue) {(wasSet: Bool, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssert(wasSet, "Failed to set \(self.key)")

                                redis.select(0) {(error: NSError?) in
                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")

                                    redis.get(self.key) {(returnedValue: RedisString?, error: NSError?) in
                                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                        XCTAssertEqual(returnedValue!.asString, expectedValue, "Returned value was not '\(expectedValue)'")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
