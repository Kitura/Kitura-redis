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

//Tests the Pub/Sub operations
public class TestTransactionsPart8: XCTestCase {
    static var allTests: [(String, (TestTransactionsPart8) -> () throws -> Void)] {
        return [
            
        ]
    }
    
    let secondConnection = Redis()
    
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
    
    private func baseAsserts(response: RedisResponse, count: Int) -> [RedisResponse]? {
        switch(response) {
        case .Array(let responses):
            XCTAssertEqual(responses.count, count, "Number of nested responses wasn't \(count), was \(responses.count)")
            for nestedResponse in responses {
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
    
    override public func tearDown() {
        let dispatchGroup = DispatchGroup()
        
        for _ in 0...3 {
            dispatchGroup.enter()
        }
        
        redis.unsubscribe { (res, err) in
            XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
            XCTAssertNotNil(res, "UNSUBSCRIBE should not have returned nil.")
            dispatchGroup.leave()
        }
        redis.punsubscribe { (res, err) in
            XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
            XCTAssertNotNil(res, "PUNSUBSCRIBE should not have returned nil.")
            dispatchGroup.leave()
        }
        secondConnection.unsubscribe { (res, err) in
            XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
            XCTAssertNotNil(res, "UNSUBSCRIBE should not have returned nil.")
            dispatchGroup.leave()
        }
        secondConnection.punsubscribe { (res, err) in
            XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
            XCTAssertNotNil(res, "PUNSUBSCRIBE should not have returned nil.")
            dispatchGroup.leave()
        }
        
        dispatchGroup.wait()
    }
    
    func test_publish() {
        extendedSetup {
            let multi = redis.multi()
            
            secondConnection.subscribe(channels: channel1, callback: { (res, err) in
                XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
                XCTAssertNotNil(res, "SUBSCRIBE should not have returned nil.")
                
                secondConnection.psubscribe(patterns: pattern2, callback: { (res, err) in
                    XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
                    XCTAssertNotNil(res, "PSUBSCRIBE should not have returned nil.")
                    
                    multi.publish(channel: channel1, message: messageA)
                    multi.publish(channel: channel2, message: messageA)
                    multi.publish(channel: channel3, message: messageA)
                    multi.exec({ (res) in
                        if let responses = self.baseAsserts(response: res, count: 3) {
                            let res0 = responses[0].asInteger
                            XCTAssertNotNil(res0, "PUBLISH should not return nil.")
                            XCTAssertEqual(res0, 1, "PUBLISH to \(self.channel1) should return 1, not \(res0).")
                            
                            let res1 = responses[1].asInteger
                            XCTAssertNotNil(res1, "PUBLISH should not return nil.")
                            XCTAssertEqual(res1, 1, "PUBLISH to \(self.channel2) should return 1, not \(res1).")
                            
                            let res2 = responses[2].asInteger
                            XCTAssertNotNil(res0, "PUBLISH should not return nil.")
                            XCTAssertEqual(res2, 0, "PUBLISH to \(self.channel3) should return 0, not \(res2).")
                        }
                    })
                })
            })
        }
    }
    
    func test_subscribePsubscribe() {
        extendedSetup {
            let multi = redis.multi()
            
            multi.subscribe(channels: channel1)
            multi.psubscribe(patterns: pattern2)
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 2) {
                    
                    let res0 = responses[0].asArray
                    XCTAssertNotNil(res0, "SUBSCRIBE channel1 should not return nil.")
                    let res00 = res0?[0].asString
                    XCTAssertEqual(res00, RedisString("subscribe"), "SUBSCRIBE \(self.channel1) should return \"subscribe\", not \(res00).")
                    let res01 = res0?[1].asString
                    XCTAssertEqual(res01, RedisString(self.channel1), "SUBSCRIBE \(self.channel1) should return \(self.channel1), not \(res01).")
                    
                    let res1 = responses[1].asArray
                    XCTAssertNotNil(res1, "SUBSCRIBE pattern2 should not return nil.")
                    let res10 = res1?[0].asString
                    XCTAssertEqual(res10, RedisString("psubscribe"), "SUBSCRIBE \(self.pattern2) should return \"subscribe\", not \(res10).")
                    let res11 = res1?[1].asString
                    XCTAssertEqual(res11, RedisString(self.pattern2), "SUBSCRIBE \(self.pattern2) should return \(self.channel2), not \(res11).")
                }
            })
        }
    }
    
