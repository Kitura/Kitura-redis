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

import Foundation
import XCTest
import SwiftRedis

// Tests the Geo transaction operations
public class TestTransactionsPart9: XCTestCase {
    static var allTests: [(String, (TestTransactionsPart9) -> () throws -> Void)] {
        return [
//            ("test_keyManipulation", test_keyManipulation),
//            ("test_MemberManipulation", test_MemberManipulation),
//            ("test_ranges", test_ranges),
//            ("tests_Remove", tests_Remove),
        ]
    }
    
    let key = "Sicily"
    
    let longitude1 = 13.361389
    let latitude1 = 38.115556
    let member1 = "Palermo"
    
    let longitude2 = 15.087269
    let latitude2 = 37.502669
    let member2 = "Catania"
    
    private func setupTests(callback: () -> Void) {
        connectRedis() {(error: NSError?) in
            guard error == nil else {
                XCTFail("Could not connect to Redis.")
                return
            }
            redis.del(key, callback: { (res, err) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")  
                callback()
            })
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
    
    
//    func tests_Remove() {
//        setupTests {
//            let multi = redis.multi()
//            multi.zadd(self.key1, tuples: (1, "a"), (1, "b"), (1, "c"), (1, "d"), (1, "e"), (1, "f"), (1, "g"))
//            multi.zcount(self.key1, min: "-inf", max: "+inf")
//            multi.zlexcount(self.key1, min: "[b", max: "[f")
//            multi.zremrangebylex(self.key1, min: "[b", max: "[f")
//            
//            multi.zadd(self.key2, tuples: (1, "a"), (2, "b"), (3, "c"), (4, "d"), (5, "e"), (6, "f"), (7, "g"))
//            multi.zremrangebyrank(self.key2, start: 4, stop: 6)
//            multi.zcount(self.key2, min: "-inf", max: "+inf")
//            
//            multi.zadd(self.key3, tuples: (1, "a"), (2, "b"), (3, "c"), (4, "d"), (5, "e"), (6, "f"), (7, "g"))
//            multi.zremrangebyscore(self.key3, min: "-inf", max: "(4")
//            multi.zcount(self.key3, min: "-inf", max: "+inf")
//            
//            multi.exec() {(response: RedisResponse) in
//                if let nestedResponses = self.baseAsserts(response: response, count: 10){
//                    XCTAssertEqual(nestedResponses[0], RedisResponse.IntegerValue(7), "Added only \(nestedResponses[0]) not 7")
//                    XCTAssertEqual(nestedResponses[1], RedisResponse.IntegerValue(7), "There were only \(nestedResponses[1]) in \(self.key1)")
//                    XCTAssertEqual(nestedResponses[2], RedisResponse.IntegerValue(5), "Returned \(nestedResponses[2]) not 5")
//                    XCTAssertEqual(nestedResponses[3], RedisResponse.IntegerValue(5), "Removed \(nestedResponses[3]) not 5")
//                    
//                    XCTAssertEqual(nestedResponses[4], RedisResponse.IntegerValue(7), "Added only \(nestedResponses[4]) not 7")
//                    XCTAssertEqual(nestedResponses[5], RedisResponse.IntegerValue(3), "Removed \(nestedResponses[5]) not 3")
//                    XCTAssertEqual(nestedResponses[6], RedisResponse.IntegerValue(4), "There are \(nestedResponses[6]) not 4 in \(self.key2)")
//                    
//                    XCTAssertEqual(nestedResponses[7], RedisResponse.IntegerValue(7), "Added only \(nestedResponses[7]) not 7")
//                    XCTAssertEqual(nestedResponses[8], RedisResponse.IntegerValue(3), "Removed \(nestedResponses[5]) not 3")
//                    XCTAssertEqual(nestedResponses[9], RedisResponse.IntegerValue(4), "There are \(nestedResponses[6]) not 4 in \(self.key2)")
//                }
//            }
//        }
//    }
    
    
}
