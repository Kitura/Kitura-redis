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

public class TestGeoCommands: XCTestCase {
    static var allTests: [(String, (TestGeoCommands) -> () throws -> Void)] {
        return [
            ("test_geoaddNew", test_geoaddNew),
            ("test_geoaddExisting", test_geoaddExisting),
            ("test_geohash", test_geohash),
            ("test_geopos", test_geopos),
            ("test_geoposNonExisting", test_geoposNonExisting),
            ("test_geodist", test_geodist),
            ("test_geodistM", test_geodistM),
            ("test_geodistKM", test_geodistKM),
            ("test_geodistMI", test_geodistMI),
            ("test_geodistFT", test_geodistFT),
            ("test_geodistBadElements", test_geodistBadElements)
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
                XCTFail("\(err)")
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
    
    func test_geoaddNew() {
        setup(major: 3, minor: 2, micro: 0) { 
            exp = expectation(description: "Add geospatial items to `key`.")
            
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 1)
                exp?.fulfill()
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_geoaddExisting() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Adding existing element to `key` should return 0.")
            
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 1)
                
                redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res, 0)
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_geohash() {
        setup(major: 3, minor: 2, micro: 0) { 
            exp = expectation(description: "Return Geohash for element.")
            
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 1)
                
                redis.geohash(key: key, members: member1, callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?[0]?.asString, "sqc8b49rny0")
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_geopos() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return position for element.")
            
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 1)
                
                redis.geopos(key: key, members: member1, callback: { (res, err) in
                    XCTAssertNil(err)
                    
                    let res0 = res?[0]?.asArray
                    XCTAssertEqual(res0?[0].asString, RedisString("13.36138933897018433"))
                    XCTAssertEqual(res0?[1].asString, RedisString("38.11555639549629859"))
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }

    func test_geoposNonExisting() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return NULL for non existing element.")
            
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 1)
                
                redis.geopos(key: key, members: "nonexisting", callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?[0], RedisResponse.Nil)
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_geodist() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return the distance between two members in the geospatial index using default unit (m).")
            
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 2)
                
                redis.geodist(key: key, member1: member1, member2: member2, callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?.asDouble, 166274.1516)
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_geodistM() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return the distance between two members in the geospatial index in meters.")
            
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 2)
                
                redis.geodist(key: key, member1: member1, member2: member2, unit: .m, callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?.asDouble, 166274.1516)
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_geodistKM() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return the distance between two members in the geospatial index in kilometers.")
            
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 2)
                
                redis.geodist(key: key, member1: member1, member2: member2, unit: .km, callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?.asDouble, 166.2742)
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }

    func test_geodistMI() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return the distance between two members in the geospatial index in miles.")
            
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 2)
                
                redis.geodist(key: key, member1: member1, member2: member2, unit: .mi, callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?.asDouble, 103.3182)
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_geodistFT() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return the distance between two members in the geospatial index in feet.")
            
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 2)
                
                redis.geodist(key: key, member1: member1, member2: member2, unit: .ft, callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?.asDouble, 545518.8700)
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_geodistBadElements() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return NULL for bad elements.")
            
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 2)
                
                redis.geodist(key: key, member1: "Foo", member2: "Bar", callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res, nil)
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
}
