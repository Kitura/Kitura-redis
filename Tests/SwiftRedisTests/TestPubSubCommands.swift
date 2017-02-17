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


public class TestPubSubCommands: XCTestCase {
    static var allTests: [(String, (TestPubSubCommands) -> () throws -> Void)] {
        return [
//            ("test_1", test_1),
//            ("test_2", test_2),
//            ("test_3", test_3),
//            ("test_4", test_4),
//            ("test_5", test_5)
        ]
    }
    
    let secondConnection = Redis()
    let sleepTime: UInt32 = 1
    
    var channel1 = "channel1"
    var channel2 = "channel2"
    var channel3 = "channel3"
    
    var pattern1 = "c?annel1"
    var pattern2 = "*2"
    var pattern3 = "c[ha]annel3"
    
    var messageA = "messageA"
    
    func localSetup(block: () -> Void) {
        connectRedis() { (err: NSError?) in
            guard err == nil else {
                XCTFail("Could not connect to Redis")
                return
            }
            block()
        }
    }
    
    func extendedSetup(block: () -> Void) {
        localSetup() {
            let password = read(fileName: "password.txt")
            let host = read(fileName: "host.txt")
            
            secondConnection.connect(host: host, port: 6379) { (err: NSError?) in
                XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
                
                secondConnection.auth(password) { (err: NSError?) in
                    XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
                    block()
                }
            }
        }
    }
    
    override public func tearDown() {
//        secondConnection.unsubscribe()
//        secondConnection.punsubscribe()
//        sleep(sleepTime)
    }
    
