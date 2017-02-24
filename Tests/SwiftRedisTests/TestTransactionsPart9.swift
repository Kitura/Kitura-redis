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

// Test GEO transaction operations
public class TestTransactionsPart9: XCTestCase {
    static var allTests: [(String, (TestTransactionsPart9) -> () throws -> Void)] {
        return [
            ("test_geoadd", test_geoadd),
            ("test_geohash", test_geohash),
            ("test_geopos", test_geopos),
            ("test_geodist", test_geodist),
            ("test_georadius", test_georadius),
            ("test_georadiusbymember", test_georadiusbymember)
        ]
    }
    
    var exp: XCTestExpectation?
    
    let key = "Sicily"
    
    let longitude1 = 13.361389
    let latitude1 = 38.115556
    let member1 = "Palermo"
    
    let longitude2 = 15.087269
    let latitude2 = 37.502669
    let member2 = "Catania"
    
    private func setup(major: Int, minor: Int, micro: Int, callback: () -> Void) {
        connectRedis() {(err) in
            guard err == nil else {
                XCTFail()
                return
            }
            redis.info { (info: RedisInfo?, _) in
                if let info = info, info.server.checkVersionCompatible(major: major, minor: minor, micro: micro) {
                    redis.flushdb(callback: { (_, _) in
                        callback()
                    })
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
    
    func test_geoadd() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Adds the specified geospatial items (latitude, longitude, name) to the specified `key`.")
            let multi = redis.multi()
            multi.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1))
            multi.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1))
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 2) {
                    XCTAssertEqual(responses[0].asInteger, 1)
                    XCTAssertEqual(responses[1].asInteger, 0)
                    self.exp?.fulfill()
                }
            })
        }
        waitForExpectations(timeout: 1) { (_) in }
    }
    
    func test_geohash() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return valid Geohash strings representing the position of one or more elements in a sorted set value representing a geospatial index (where elements were added using GEOADD).")
            let multi = redis.multi()
            multi.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1))
            multi.geohash(key: key, members: member1, member2)
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 2) {
                    XCTAssertEqual(responses[0].asInteger, 1)
                    XCTAssertEqual((responses[1].asArray)?[0].asString, RedisString("sqc8b49rny0"))
                    self.exp?.fulfill()
                }
            })
            waitForExpectations(timeout: 1) { (_) in }
        }
    }
    
    func test_geopos() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return the positions (longitude,latitude) of all the specified members of the geospatial index represented by the sorted set at `key`.")
            let multi = redis.multi()
            multi.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1))
            multi.geopos(key: key, members: member1)
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 2) {
                    XCTAssertEqual(responses[0].asInteger, 1)
                    XCTAssertEqual(((responses[1].asArray)?[0].asArray)?[0].asString, RedisString("13.36138933897018433"))
                    XCTAssertEqual(((responses[1].asArray)?[0].asArray)?[1].asString, RedisString("38.11555639549629859"))
                    self.exp?.fulfill()
                }
            })
            waitForExpectations(timeout: 1) { (_) in }
        }
    }
    
    func test_geodist() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return the distance between two members in the geospatial index represented by the sorted set.")
            let multi = redis.multi()
            multi.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2))
            multi.geodist(key: key, member1: member1, member2: member2, unit: .m)
            multi.geodist(key: key, member1: member1, member2: member2, unit: .km)
            multi.geodist(key: key, member1: member1, member2: member2, unit: .mi)
            multi.geodist(key: key, member1: member1, member2: member2, unit: .ft)
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 5) {
                    XCTAssertEqual(responses[0].asInteger, 2)
                    XCTAssertEqual(responses[1].asString, RedisString("166274.1516"))
                    XCTAssertEqual(responses[2].asString, RedisString("166.2742"))
                    XCTAssertEqual(responses[3].asString, RedisString("103.3182"))
                    XCTAssertEqual(responses[4].asString, RedisString("545518.8700"))
                    self.exp?.fulfill()
                }
            })
            waitForExpectations(timeout: 1) { (_) in }
        }
    }
    
    func test_georadius() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return the members of a sorted set populated with geospatial information using GEOADD, which are within the borders of the area specified with the center location and the maximum distance from the center (the radius).")
            let multi = redis.multi()
            multi.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1))
            multi.georadius(key: key, longitude: longitude1, latitude: latitude1, radius: 1, unit: .km)
            multi.georadius(key: key, longitude: longitude1, latitude: latitude1, radius: 1, unit: .mi)
            multi.georadius(key: key, longitude: longitude1, latitude: latitude1, radius: 1, unit: .ft)
            multi.georadius(key: key, longitude: longitude1, latitude: latitude1, radius: 1, unit: .m, withCoord: true)
            multi.georadius(key: key, longitude: longitude1, latitude: latitude1, radius: 1, unit: .m, withDist: true)
            multi.georadius(key: key, longitude: longitude1, latitude: latitude1, radius: 1, unit: .m, withHash: true)
            multi.georadius(key: key, longitude: longitude1, latitude: latitude1, radius: 1, unit: .m, count: 1)
            multi.georadius(key: key, longitude: longitude1, latitude: latitude1, radius: 1, unit: .m, ascending: true)
            multi.georadius(key: key, longitude: longitude1, latitude: latitude1, radius: 1, unit: .m, ascending: false)
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 10) {
                    XCTAssertEqual(responses[0].asInteger, 1)
                    XCTAssertEqual((responses[1].asArray)?[0].asString, RedisString(self.member1))
                    XCTAssertEqual((responses[2].asArray)?[0].asString, RedisString(self.member1))
                    XCTAssertEqual((responses[3].asArray)?[0].asString, RedisString(self.member1))
                    XCTAssertEqual(((responses[4].asArray)?[0].asArray)?[0].asString, RedisString(self.member1))
                    XCTAssertEqual(((responses[5].asArray)?[0].asArray)?[0].asString, RedisString(self.member1))
                    XCTAssertEqual(((responses[6].asArray)?[0].asArray)?[0].asString, RedisString(self.member1))
                    XCTAssertEqual((responses[7].asArray)?[0].asString, RedisString(self.member1))
                    XCTAssertEqual((responses[8].asArray)?[0].asString, RedisString(self.member1))
                    XCTAssertEqual((responses[9].asArray)?[0].asString, RedisString(self.member1))
                    self.exp?.fulfill()
                }
            })
            waitForExpectations(timeout: 1) { (_) in }
        }
    }
    
    func test_georadiusbymember() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "This command is exactly like GEORADIUS with the sole difference that instead of taking, as the center of the area to query, a longitude and latitude value, it takes the name of a member already existing inside the geospatial index represented by the sorted set.")
            let multi = redis.multi()
            multi.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1))
            multi.georadiusbymember(key: key, member: member1, radius: 1, unit: .km)
            multi.georadiusbymember(key: key, member: member1, radius: 1, unit: .mi)
            multi.georadiusbymember(key: key, member: member1, radius: 1, unit: .ft)
            multi.georadiusbymember(key: key, member: member1, radius: 1, unit: .m, withCoord: true)
            multi.georadiusbymember(key: key, member: member1, radius: 1, unit: .m, withDist: true)
            multi.georadiusbymember(key: key, member: member1, radius: 1, unit: .m, withHash: true)
            multi.georadiusbymember(key: key, member: member1, radius: 1, unit: .m, count: 1)
            multi.georadiusbymember(key: key, member: member1, radius: 1, unit: .m, ascending: true)
            multi.georadiusbymember(key: key, member: member1, radius: 1, unit: .m, ascending: false)
            multi.exec({ (res) in
                if let responses = self.baseAsserts(response: res, count: 10) {
                    XCTAssertEqual(responses[0].asInteger, 1)
                    XCTAssertEqual((responses[1].asArray)?[0].asString, RedisString(self.member1))
                    XCTAssertEqual((responses[2].asArray)?[0].asString, RedisString(self.member1))
                    XCTAssertEqual((responses[3].asArray)?[0].asString, RedisString(self.member1))
                    XCTAssertEqual(((responses[4].asArray)?[0].asArray)?[0].asString, RedisString(self.member1))
                    XCTAssertEqual(((responses[5].asArray)?[0].asArray)?[0].asString, RedisString(self.member1))
                    XCTAssertEqual(((responses[6].asArray)?[0].asArray)?[0].asString, RedisString(self.member1))
                    XCTAssertEqual((responses[7].asArray)?[0].asString, RedisString(self.member1))
                    XCTAssertEqual((responses[8].asArray)?[0].asString, RedisString(self.member1))
                    XCTAssertEqual((responses[9].asArray)?[0].asString, RedisString(self.member1))
                    self.exp?.fulfill()
                }
            })
            waitForExpectations(timeout: 1) { (_) in }
        }
    }
}
