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
import Dispatch

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import Foundation
import XCTest


public class TestPubSub: XCTestCase {
    static var allTests: [(String, (TestPubSub) -> () throws -> Void)] {
        return [
            ("test_1", test_1),
            ("test_2", test_2)
        ]
    }
    
    let secondConnection = Redis()
    
    let queue = DispatchQueue(label: "unblocker", attributes: DispatchQueue.Attributes.concurrent)
    
    var channel1: String { return "1" }
    var channel2: String { return "2" }
    var channel3: String { return "2" }
    var messageA: String { return "A" }
    var messageB: String { return "B" }
    var messageC: String { return "C" }
    
    func localSetup(block: () -> Void) {
        connectRedis() { (error: NSError?) in
            if error != nil {
                XCTFail("Could not connect to Redis")
                return
            }
            
            redis.del(self.channel1, self.channel2, self.channel3, self.messageA, self.messageB, self.messageC) { (deleted: Int?, error: NSError?) in
                block()
            }
        }
    }
    
    func extendedSetup(block: () -> Void) {
        localSetup() {
            let password = read(fileName: "password.txt")
            let host = read(fileName: "host.txt")
            
            self.secondConnection.connect(host: host, port: 6379) { (error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                
                self.secondConnection.auth(password) { (error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    
                    block()
                }
            }
        }
    }
    
    // PUBLISH, SUBSCRIBE, UNSUBSCRIBE
    func test_1() {
        extendedSetup() {
            
            // Publish to channel1
            redis.publish(channel: self.channel1, message: self.messageA, callback: { (result, error) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssertNotNil(result, "PUBLISH should not have returned nil.")
                XCTAssertEqual(result, 0, "PUBLISH should return 0, not \(result).")
                
                // Subscribe to channel1
                self.secondConnection.subscribe(channels: self.channel1, callback: {
                    
                    // Publish to channel1
                    redis.publish(channel: self.channel1, message: self.messageA, callback: { (result, error) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(result, "PUBLISH should not have returned nil.")
                        XCTAssertEqual(result, 1, "PUBLISH should return 1, not \(result).")
                        
                        // Unsubscribe to channel1
                        self.secondConnection.unsubscribe(channels: self.channel1, callback: { 
                            
                            // Publish to channel1
                            redis.publish(channel: self.channel1, message: self.messageA, callback: { (result, error) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssertNotNil(result, "PUBLISH should not have returned nil.")
                                XCTAssertEqual(result, 0, "PUBLISH should return 0, not \(result).")
                            })
                        })
                    })
                })
            })
        }
    }
    
    // PUBLISH, SUBSCRIBE, UNSUBSCRIBE with multiple channels
    func test_2() {
        extendedSetup() {
            
            // Subscribe to channel1, channel2, channel3
            self.secondConnection.subscribe(channels: self.channel1, self.channel2, self.channel3, callback: {
                
                // Publish to channel1
                redis.publish(channel: self.channel1, message: self.messageA, callback: { (result, error) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(result, "PUBLISH should not have returned nil.")
                    XCTAssertEqual(result, 1, "PUBLISH should return 1, not \(result).")
                    
                    // Publish to channel2
                    redis.publish(channel: self.channel2, message: self.messageA, callback: { (result, error) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(result, "PUBLISH should not have returned nil.")
                        XCTAssertEqual(result, 1, "PUBLISH should return 1, not \(result).")
                        
                        // Unsubscribe from channel2, channel3
                        self.secondConnection.unsubscribe(channels: self.channel2, self.channel3, callback: {
                            
                            // Publish to channel2
                            redis.publish(channel: self.channel2, message: self.messageA, callback: { (result, error) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssertNotNil(result, "PUBLISH should not have returned nil.")
                                XCTAssertEqual(result, 0, "PUBLISH should return 0, not \(result).")
                            })
                            
                            // Publish to channel3
                            redis.publish(channel: self.channel3, message: self.messageA, callback: { (result, error) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssertNotNil(result, "PUBLISH should not have returned nil.")
                                XCTAssertEqual(result, 0, "PUBLISH should return 0, not \(result).")
                            })
                            
                            // Unsubscribe from all channels
                            self.secondConnection.unsubscribe(callback: {
                                
                                // Publish to channel1
                                redis.publish(channel: self.channel1, message: self.messageA, callback: { (result, error) in
                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                    XCTAssertNotNil(result, "PUBLISH should not have returned nil.")
                                    XCTAssertEqual(result, 0, "PUBLISH should return 0, not \(result).")
                                })
                            })
                        })
                    })
                })
            })
        }
    }
}
