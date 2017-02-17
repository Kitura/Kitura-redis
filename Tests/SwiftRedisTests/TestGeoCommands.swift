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
            ("test_1", test_1),
            ("test_2", test_2),
            ("test_3", test_3),
            ("test_4", test_4)
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
        connectRedis() { (error: NSError?) in
            guard error == nil else {
                XCTFail("Could not connect to Redis")
                return
            }
            redis.del(key) { (deleted: Int?, error: NSError?) in
                guard error == nil else {
                    XCTFail("Could not reset database before test")
                    return
                }
                callback()
            }
        }
    }
    
    // GEOADD, GEODIST, GEOHASH
    func test_1() {
        setupTests {
            // GEOADD
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2), callback: { (result, error) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssertNotNil(result, "Result should not be nil.")
                XCTAssertEqual(result, 2, "Should return 2, not \(result).")
                
                // GEODIST
                redis.geodist(key: key, member1: member1, member2: member2, callback: { (result, error) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(result, "Result should not be nil.")
                    XCTAssertEqual(result?.asDouble, 166274.1516, "Should return 166274.1516, not \(result).")
                })
                
                redis.geodist(key: key, member1: member1, member2: member2, unit: "km", callback: { (result, error) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(result, "Result should not be nil.")
                    XCTAssertEqual(result?.asDouble, 166.2742, "Should return 166.2742, not \(result).")
                })
                
                redis.geodist(key: key, member1: member1, member2: member2, unit: "mi", callback: { (result, error) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(result, "Result should not be nil.")
                    XCTAssertEqual(result?.asDouble, 103.3182, "Should return 103.3182, not \(result).")
                })
                
                redis.geodist(key: key, member1: "Foo", member2: "Bar", callback: { (result, error) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNil(result, "Should return nil, not \(result).")
                })
                
                // GEOHASH
                redis.geohash(key: key, members: member1, member2, callback: { (result, error) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(result, "Result should not be nil.")
                    XCTAssertEqual(result?.count, 2, "Should return 2, not \(result?.count).")
                    
                    let result0 = result?[0]?.asString
                    let result1 = result?[1]?.asString
                    XCTAssertEqual(result0, "sqc8b49rny0", "Should return sqc8b49rny0, not \(result0).")
                    XCTAssertEqual(result1, "sqdtr74hyu0", "Should return sqdtr74hyu0, not \(result1).")

                })
            })
        }
    }
    
    // GEOPOS
    func test_2() {
        setupTests {
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2), callback: { (result, error) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssertNotNil(result, "Result should not be nil.")
                XCTAssertEqual(result, 2, "Should return 2, not \(result).")
                
                redis.geopos(key: key, members: member1, member2, "NonExisting", callback: { (result, error) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(result, "Result should not be nil.")
                    XCTAssertEqual(result?.count, 3, "Should return 3, not \(result?.count).")
                    
                    let result0 = result?[0] as? [RedisResponse]
                    let result00 = result0?[0].asString
                    let result01 = result0?[1].asString
                    XCTAssertEqual(result00, RedisString("13.36138933897018433"), "Should return 13.36138933897018433, not \(result00).")
                    XCTAssertEqual(result01, RedisString("38.11555639549629859"), "Should return 38.11555639549629859, not \(result01).")
                    
                    let result1 = result?[1] as? [RedisResponse]
                    let result10 = result1?[0].asString
                    let result11 = result1?[1].asString
                    XCTAssertEqual(result10, RedisString("15.08726745843887329"), "Should return 15.08726745843887329, not \(result10).")
                    XCTAssertEqual(result11, RedisString("37.50266842333162032"), "Should return 37.50266842333162032, not \(result11).")
                    
                    let result2 = result?[2]
                    XCTAssertNil(result2, "Should return nil, not \(result2).")
                })
                
            })
        }
    }
    
    // GEORADIUS
    func test_3() {
        setupTests {
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2), callback: { (result, error) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssertNotNil(result, "Result should not be nil.")
                XCTAssertEqual(result, 2, "Should return 2, not \(result).")
                
                redis.georadius(key: key, longitude: 15, latitude: 37, radius: 200, unit: "km", withDist: true, callback: { (result, error) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(result, "Result should not be nil.")
                    XCTAssertEqual(result?.count, 2, "Should return 3, not \(result?.count).")
                    
                    let result0 = result?[0] as? [RedisResponse]
                    let result00 = result0?[0].asString
                    let result01 = result0?[1].asString
                    XCTAssertEqual(result00, RedisString(member1), "Should return \(member1), not \(result00).")
                    XCTAssertEqual(result01, RedisString("190.4424"), "Should return 190.4424, not \(result01).")
                    
                    let result1 = result?[1] as? [RedisResponse]
                    let result10 = result1?[0].asString
                    let result11 = result1?[1].asString
                    XCTAssertEqual(result10, RedisString(member2), "Should return \(member2), not \(result10).")
                    XCTAssertEqual(result11, RedisString("56.4413"), "Should return 37.50266842333162032, not \(result11).")
                })
            
                redis.georadius(key: key, longitude: 15, latitude: 37, radius: 200, unit: "km", withCoord: true, callback: { (result, error) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(result, "Result should not be nil.")
                    XCTAssertEqual(result?.count, 2, "Should return 2, not \(result?.count).")
                    
                    let result0 = result?[0] as? [RedisResponse]
                    let result00 = result0?[0].asString
                    let result01 = result0?[1].asArray
                    let result010 = result01?[0].asString
                    let result011 = result01?[1].asString
                    XCTAssertEqual(result00, RedisString(member1), "Should return \(member1), not \(result00).")
                    XCTAssertEqual(result010, RedisString("13.36138933897018433"), "Should return 13.36138933897018433, not \(result010).")
                    XCTAssertEqual(result011, RedisString("38.11555639549629859"), "Should return 38.11555639549629859, not \(result011).")
                    
                    let result1 = result?[1] as? [RedisResponse]
                    let result10 = result1?[0].asString
                    let result11 = result1?[1].asArray
                    let result110 = result11?[0].asString
                    let result111 = result11?[1].asString
                    XCTAssertEqual(result10, RedisString(member2), "Should return \(member2), not \(result10).")
                    XCTAssertEqual(result110, RedisString("15.08726745843887329"), "Should return 15.08726745843887329, not \(result110).")
                    XCTAssertEqual(result111, RedisString("37.50266842333162032"), "Should return 37.50266842333162032, not \(result111).")
                })
                
                redis.georadius(key: key, longitude: 15, latitude: 37, radius: 200, unit: "km", withCoord: true, withDist: true, callback: { (result, error) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(result, "Result should not be nil.")
                    XCTAssertEqual(result?.count, 2, "Should return 2, not \(result?.count).")

                    let result0 = result?[0] as? [RedisResponse]
                    let result00 = result0?[0].asString
                    let result01 = result0?[1].asString
                    let result02 = result0?[2].asArray
                    let result020 = result02?[0].asString
                    let result021 = result02?[1].asString
                    XCTAssertEqual(result00, RedisString(member1), "Should return \(member1), not \(result00).")
                    XCTAssertEqual(result01, RedisString(190.4424), "Should return \(190.4424), not \(result01).")
                    XCTAssertEqual(result020, RedisString("13.36138933897018433"), "Should return 13.36138933897018433, not \(result020).")
                    XCTAssertEqual(result021, RedisString("38.11555639549629859"), "Should return 38.11555639549629859, not \(result021).")
                    
                    let result1 = result?[1] as? [RedisResponse]
                    let result10 = result1?[0].asString
                    let result11 = result1?[1].asString
                    let result12 = result1?[2].asArray
                    let result120 = result12?[0].asString
                    let result121 = result12?[1].asString
                    XCTAssertEqual(result10, RedisString(member2), "Should return \(member2), not \(result10).")
                    XCTAssertEqual(result11, RedisString(56.4413), "Should return \(56.4413), not \(result11).")
                    XCTAssertEqual(result120, RedisString("15.08726745843887329"), "Should return 15.08726745843887329, not \(result120).")
                    XCTAssertEqual(result121, RedisString("37.50266842333162032"), "Should return 37.50266842333162032, not \(result121).")
                })
            })
        }
    }
    
    // GEORADIUSBYMEMBER
    func test_4() {
        setupTests {
            redis.geoadd(key: key, geospatialItems: (longitude1, latitude1, member1), (longitude2, latitude2, member2), (13.583333, 37.316667, "Agrigento"), callback: { (result, error) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssertNotNil(result, "Result should not be nil.")
                XCTAssertEqual(result, 3, "Should return 3, not \(result).")
                
                redis.georadiusbymember(key: key, member: "Agrigento", radius: 100, unit: "km", callback: { (result, error) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(result, "Result should not be nil.")
                    XCTAssertEqual(result?.count, 2, "Should return 2, not \(result?.count).")
                    
                    let result0 = (result?[0] as? RedisString)?.asString
                    let result1 = (result?[1] as? RedisString)?.asString
                    XCTAssertEqual(result0, "Agrigento", "Should return Agrigento, not \(result0).")
                    XCTAssertEqual(result1, "Palermo", "Should return Palermo, not \(result1).")
                })
            })
        }
    }
}
