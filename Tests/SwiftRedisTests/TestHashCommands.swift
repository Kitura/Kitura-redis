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

public class TestHashCommands: XCTestCase {
    static var allTests: [(String, (TestHashCommands) -> () throws -> Void)] {
        return [
            ("test_hashSetAndGet", test_hashSetAndGet),
            ("test_Incr", test_Incr),
            ("test_bulkCommands", test_bulkCommands),
            ("test_binarySafeHsetAndHmset", test_binarySafeHsetAndHmset),
            ("test_hscan", test_hscan),
            ("test_hscanMatch", test_hscanMatch),
            ("test_hscanCount", test_hscanCount),
            ("test_hscanMatchCount", test_hscanMatchCount)
        ]
    }

    var exp: XCTestExpectation?
    
    let key = "key"

    let field1 = "f1"
    let field2 = "f2"
    let field3 = "f3"
    let field4 = "f4"
    
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
    
    func test_hashSetAndGet() {
        setup(major: 2, minor: 0, micro: 0) {
            let expVal1 = "testing, testing, 1 2 3"
            let expVal2 = "hi hi, hi ho, its off to test we go"

            redis.hset(self.key, field: self.field1, value: expVal1) {(newField: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssert(newField, "\(self.field1) wasn't a new field in \(self.key)")

                redis.hset(self.key, field: self.field1, value: expVal2) {(newField: Bool, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertFalse(newField, "\(self.field1) wasn't an existing field in \(self.key)")

                    redis.hget(self.key, field: self.field1) {(value: RedisString?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(value, "\(self.field1) in \(self.key) had no value")
                        XCTAssertEqual(value!.asString, expVal2, "The value of \(self.field1) in \(self.key) wasn't '\(expVal2)'")

                        redis.hexists(self.key, field: self.field2) {(exists: Bool, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertFalse(exists, "\(self.field2) isn't suppose to exist in \(self.key)")

                            redis.hset(self.key, field: self.field2, value: expVal1) {(newField: Bool, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssert(newField, "\(self.field2) wasn't a new field in \(self.key)")

                                redis.hlen(self.key) {(count: Int?, error: NSError?) in
                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                    XCTAssertNotNil(count, "Count value shouldn't be nil")
                                    XCTAssertEqual(count!, 2, "There should be two fields in \(self.key)")

                                    redis.hset(self.key, field: self.field1, value: expVal2, exists: false) {(newField: Bool, error: NSError?) in
                                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                        XCTAssertFalse(newField, "\(self.field1) wasn't an existing field in \(self.key)")

                                        redis.hdel(self.key, fields: self.field1, self.field2) {(deleted: Int?, error: NSError?) in
                                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                            XCTAssertNotNil(deleted, "Deleted count value shouldn't be nil")
                                            XCTAssertEqual(deleted!, 2, "Two fields in \(self.key) should have been deleted")

                                            redis.hget(self.key, field: self.field1) {(value: RedisString?, error: NSError?) in
                                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                                XCTAssertNil(value, "\(self.field1) in \(self.key) should have no value")

                                                redis.hset(self.key, field: self.field1, value: expVal1, exists: false) {(newField: Bool, error: NSError?) in
                                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                                    XCTAssert(newField, "\(self.field1) wasn't a new field in \(self.key)")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func test_Incr() {
        setup(major: 3, minor: 2, micro: 0) {
            let incInt = 10
            let incFloat: Float = 8.5

            redis.hincr(self.key, field: self.field3, by: incInt) {(value: Int?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssertNotNil(value, "Value of field shouldn't be nil")
                XCTAssertEqual(value!, incInt, "Value of field should be \(incInt), was \(value!)")

                redis.hincr(self.key, field: self.field2, byFloat: incFloat) {(value: RedisString?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(value, "Value of field shouldn't be nil")
                    XCTAssertEqual(value!.asDouble, Double(incFloat), "Value of field should be \(incFloat), was \(value!.asDouble)")

                    redis.info() {
                        (info: RedisInfo?, error: NSError?) in

                        if let info = info {
                            if info.server.checkVersionCompatible(major: 3, minor: 2) {
                                let expVal1 = "testing, testing, 1 2 3"

                                redis.hset(self.key, field: self.field1, value: expVal1) {(newField: Bool, error: NSError?) in
                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                    XCTAssert(newField, "\(self.field1) wasn't a new field in \(self.key)")

                                    redis.hstrlen(self.key, field: self.field1) {(length: Int?, error: NSError?) in
                                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                        XCTAssertNotNil(length, "Length of field shouldn't be nil")
                                        XCTAssertEqual(length!, expVal1.characters.count, "Length of field should be \(expVal1.characters.count), was \(length!)")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func test_bulkCommands() {
        setup(major: 2, minor: 0, micro: 0) {
            let expVal1 = "Hi ho, hi ho"
            let expVal2 = "it's off to test"
            let expVal3 = "we go"

            redis.hmset(self.key, fieldValuePairs: (self.field1, expVal1), (self.field2, expVal2), (self.field3, expVal3)) {(wereSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssert(wereSet, "Fields 1,2,3 should have been set")

                redis.hget(self.key, field: self.field1) {(value: RedisString?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertEqual(value!.asString, expVal1, "\(self.key).\(self.field1) wasn't set to \(expVal1). Instead was \(String(describing: value))")

                    redis.hmget(self.key, fields: self.field1, self.field2, self.field4, self.field3) {(values: [RedisString?]?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(values, "Received a nil values array")
                        XCTAssertEqual(values!.count, 4, "Values array didn't have four elements. Had \(values!.count) elements")
                        XCTAssertNotNil(values![0], "Values array [0] was nil")
                        XCTAssertEqual(values![0]!.asString, expVal1, "Values array [0] wasn't equal to \(expVal1), was \(values![0]!)")
                        XCTAssertNotNil(values![1], "Values array [1] was nil")
                        XCTAssertEqual(values![1]!.asString, expVal2, "Values array [1] wasn't equal to \(expVal2), was \(values![1]!)")
                        XCTAssertNil(values![2], "Values array [2] wasn't nil. Was \(String(describing: values![2]))")
                        XCTAssertNotNil(values![3], "Values array [3] was nil")
                        XCTAssertEqual(values![3]!.asString, expVal3, "Values array [3] wasn't equal to \(expVal3), was \(values![3]!)")

                        redis.hkeys(self.key) {(fields: [String]?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertNotNil(fields, "Received a nil field names array")
                            XCTAssertEqual(fields!.count, 3, "Field names array didn't have three elements. Had \(fields!.count) elements")

                            redis.hvals(self.key) {(values: [RedisString?]?, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssertNotNil(values, "Received a nil values array")
                                XCTAssertEqual(values!.count, 3, "Values array didn't have three elements. Had \(values!.count) elements")

                                redis.hgetall(self.key) {(values: [String: RedisString], error: NSError?) in
                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                    XCTAssertEqual(values.count, 3, "There should have been 3 fields in \(self.key), there were \(values.count) fields")

                                    let fieldNames = [self.field1, self.field2, self.field3]
                                    let fieldValues = [expVal1, expVal2, expVal3]
                                    for idx in 0..<fieldNames.count {
                                        let field = values[fieldNames[idx]]
                                      
                                        XCTAssertNotNil(field, "\(fieldNames[idx]) in \(self.key) was nil")
                                        XCTAssertEqual(field!.asString, fieldValues[idx], "\(fieldNames[idx]) in \(self.key) wasn't '\(fieldValues[idx])', it was \(String(describing: field))")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func test_binarySafeHsetAndHmset() {
        setup(major: 2, minor: 0, micro: 0) {
            var bytes: [UInt8] = [0xff, 0x00, 0xfe, 0x02]
            let expData1 = Data(bytes: bytes, count: bytes.count)

            redis.hset(self.key, field: self.field1, value: RedisString(expData1)) {(wasSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssert(wasSet, "\(self.key).\(self.field1) wasn't set")

                bytes = [0x00, 0x01, 0x02, 0x03, 0x04]
                let expData2 = Data(bytes: bytes, count: bytes.count)
                bytes = [0xf0, 0xf1, 0xf2, 0xf3, 0xf4]
                let expData3 = Data(bytes: bytes, count: bytes.count)

                redis.hmset(self.key, fieldValuePairs: (self.field2, RedisString(expData2)), (self.field3, RedisString(expData3))) {(wereSet: Bool, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssert(wereSet, "\(self.key).\(self.field2)/\(self.field3) weren't set")

                    redis.hgetall(self.key) {(values: [String: RedisString], error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertEqual(values.count, 3, "There should have been 3 fields in \(self.key), there were \(values.count) fields")

                        let fieldNames = [self.field1, self.field2, self.field3]
                        let fieldValues = [expData1, expData2, expData3]
                        for idx in 0..<fieldNames.count {
                            let field = values[fieldNames[idx]]

                            XCTAssertNotNil(field, "\(fieldNames[idx]) in \(self.key) was nil")
                            XCTAssertEqual(field!.asData, fieldValues[idx], "\(fieldNames[idx]) in \(self.key) wasn't '\(fieldValues[idx])', it was \(String(describing: field))")
                        }
                    }
                }
            }
        }
    }

    func test_hscan() {
        setup(major: 2, minor: 8, micro: 0) {
            exp = expectation(description: "Iterate fields of Hash types and their associated values.")

            redis.hmset(key, fieldValuePairs: ("linkin park", "crawling"), ("incubus", "drive"), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssert(res)
                
                redis.hscan(key: key, cursor: 0, callback: { (newCursor, res, err) in
                    XCTAssertNil(err)
                    XCTAssertNotNil(newCursor)
                    XCTAssertEqual(res?.count, 4)
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1) { (_) in }
        }
    }
    
    func test_hscanMatch() {
        setup(major: 2, minor: 8, micro: 0) {
            exp = expectation(description: "Iterate fields of Hash types and their associated values that match a pattern.")

            redis.hmset(key, fieldValuePairs: ("linkin park", "crawling"), ("incubus", "drive"), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssert(res)
                
                redis.hscan(key: key, cursor: 0, match: "link*", callback: { (newCursor, res, err) in
                    XCTAssertNil(err)
                    XCTAssertNotNil(newCursor)
                    XCTAssertNotNil(res)
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1) { (_) in }
        }
    }

    func test_hscanCount() {
        setup(major: 2, minor: 8, micro: 0) {
            exp = expectation(description: "Iterate a certain number of fields of Hash types and their associated values.")

            redis.hmset(key, fieldValuePairs: ("linkin park", "crawling"), ("incubus", "drive"), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssert(res)
                
                redis.hscan(key: key, cursor: 0, count: 1, callback: { (newCursor, res, err) in
                    XCTAssertNil(err)
                    XCTAssertNotNil(newCursor)
                    XCTAssertNotNil(res)
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1) { (_) in }
        }
    }
    
    func test_hscanMatchCount() {
        setup(major: 2, minor: 8, micro: 0) {
            exp = expectation(description: "Iterate a certain number of fields of Hash types and their associated values that match a pattern.")

            redis.hmset(key, fieldValuePairs: ("linkin park", "crawling"), ("incubus", "drive"), callback: { (res, err) in
                XCTAssertNil(err)
                XCTAssert(res)
                redis.hscan(key: key, cursor: 0, match: "link*", count: 1, callback: { (newCursor, res, err) in
                    XCTAssertNil(err)
                    XCTAssertNotNil(newCursor)
                    XCTAssertNotNil(res)
                    exp?.fulfill()
                })
            })
            waitForExpectations(timeout: 1) { (_) in }
        }
    }
}