    func test_pubsubChannelsNumsubNumPat() {
        extendedSetup {
            let multi = redis.multi()
            
            secondConnection.subscribe(channels: channel1, callback: { (res, err) in
                XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
                XCTAssertNotNil(res, "SUBSCRIBE channel1 should not have returned nil.")

                secondConnection.psubscribe(patterns: pattern2, callback: { (res, err) in
                    XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
                    XCTAssertNotNil(res, "PSUBSCRIBE pattern2 should not have returned nil.")
                    
                    multi.pubsubChannels(pattern: pattern1)
                    multi.pubsubChannels(pattern: pattern2)
                    multi.pubsubChannels()
                    multi.pubsubNumsub(channels: channel1, channel2)
                    multi.pubsubNumsub()
                    multi.pubsubNumpat()
                    multi.exec({ (res) in
                        if let responses = self.baseAsserts(response: res, count: 6) {
                            
                            let res0 = responses[0].asArray
                            XCTAssertNotNil(res0, "PUBSUB CHANNELS pattern1 should not have returned nil.")
                            XCTAssertEqual(res0?[0].asString, RedisString(self.channel1), "PUBSUB CHANNELS res[0] should be 'channel1', not \(res).")
                            
                            let res1 = responses[1].asArray
                            XCTAssertNotNil(res1, "PUBSUB CHANNELS pattern2 should not have returned nil.")
                            XCTAssertEqual(res1?.count, 0, "PUBSUB CHANNELS pattern2 should return [], not \(res1).")
                            
                            let res2 = responses[2].asArray
                            XCTAssertNotNil(res2, "PUBSUB CHANNELS should not have returned nil.")
                            XCTAssertEqual(res2?[0].asString, RedisString(self.channel1), "PUBSUB CHANNELS res[0] should be 'channel1', not \(res2).")
                            
                            let res3 = responses[3].asArray
                            XCTAssertNotNil(res3, "PUBSUB NUMSUB channel1 channel2 should not have returned nil.")
                            let count = res3?.count
                            XCTAssertEqual(count, 4, "PUBSUB NUMSUB channel1 channel2 channel1 channel2 result array count should be 4, not \(count).")
                            let res30 = res3?[0].asString
                            XCTAssertEqual(res30, RedisString(self.channel1), "PUBSUB NUMSUB res[0] should be \(self.channel1), not \(res30).")
                            let res31 = res3?[1].asInteger
                            XCTAssertEqual(res31, 1, "PUBSUB NUMSUB channel1 channel2 res[1] should be 1, not \(res31).")
                            let res32 = res3?[2].asString
                            XCTAssertEqual(res32, RedisString(self.channel2), "PUBSUB NUMSUB channel1 channel2 res[2] should be \(self.channel2), not \(res32).")
                            let res33 = res3?[3].asInteger
                            XCTAssertEqual(res33, 0, "PUBSUB NUMSUB channel1 channel2 res[3] should be 0, not \(res33).")
                            
                            let res4 = responses[4].asArray
                            XCTAssertNotNil(res4, "PUBSUB NUMSUB should not have returned nil.")
                            XCTAssertEqual(res4?.count, 0, "PUBSUB CHANNELS pattern2 should return [], not \(res4).")
                            
                            let res5 = responses[5].asInteger
                            XCTAssertNotNil(res5, "PUBSUB NUMPAT should not have returned nil.")
                            XCTAssertEqual(res5, 1, "PUBSUB NUMPAT should return 1, not \(res5).")
                        }
                    })
                })
            })
        }
    }
}
