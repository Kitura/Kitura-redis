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
    
    private func setup(callback: () -> Void) {
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
    
    func test_1() {
        setup {
            let multi = redis.multi()
            multi.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2))
            multi.geodist(key: key, member1: member1, member2: member2)
            multi.georadius(key: key, longitude: 15, latitude: 37, radius: 100, unit: "km")
            multi.georadius(key: key, longitude: 15, latitude: 37, radius: 200, unit: "km")
            multi.geohash(key: key, members: member1, member2)
            multi.geopos(key: key, members: member1, member2, "NonExisting")
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 6) {
                    let res0 = responses[0].asInteger
                    XCTAssertEqual(res0, 2, "GEOADD should return 2, not \(res0).")
                    
                    let res1 = responses[1].asString
                    XCTAssertEqual(res1, RedisString("166274.1516"), "GEODIST \(self.member1) \(self.member2) should return \"166274.1516\", not \(res1).")
                    
                    let res2 = responses[2].asArray
                    XCTAssertEqual(res2?.count, 1, "GEORADIUS should return array size 1, not \(res2?.count).")
                    XCTAssertEqual(res2?[0].asString, RedisString("Catania"), "GEORADIUS should return \"Catania\", not \(res2).")
                    
                    let res3 = responses[3].asArray
                    XCTAssertEqual(res3?.count, 2, "GEORADIUS should return array size 2, not \(res3?.count).")
                    let res30 = res3?[0].asString
                    XCTAssertEqual(res30, RedisString("Palermo"), "GEORADIUS should return \"Palermo\", not \(res30).")
                    let res31 = res3?[1].asString
                    XCTAssertEqual(res31, RedisString("Catania"), "GEORADIUS should return \"Catania\", not \(res31).")
                    
                    let res4 = responses[4].asArray
                    XCTAssertEqual(res4?.count, 2, "GEOHASH \(self.key) \(self.member1) \(self.member2) should return array size 2, not \(res4?.count).")
                    let res40 = res4?[0].asString
                    XCTAssertEqual(res40, RedisString("sqc8b49rny0"), "GEOHASH \(self.key) \(self.member1) \(self.member2) should return \"sqc8b49rny0\", not \(res40).")
                    let res41 = res4?[1].asString
                    XCTAssertEqual(res41, RedisString("sqdtr74hyu0"), "GEOHASH \(self.key) \(self.member1) \(self.member2) should return \"sqdtr74hyu0\", not \(res41).")
                    
                    let res5 = responses[5].asArray
                    XCTAssertEqual(res5?.count, 3, "GEOPOS should return array size 3, not \(res5?.count).")
                    let res50 = res5?[0].asArray
                    XCTAssertEqual(res50?.count, 2, "GEOPOS should return array size 2, not \(res50?.count).")
                    let res500 = res50?[0].asString
                    XCTAssertEqual(res500, RedisString("13.36138933897018433"), "GEOPOS should return \"13.36138933897018433\", not \(res500).")
                    let res501 = res50?[1].asString
                    XCTAssertEqual(res501, RedisString("38.11555639549629859"), "GEOPOS should return \"38.11555639549629859\", not \(res501).")
                    let res51 = res5?[1].asArray
                    XCTAssertEqual(res51?.count, 2, "GEOPOS should return array size 2, not \(res51?.count).")
                    let res510 = res51?[0].asString
                    XCTAssertEqual(res510, RedisString("15.08726745843887329"), "GEOPOS should return \"15.08726745843887329\", not \(res510).")
                    let res511 = res51?[1].asString
                    XCTAssertEqual(res511, RedisString("37.50266842333162032"), "GEOPOS should return \"37.50266842333162032\", not \(res511).")
                    let res52 = res5?[2]
                    XCTAssertEqual(res52, RedisResponse.Nil, "GEOPOS should return nil, not \(res52).")
                }
            })
        }
    }
    
    func test_2() {
        setup {
            let multi = redis.multi()
            multi.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2))
            multi.georadius(key: key, longitude: 15, latitude: 37, radius: 200, unit: "km", withDist: true)
            multi.georadius(key: key, longitude: 15, latitude: 37, radius: 200, unit: "km", withCoord: true)
            multi.georadius(key: key, longitude: 15, latitude: 37, radius: 200, unit: "km", withCoord: true, withDist: true)
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 4) {
                    let res1 = responses[1].asArray
                    XCTAssertEqual(res1?.count, 2, "First GEORADIUS resopnse array should be size 2, not \(res1?.count).")
                    let res10 = res1?[0].asArray
                    XCTAssertEqual(res10?.count, 2, "First GEORADIUS first array within response array should be size 2, not \(res10?.count).")
                    let res100 = res10?[0].asString
                    XCTAssertEqual(res100, RedisString(self.member1), "First GEORADIUS first location should be \(self.member1), not \(res100).")
                    let res101 = res10?[1].asString
                    XCTAssertEqual(res101, RedisString("190.4424"), "First GEORADIUS first location distance should be 190.4424, not \(res101).")
                    let res11 = res1?[1].asArray
                    XCTAssertEqual(res11?.count, 2, "First GEORADIUS second array within response array should be size 2, not \(res11?.count).")
                    let res110 = res11?[0].asString
                    XCTAssertEqual(res110, RedisString(self.member2), "First GEORADIUS second location should be \(self.member2), not \(res110).")
                    let res111 = res11?[1].asString
                    XCTAssertEqual(res111, RedisString("56.4413"), "First GEORADIUS second location distance should be 56.4413, not \(res111).")
                }
            })
        }
    }
}
