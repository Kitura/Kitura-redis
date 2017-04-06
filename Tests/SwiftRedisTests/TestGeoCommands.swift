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

import XCTest
import SwiftRedis

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
    
    let key = "Sicily"
    
    let longitude1 = 13.361389
    let latitude1 = 38.115556
    let member1 = "Palermo"
    
    let longitude2 = 15.087269
    let latitude2 = 37.502669
    let member2 = "Catania"
    
    func test_geoaddNew() {
        setup(major: 3, minor: 2, micro: 0) {
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 1)
            })
        }
    }
    
    func test_geoaddExisting() {
        setup(major: 3, minor: 2, micro: 0) {
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 1)
                
                redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res, 0)
                })
            })
        }
    }
    
    func test_geohash() {
        setup(major: 3, minor: 2, micro: 0) {
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 1)
                
                redis.geohash(key: key, members: member1, callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?[0]?.asString, "sqc8b49rny0")
                    
                })
            })
        }
    }
    
    func test_geopos() {
        setup(major: 3, minor: 2, micro: 0) {
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 1)
                
                redis.geopos(key: key, members: member1, callback: { (res, err) in
                    XCTAssertNil(err)
                    
                    let res0 = res?[0]
                    XCTAssertEqual(res0?.0, 13.361389338970184)
                    XCTAssertEqual(res0?.1, 38.115556395496298)
                    
                })
            })
        }
    }
    
    func test_geoposNonExisting() {
        setup(major: 3, minor: 2, micro: 0) {
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 1)
                
                redis.geopos(key: key, members: "nonexisting", callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertNil(res?[0])
                    
                })
            })
        }
    }
    
    func test_geoposMixed() {
        setup(major: 3, minor: 2, micro: 0) {
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 1)
                
                redis.geopos(key: key, members: member1, "nonexisting", callback: { (res, err) in
                    XCTAssertNil(err)
                    
                    let res0 = res?[0]
                    XCTAssertEqual(res0?.0, 13.361389338970184)
                    XCTAssertEqual(res0?.1, 38.115556395496298)
                    
                    let res1 = res?[1]
                    XCTAssertNil(res1)
                    
                })
            })
        }
    }
    
    func test_geodist() {
        setup(major: 3, minor: 2, micro: 0) {
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 2)
                
                redis.geodist(key: key, member1: member1, member2: member2, callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?.asDouble, 166274.1516)
                    
                })
            })
        }
    }
    
    func test_geodistM() {
        setup(major: 3, minor: 2, micro: 0) {
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 2)
                
                redis.geodist(key: key, member1: member1, member2: member2, unit: .m, callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?.asDouble, 166274.1516)
                    
                })
            })
        }
    }
    
    func test_geodistKM() {
        setup(major: 3, minor: 2, micro: 0) {
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 2)
                
                redis.geodist(key: key, member1: member1, member2: member2, unit: .km, callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?.asDouble, 166.2742)
                    
                })
            })
        }
    }
    
    func test_geodistMI() {
        setup(major: 3, minor: 2, micro: 0) {
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 2)
                
                redis.geodist(key: key, member1: member1, member2: member2, unit: .mi, callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?.asDouble, 103.3182)
                    
                })
            })
        }
    }
    
    func test_geodistFT() {
        setup(major: 3, minor: 2, micro: 0) {
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 2)
                
                redis.geodist(key: key, member1: member1, member2: member2, unit: .ft, callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res?.asDouble, 545518.8700)
                    
                })
            })
        }
    }
    
    func test_geodistBadElements() {
        setup(major: 3, minor: 2, micro: 0) {
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssertEqual(res, 2)
                
                redis.geodist(key: key, member1: "Foo", member2: "Bar", callback: { (res, err) in
                    XCTAssertNil(err)
                    XCTAssertEqual(res, nil)
                    
                })
            })
        }
    }
}