    // PUBLISH, SUBSCRIBE, UNSUBSCRIBE
//    func test_1() {
//        extendedSetup() {
//            
//            // PUBLISH channel1
//            redis.publish(channel: channel1, message: messageA, callback: { (res, err) in
//                XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
//                XCTAssertNotNil(res, "PUBLISH should not have returned nil.")
//                XCTAssertEqual(res, 0, "PUBLISH should return 0, not \(res).")
//                
//                // SUBSCRIBE channel1
//                secondConnection.subscribe(channels: channel1, callback: { (res, err) in
//                    XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
//                    XCTAssertNotNil(res, "PUBLISH should not have returned nil.")
//                    let res0 = (res?[0] as? RedisString)?.asString
//                    let res1 = (res?[1] as? RedisString)?.asString
//                    let res2 = (res?[2] as? RedisString)?.asInteger
//                    XCTAssertEqual(res0, "subscribe", "Should return subscribe, not \(res0).")
//                    XCTAssertEqual(res1, channel1, "Should return channel1, not \(res1).")
//                    XCTAssertEqual(res2, 1, "Should return 1, not \(res2).")
//                  
//                    // PUBLISH channel1
//                    redis.publish(channel: channel1, message: messageA, callback: { (res, err) in
//                        XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
//                        XCTAssertNotNil(res, "PUBLISH should not have returned nil.")
//                        XCTAssertEqual(res, 1, "PUBLISH should return 1, not \(res).")
//                        
//                        // UNSUBSCRIBE channel1
//                        secondConnection.unsubscribe(channels: channel1, callback: { (res, err) in
//                          
//                            // PUBLISH channel1
//                            redis.publish(channel: channel1, message: messageA, callback: { (res, err) in
//                                XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
//                                XCTAssertNotNil(res, "PUBLISH should not have returned nil.")
//                                XCTAssertEqual(res, 0, "PUBLISH should return 0, not \(res).")
//                            })
//                        })
//                    })
//                })
//            })
//        }
//    }
    
//    // PUBLISH, SUBSCRIBE, UNSUBSCRIBE multiple channels
//    func test_2() {
//        extendedSetup() {
//            
//            // SUBSCRIBE channel1, channel2, channel3
//            secondConnection.subscribe(channels: channel1, channel2, channel3, callback: { (res, err) in
//                print("SUBSCRIBE \(res)")
//              
//                // PUBLISH channel1
//                redis.publish(channel: channel1, message: messageA, callback: { (res, err) in
//                    XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
//                    XCTAssertNotNil(res, "PUBLISH should not have returned nil.")
//                    XCTAssertEqual(res, 1, "PUBLISH should return 1, not \(res).")
//                    
//                    // PUBLISH channel2
//                    redis.publish(channel: channel2, message: messageA, callback: { (res, err) in
//                        XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
//                        XCTAssertNotNil(res, "PUBLISH should not have returned nil.")
//                        XCTAssertEqual(res, 1, "PUBLISH should return 1, not \(res).")
//                        
//                        // UNSUBSCRIBE channel2, channel3
//                        secondConnection.unsubscribe(channels: channel2, channel3, callback: { (res, err) in
//                            print("1 UNSUBSCRIBE \(res)")
//                            
//                            // PUBLISH channel2
//                            redis.publish(channel: channel2, message: messageA, callback: { (res, err) in
//                                XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
//                                XCTAssertNotNil(res, "PUBLISH should not have returned nil.")
//                                XCTAssertEqual(res, 0, "PUBLISH should return 0, not \(res).")
//                            })
//                            
//                            // PUBLISH channel3
//                            redis.publish(channel: channel3, message: messageA, callback: { (res, err) in
//                                XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
//                                XCTAssertNotNil(res, "PUBLISH should not have returned nil.")
//                                XCTAssertEqual(res, 0, "PUBLISH should return 0, not \(res).")
//                            })
//                            
//                            // UNSUBSCRIBE
//                            secondConnection.unsubscribe(callback: { (res, err) in
//                                print("3 UNSUBSCRIBE \(res)")
//                                
//                                // PUBLISH channel1
//                                redis.publish(channel: channel1, message: messageA, callback: { (res, err) in
//                                    XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
//                                    XCTAssertNotNil(res, "PUBLISH should not have returned nil.")
//                                    XCTAssertEqual(res, 0, "PUBLISH should return 0, not \(res).")
//                                })
//                            })
//                        })
//                    })
//                })
//            })
//        }
//    }
//
//    // PSUBSCRIBE, PUNSUBSCRIBE
//    func test_3() {
//        extendedSetup() {
//            // Subscribe to pattern1, pattern2, pattern3
//            secondConnection.psubscribe(patterns: pattern1, pattern2, pattern3)
//            sleep(sleepTime)
//            
//            // Publish to pattern1
//            redis.publish(channel: pattern1, message: messageA, callback: { (res, err) in
//                XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
//                XCTAssertNotNil(res, "PUBLISH should not have returned nil.")
//                XCTAssertEqual(res, 1, "PUBLISH should return 1, not \(res).")
//                
//                // Publish to pattern2
//                redis.publish(channel: pattern2, message: messageA, callback: { (res, err) in
//                    XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
//                    XCTAssertNotNil(res, "PUBLISH should not have returned nil.")
//                    XCTAssertEqual(res, 1, "PUBLISH should return 1, not \(res).")
//                    
//                    // Unsubscribe from pattern2, pattern3
//                    secondConnection.punsubscribe(patterns: pattern2, pattern3)
//                    sleep(sleepTime)
//                    
//                    // Publish to pattern2
//                    redis.publish(channel: pattern2, message: messageA, callback: { (res, err) in
//                        XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
//                        XCTAssertNotNil(res, "PUBLISH should not have returned nil.")
//                        XCTAssertEqual(res, 0, "PUBLISH should return 0, not \(res).")
//                    })
//                    
//                    // Publish to pattern3
//                    redis.publish(channel: pattern3, message: messageA, callback: { (res, err) in
//                        XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
//                        XCTAssertNotNil(res, "PUBLISH should not have returned nil.")
//                        XCTAssertEqual(res, 0, "PUBLISH should return 0, not \(res).")
//                    })
//                    
//                    // Unsubscribe from all channels
//                    secondConnection.punsubscribe()
//                    sleep(sleepTime)
//                    
//                    // Publish to pattern1
//                    redis.publish(channel: pattern1, message: messageA, callback: { (res, err) in
//                        XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
//                        XCTAssertNotNil(res, "PUBLISH should not have returned nil.")
//                        XCTAssertEqual(res, 0, "PUBLISH should return 0, not \(res).")
//                    })
//                })
//            })
//        }
//    }
//    
//    // PUBSUB: CHANNELS, NUMSUB
//    func test_4() {
//        extendedSetup() {
//            
//            // NUMSUB no channels
//            redis.pubsubNumsub(callback: { (res, err) in
//                XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
//                XCTAssertNotNil(res, "PUBSUB CHANNELS should not have returned nil.")
//                XCTAssertEqual(res?.count, 0, "PUBSUB NUMSUB res.COUNT should be 0, not \(res?.count).")
//            })
//            
//            // Subscribe to channel1
//            secondConnection.subscribe(channels: channel1, channel2)
//            sleep(sleepTime)
//            
//            // PSUBSCRIBE to pattern2
//            secondConnection.psubscribe(patterns: pattern3)
//            sleep(sleepTime)
//            
//            // NUMSUB channel1, channel3
//            redis.pubsubNumsub(channels: channel1, channel3, callback: { (res, err) in
//                XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
//                XCTAssertNotNil(res, "PUBSUB NUMSUB should not have returned nil.")
//                
//                let count = res?.count
//                XCTAssertEqual(count, 4, "PUBSUB NUMSUB res.count should be 4, not \(count)")
//                
//                let res0 = (res?[0] as? RedisString)?.asString
//                let res1 = (res?[1] as? RedisString)?.asInteger
//                let res2 = (res?[2] as? RedisString)?.asString
//                let res3 = (res?[3] as? RedisString)?.asInteger
//                XCTAssertEqual(res0, channel1, "PUBSUB NUMSUB res[0] should be \(channel1), not \(res0)")
//                XCTAssertEqual(res1, 1, "PUBSUB NUMSUB res[1] should be 1, not \(res1)")
//                XCTAssertEqual(res2, channel3, "PUBSUB NUMSUB res[2] should be \(channel3), not \(res2)")
//                XCTAssertEqual(res3, 0, "PUBSUB NUMSUB res[3] should be 0, not \(res3)")
//            })
//            
//            // CHANNELS on pattern1
//            redis.pubsubChannels(pattern: pattern1, callback: { (res, err) in
//                XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
//                XCTAssertNotNil(res, "PUBSUB CHANNELS should not have returned nil.")
//                XCTAssertEqual(res?[0]?.asString, channel1, "PUBSUB CHANNELS res[0] should be 'channel1', not \(res).")
//            })
//            
//            // CHANNELS get all
//            redis.pubsubChannels(callback: { (res, err) in
//                XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
//                XCTAssertNotNil(res, "PUBSUB CHANNELS should not have returned nil.")
//                XCTAssertEqual(res?.count, 2, "PUBSUB CHANNELS res array should be size 2, not \(res).")
//            })
//        }
//    }
//    
//    // PUBSUB NUMPAT
//    func test_5() {
//        extendedSetup() {
//            
//            // NUMPAT
//            redis.pubsubNumpat(callback: { (res, err) in
//                XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
//                XCTAssertNotNil(res, "PUBSUB NUMPAT should not have returned nil.")
//                XCTAssertEqual(res, 0, "PUBSUB NUMPAT should reutnr 0, not \(res).")
//                
//                // SUBSCRIBE to channel1
//                secondConnection.subscribe(channels: channel1)
//                sleep(sleepTime)
//                
//                // NUMPAT
//                redis.pubsubNumpat(callback: { (res, err) in
//                    XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
//                    XCTAssertNotNil(res, "PUBSUB NUMPAT should not have returned nil.")
//                    XCTAssertEqual(res, 0, "PUBSUB NUMPAT should reutnr 0, not \(res).")
//                    
//                    // PSUBSCRIBE to pattern1
//                    secondConnection.psubscribe(patterns: pattern1)
//                    sleep(sleepTime)
//                    
//                    // NUMPAT
//                    redis.pubsubNumpat(callback: { (res, err) in
//                        XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
//                        XCTAssertNotNil(res, "PUBSUB NUMPAT should not have returned nil.")
//                        XCTAssertEqual(res, 1, "PUBSUB NUMPAT should reutnr 0, not \(res).")
//                    })
//                })
//            })
//        }
//    }
}