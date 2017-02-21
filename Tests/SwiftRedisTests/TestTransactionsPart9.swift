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
            ("test_geoaddNew", test_geoaddNew),
            ("test_geoaddExisting", test_geoaddExisting),
            ("test_geohash", test_geohash),
            ("test_geopos", test_geopos),
            ("test_geoposNonExisting", test_geoposNonExisting),
            ("test_geodistDefault", test_geodistDefault),
            ("test_geodistKm", test_geodistKm),
            ("test_geodistMissingMembers", test_geodistMissingMembers),
            ("test_georadiusWithDist", test_georadiusWithDist),
            ("test_georadiusWithCoord", test_georadiusWithCoord),
            ("test_georadiusbymember", test_georadiusbymember)
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
        connectRedis() {(err: NSError?) in
            guard err == nil else {
                XCTFail("Could not connect to Redis.")
                return
            }
            redis.del(key, callback: { (res, err) in
                XCTAssertNil(err, "\(err != nil ? err!.localizedDescription : "")")
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
    
    func test_geoaddNew() {
        setup {
            let multi = redis.multi()
            multi.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2))
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 1) {
                    let res0 = responses[0].asInteger
                    XCTAssertEqual(res0, 2, "Should return 2 for the added elements, not \(res0).")
                }
            })
        }
    }
    
    func test_geoaddExisting() {
        setup {
            let multi = redis.multi()
            multi.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1))
            multi.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1))
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 2) {
                    let res1 = responses[1].asInteger
                    XCTAssertEqual(res1, 0, "Should return 0 because it didn't add a new element, not \(res1).")
                }
            })
        }
    }
    
    func test_geohash() {
        setup {
            let multi = redis.multi()
            multi.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2))
            multi.geohash(key: key, members: member1, member2)
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 2) {
                    let res = responses[1].asArray
                    let res0 = res?[0].asString
                    let hash1 = RedisString("sqc8b49rny0")
                    XCTAssertEqual(res0, hash1, "\(self.member1) hash should be \(hash1), not \(res0).")
                    let res1 = res?[1].asString
                    let hash2 = RedisString("sqdtr74hyu0")
                    XCTAssertEqual(res1, hash2, "\(self.member2) hash should be \(hash2), not \(res1).")
                }
            })
        }
    }
    
    func test_geopos() {
        setup {
            let multi = redis.multi()
            multi.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2))
            multi.geopos(key: key, members: member1, member2)
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 2) {
                    let res = responses[1].asArray
                    let res0 = res?[0].asArray
                    let res00 = res0?[0].asString
                    let longitude1 = RedisString("13.36138933897018433")
                    XCTAssertEqual(res00, longitude1, "\(self.member1) longitude should be \(longitude1), not \(res00).")
                    let res01 = res0?[1].asString
                    let latitude1 = RedisString("38.11555639549629859")
                    XCTAssertEqual(res01, latitude1, "\(self.member1) latitude should be \(latitude1), not \(res01).")
                    let res1 = res?[1].asArray
                    let res10 = res1?[0].asString
                    let longitude2 = RedisString("15.08726745843887329")
                    XCTAssertEqual(res10, longitude2, "\(self.member2) longitude should be \(longitude2), not \(res10).")
                    let res11 = res1?[1].asString
                    let latitude2 = RedisString("37.50266842333162032")
                    XCTAssertEqual(res11, latitude2, "\(self.member2) latitude should be \(latitude2), not \(res11).")
                }
            })
        }
    }
    
    func test_geoposNonExisting() {
        setup {
            let multi = redis.multi()
            multi.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2))
            multi.geopos(key: key, members: "NonExisting")
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 2) {
                    let res = responses[1].asArray
                    let res0 = res?[0]
                    XCTAssertEqual(res0, RedisResponse.Nil, "GEOPOS NonExisting should return nil, not \(res0).")
                }
            })
        }
    }
    
    func test_geodistDefault() {
        setup {
            let multi = redis.multi()
            multi.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2))
            multi.geodist(key: key, member1: member1, member2: member2)
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 2) {
                    let res = responses[1].asString
                    let dist = RedisString("166274.1516")
                    XCTAssertEqual(res, dist, "Distance should be \(dist), not \(res).")
                }
            })
        }
    }
    
    func test_geodistKm() {
        setup {
            let multi = redis.multi()
            multi.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2))
            multi.geodist(key: key, member1: member1, member2: member2, unit: "km")
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 2) {
                    let res = responses[1].asString
                    let dist = RedisString("166.2742")
                    XCTAssertEqual(res, dist, "Distance should be \(dist), not \(res).")
                }
            })
        }
    }
    
    func test_geodistMissingMembers() {
        setup {
            let multi = redis.multi()
            multi.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2))
            multi.geodist(key: key, member1: "Foo", member2: "Bar")
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 2) {
                    let res = responses[1]
                    XCTAssertEqual(res, RedisResponse.Nil, "Should return nil, not \(res).")
                }
            })
        }
    }
    
    func test_georadiusWithDist() {
        setup {
            let multi = redis.multi()
            multi.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2))
            multi.georadius(key: key, longitude: 15, latitude: 37, radius: 200, unit: "km", withDist: true)
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 2) {
                    let res1 = responses[1].asArray
                    let res10 = res1?[0].asArray
                    let res100 = res10?[0].asString
                    XCTAssertEqual(res100, RedisString(self.member1), "First location should be \(self.member1), not \(res100).")
                    let res101 = res10?[1].asString
                    let dist1 = RedisString("190.4424")
                    XCTAssertEqual(res101, dist1, "First location distance should be \(dist1), not \(res101).")
                    let res11 = res1?[1].asArray
                    let res110 = res11?[0].asString
                    XCTAssertEqual(res110, RedisString(self.member2), "Second location should be \(self.member2), not \(res110).")
                    let res111 = res11?[1].asString
                    let dist2 = RedisString("56.4413")
                    XCTAssertEqual(res111, dist2, "Second location distance should be \(dist2), not \(res111).")
                }
            })
        }
    }
    
    func test_georadiusWithCoord() {
        setup {
            let multi = redis.multi()
            multi.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2))
            multi.georadius(key: key, longitude: 15, latitude: 37, radius: 200, unit: "km", withCoord: true)
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 2) {
                    let res1 = responses[1].asArray
                    let res10 = res1?[0].asArray
                    let res100 = res10?[0].asString
                    XCTAssertEqual(res100, RedisString(self.member1), "First location should be \(self.member1), not \(res100).")
                    let res101 = res10?[1].asArray
                    let res1010 = res101?[0].asString
                    let longitude1 = RedisString("13.36138933897018433")
                    XCTAssertEqual(res1010, longitude1, "First location longitude should be \(longitude1), not \(res1010).")
                    let res1011 = res101?[1].asString
                    let latitude1 = RedisString("38.11555639549629859")
                    XCTAssertEqual(res1011, latitude1, "First location latitude should be \(latitude1), not \(res1011).")
                    let res11 = res1?[1].asArray
                    let res110 = res11?[0].asString
                    XCTAssertEqual(res110, RedisString(self.member2), "Second location should be \(self.member2), not \(res110).")
                    let res111 = res11?[1].asArray
                    let res1110 = res111?[0].asString
                    let longitude2 = RedisString("15.08726745843887329")
                    XCTAssertEqual(res1110, longitude2, "Second location longitude should be \(longitude2), not \(res1110).")
                    let res1111 = res111?[1].asString
                    let latitude2 = RedisString("37.50266842333162032")
                    XCTAssertEqual(res1111, latitude2, "Second location latitude should be \(latitude2), not \(res1111).")
                }
            })
        }
    }
    
    func test_georadiusbymember() {
        setup {
            let multi = redis.multi()
            multi.geoadd(key: key, geospatialItems: (13.583333, 37.316667, "Agrigento"))
            multi.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2))
            multi.georadiusbymember(key: key, member: "Agrigento", radius: 100, unit: "km")
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 3) {
                    let res2 = responses[2].asArray
                    let res20 = res2?[0].asString
                    XCTAssertEqual(res20, RedisString("Agrigento"), "First city should be Agrigento, not \(res20).")
                    let res21 = res2?[1].asString
                    XCTAssertEqual(res21, RedisString(self.member1), "Second city should be \(self.member1), not \(res21).")
                }
            })
        }
    }
}
