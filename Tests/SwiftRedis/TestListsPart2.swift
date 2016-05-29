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

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import Foundation
import XCTest


public class TestListsPart2: XCTestCase {
    static var allTests : [(String, TestListsPart2 -> () throws -> Void)] {
        return [
            ("test_lindexLinsertAndLlen", test_lindexLinsertAndLlen),
            ("test_binaryLindexLinsertAndLlen", test_binaryLindexLinsertAndLlen)
        ]
    }
    
    var key1: String { return "test1" }
    var key2: String { return "test2" }
    var key3: String { return "test3" }
    
    func localSetup(block: () -> Void) {
        connectRedis() {(error: NSError?) in
            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
        
            redis.del(self.key1, self.key2, self.key3) {(deleted: Int?, error: NSError?) in
                block()
            }
        }
    }
    
    func test_lindexLinsertAndLlen() {
        localSetup() {
            let value1 = "testing 1 2 3"
            let value2 = "over the hill and through the woods"
            let value3 = "to grandmothers house we go"
            
            redis.lpush(self.key1, values: value1, value3) {(numberSet: Int?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                
                redis.linsert(self.key1, before: true, pivot: value3, value: value2) {(listSize: Int?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(listSize, "Result of linsert was nil, but \(self.key1) should exist")
                    XCTAssertEqual(listSize!, 3, "Returned \(listSize!) for \(self.key1) instead of 3")
                    
                    redis.llen(self.key1) {(listSize: Int?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(listSize, "Result of llen was nil, but \(self.key1) should exist")
                        XCTAssertEqual(listSize!, 3, "Returned \(listSize!) for \(self.key1) instead of 3")
                        
                        redis.lindex(self.key1, index: 2) {(retrievedValue: RedisString?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertNotNil(retrievedValue, "Result of lindex was nil, but \(self.key1) should exist")
                            XCTAssertEqual(retrievedValue!, RedisString(value1), "Result of lindex was \(retrievedValue!). It should have been \(value1)")
                        }
                    }
                }
            }
        }
    }
    
    func test_binaryLindexLinsertAndLlen() {
        localSetup() {
            let binaryValue1 = RedisString("testing 1 2 3")
            let binaryValue2 = RedisString("over the hill and through the woods")
            let binaryValue3 = RedisString("to grandmothers house we go")
            
            redis.lpush(self.key1, values: binaryValue2, binaryValue1) {(numberSet: Int?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                
                redis.linsert(self.key1, before: false, pivot: binaryValue2, value: binaryValue3) {(listSize: Int?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(listSize, "Result of linsert was nil, but \(self.key1) should exist")
                    XCTAssertEqual(listSize!, 3, "Returned \(listSize!) for \(self.key1) instead of 3")
                    
                    redis.llen(self.key1) {(listSize: Int?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(listSize, "Result of llen was nil, but \(self.key1) should exist")
                        XCTAssertEqual(listSize!, 3, "Returned \(listSize!) for \(self.key1) instead of 3")
                        
                        redis.lindex(self.key1, index: 2) {(retrievedValue: RedisString?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertNotNil(retrievedValue, "Result of lindex was nil, but \(self.key1) should exist")
                            XCTAssertEqual(retrievedValue!, binaryValue3, "Result of lindex was \(retrievedValue!). It should have been \(binaryValue2)")
                        }
                    }
                }
            }
        }
    }
    
}
