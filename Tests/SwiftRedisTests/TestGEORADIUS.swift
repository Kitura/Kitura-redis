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

public class TestGEORADIUS: XCTestCase {
    static var allTests: [(String, (TestGEORADIUS) -> () throws -> Void)] {
        return [
            ("test_georadiusM", test_georadiusM),
            ("test_georadiusKM", test_georadiusKM),
            ("test_georadiusMI", test_georadiusMI),
            ("test_georadiusFT", test_georadiusFT),
            ("test_georadiusWITHCOORD", test_georadiusWITHCOORD),
            ("test_georadiusWITHDIST", test_georadiusWITHDIST),
            ("test_georadiusWITHHASH", test_georadiusWITHHASH),
            ("test_georadiusASC", test_georadiusASC),
            ("test_georadiusDESC", test_georadiusDESC),
            ("test_georadiusMultiCommands", test_georadiusMultiCommands)
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
    
    func test_georadiusM() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return the members within the borders of the area, measured in meters.")
            
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 1)
                
                redis.georadius(key: key, longitude: longitude1, latitude: latitude1, radius: 1, unit: .m, callback: { (res, err) in
                    XCTAssertNil(err)
                    let res0 = res?[0]?.asString
                    XCTAssertEqual(res0, RedisString(member1))
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_georadiusKM() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return the members within the borders of the area, measured in kilometers.")
            
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 1)
                
                redis.georadius(key: key, longitude: longitude1, latitude: latitude1, radius: 1, unit: .km, callback: { (res, err) in
                    XCTAssertNil(err)
                    let res0 = res?[0]?.asString
                    XCTAssertEqual(res0, RedisString(member1))
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_georadiusMI() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return the members within the borders of the area, measured in miles.")
            
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 1)
                
                redis.georadius(key: key, longitude: longitude1, latitude: latitude1, radius: 1, unit: .mi, callback: { (res, err) in
                    XCTAssertNil(err)
                    let res0 = res?[0]?.asString
                    XCTAssertEqual(res0, RedisString(member1))
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }    }
    
    func test_georadiusFT() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return the members within the borders of the area, measured in feet.")
            
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 1)
                
                redis.georadius(key: key, longitude: longitude1, latitude: latitude1, radius: 1, unit: .ft, callback: { (res, err) in
                    XCTAssertNil(err)
                    let res0 = res?[0]?.asString
                    XCTAssertEqual(res0, RedisString(member1))
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_georadiusWITHCOORD() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return the members within the borders of the area, with their coordinates.")
            
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 1)
                
                redis.georadius(key: key, longitude: 15, latitude: 37, radius: 200, unit: .km, withCoord: true, callback: { (res, err) in
                    XCTAssertNil(err)
                    let res0 = res?[0]?.asArray
                    let res00 = res0?[0].asString
                    XCTAssertEqual(res00, RedisString(member1))
                    let res01 = res0?[1].asArray
                    let res010 = res01?[0].asString
                    XCTAssertEqual(res010, RedisString("13.36138933897018433"))
                    let res011 = res01?[1].asString
                    XCTAssertEqual(res011, RedisString("38.11555639549629859"))
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_georadiusWITHDIST() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return the members within the borders of the area, and their distance from the center of the area.")
            
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 1)
                
                redis.georadius(key: key, longitude: 15, latitude: 37, radius: 200, unit: .km, withDist: true, callback: { (res, err) in
                    XCTAssertNil(err)
                    let res0 = res?[0]?.asArray
                    let res00 = res0?[0].asString
                    XCTAssertEqual(res00, RedisString(member1))
                    let res01 = res0?[1].asString
                    XCTAssertEqual(res01, RedisString("190.4424"))
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_georadiusWITHHASH() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return the raw geohash-encoded sorted set score of the item.")
            
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 1)
                
                redis.georadius(key: key, longitude: 15, latitude: 37, radius: 200, unit: .km, withHash: true, callback: { (res, err) in
                    XCTAssertNil(err)
                    let res0 = res?[0]?.asArray
                    let res00 = res0?[0].asString
                    XCTAssertEqual(res00, RedisString(member1))
                    let res01 = res0?[1].asInteger
                    XCTAssertEqual(res01, 3479099956230698)
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_georadiusASC() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return the members within the borders of the area, sorted nearest to farthest from center.")
            
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 2)
                
                redis.georadius(key: key, longitude: longitude1, latitude: latitude1, radius: 200, unit: .km, ascending: true, callback: { (res, err) in
                    XCTAssertNil(err)
                    let res0 = res?[0]?.asString
                    XCTAssertEqual(res0, RedisString(member1))
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_georadiusDESC() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return the members within the borders of the area, sorted farthest to nearest from center.")
            
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 2)
                
                redis.georadius(key: key, longitude: longitude1, latitude: latitude1, radius: 200, unit: .km, ascending: false, callback: { (res, err) in
                    XCTAssertNil(err)
                    let res0 = res?[0]?.asString
                    XCTAssertEqual(res0, RedisString(member2))
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
    
    func test_georadiusMultiCommands() {
        setup(major: 3, minor: 2, micro: 0) {
            exp = expectation(description: "Return the members within the borders of the area.")
            
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 2)
                
                redis.georadius(key: key, longitude: 15, latitude: 37, radius: 200, unit: .km, withCoord: true, withDist: true, withHash: true, count: 1, ascending: true, callback: { (res, err) in
                    XCTAssertNil(err)
                    
                    let res0 = res?[0]?.asArray
                    let res00 = res0?[0].asString
                    XCTAssertEqual(res00, RedisString(member2))
                    
                    let res01 = res0?[1].asString
                    XCTAssertEqual(res01, RedisString("56.4413"))
                    
                    let res02 = res0?[2].asInteger
                    XCTAssertEqual(res02, 3479447370796909)
                    
                    let res03 = res0?[3].asArray
                    let res030 = res03?[0].asString
                    XCTAssertEqual(res030?.asString, "15.08726745843887329")
                    
                    let res031 = res03?[1].asString
                    XCTAssertEqual(res031?.asString, "37.50266842333162032")
                    
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1, handler: { (_) in })
        }
    }
}
