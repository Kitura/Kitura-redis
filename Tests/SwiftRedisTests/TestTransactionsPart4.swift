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

public class TestTransactionsPart4: XCTestCase {
    static var allTests : [(String, (TestTransactionsPart4) -> () throws -> Void)] {
        return [
            ("test_hashSetAndGet", test_hashSetAndGet),
            ("test_Incr", test_Incr),
            ("test_bulkCommands", test_bulkCommands),
            ("test_binarySafeHsetAndHmset", test_binarySafeHsetAndHmset)
        ]
    }

    let key1 = "test1"

    let field1 = "f1"
    let field2 = "f2"
    let field3 = "f3"
    let field4 = "f4"

    func test_hashSetAndGet() {
        setupTests() {
            let expVal1 = "testing, testing, 1 2 3"
            let expVal2 = "hi hi, hi ho, its off to test we go"

            let multi = redis.multi()
            multi.hset(self.key1, field: self.field1, value: expVal1)
            multi.hset(self.key1, field: self.field1, value: expVal2).hget(self.key1, field: self.field1)
            multi.hexists(self.key1, field: self.field2).hset(self.key1, field: self.field2, value: expVal1)
            multi.hlen(self.key1).hset(self.key1, field: self.field1, value: expVal2, exists: false)
            multi.hdel(self.key1, fields: self.field1, self.field2).hget(self.key1, field: self.field1)
            multi.hset(self.key1, field: self.field1, value: expVal1, exists: false)

            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 10)  {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.IntegerValue(1), "\(self.field1) wasn't a new field in \(self.key1)")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.IntegerValue(0), "\(self.field1) wasn't an existing field in \(self.key1)")
                    XCTAssertEqual(nestedResponses[2], RedisResponse.StringValue(RedisString(expVal2)), "\(self.key1) should have been equal to \(expVal2). Was \(nestedResponses[2].asString?.asString)")
                    XCTAssertEqual(nestedResponses[3], RedisResponse.IntegerValue(0), "\(self.field2) isn't suppose to exist in \(self.key1)")
                    XCTAssertEqual(nestedResponses[4], RedisResponse.IntegerValue(1), "\(self.field2) wasn't a new field in \(self.key1)")
                    XCTAssertEqual(nestedResponses[5], RedisResponse.IntegerValue(2), "There should be two fields in \(self.key1)")
                    XCTAssertEqual(nestedResponses[6], RedisResponse.IntegerValue(0), "\(self.field1) wasn't an existing field in \(self.key1)")
                    XCTAssertEqual(nestedResponses[7], RedisResponse.IntegerValue(2), "Two fields in \(self.key1) should have been deleted")
                    XCTAssertEqual(nestedResponses[8], RedisResponse.Nil, "\(self.field1) in \(self.key1) should have no value")
                    XCTAssertEqual(nestedResponses[9], RedisResponse.IntegerValue(1), "\(self.field1) wasn't a new field in \(self.key1)")
                }
            }
        }
    }

    func test_Incr() {
        setupTests() {
            let incInt = 10
            let incFloat: Float = 8.5

            let multi = redis.multi()
            multi.hincr(self.key1, field: self.field3, by: incInt)
            multi.hincr(self.key1, field: self.field2, byFloat: incFloat)

            // To test HSTRLEN one needs a Redis 3.2 server
            //
            //let expVal1 = "testing, testing, 1 2 3"
            //multi.hset(self.key1, field: self.field1, value: expVal1).hstrlen(self.key1, field: self.field1)

            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 2  /* Should be 4 if testing hstrlen */ )  {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.IntegerValue(Int64(incInt)), "Value of the field should be \(incInt), was \(nestedResponses[0].asInteger)")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.StringValue(RedisString(String(incFloat))), "Value of the field should be \(incFloat). Was \(nestedResponses[1].asString?.asString)")

                    // To test HSTRLEN one needs a Redis 3.2 server
                    //
                    //XCTAssertEqual(nestedResponses[2], RedisResponse.IntegerValue(1), "\(self.field1) wasn't a new field in \(self.key1)")
                    //XCTAssertEqual(nestedResponses[3], RedisResponse.IntegerValue(expVal1.characters.count), "Length of field should be \(expVal1.characters.count), was \(nestedResponses[3].asInteger)")
                }
            }
        }
    }

    func test_bulkCommands() {
        setupTests() {
            let expVal1 = "Hi ho, hi ho"
            let expVal2 = "it's off to test"
            let expVal3 = "we go"

            let multi = redis.multi()
            multi.hmset(self.key1, fieldValuePairs: (self.field1, expVal1), (self.field2, expVal2), (self.field3, expVal3))
            multi.hget(self.key1, field: self.field1)
            multi.hmget(self.key1, fields: self.field1, self.field2, self.field4, self.field3)
            multi.hkeys(self.key1).hvals(self.key1).hgetall(self.key1)

            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 6)  {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.Status("OK"), "Fields 1,2,3 should have been set")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.StringValue(RedisString(expVal1)), "\(self.key1).\(self.field1) wasn't set to \(expVal1). Was \(nestedResponses[1].asString?.asString)")
                    let innerResponses = nestedResponses[2].asArray!
                    XCTAssertEqual(innerResponses.count, 4, "Values array didn't have four elements. Had \(innerResponses.count) elements")
                    XCTAssertEqual(innerResponses[0].asString!.asString, expVal1, "Values array [0] wasn't equal to \(expVal1), was \(innerResponses[0].asString!.asString)")
                    XCTAssertEqual(innerResponses[1].asString!.asString, expVal2, "Values array [1] wasn't equal to \(expVal2), was \(innerResponses[1].asString!.asString)")
                    XCTAssertEqual(innerResponses[2], RedisResponse.Nil, "Values array [2] wasn't nil. Was \(innerResponses[2])")
                    XCTAssertEqual(innerResponses[3].asString!.asString, expVal3, "Values array [3] wasn't equal to \(expVal3), was \(innerResponses[3].asString!.asString)")
                    XCTAssertEqual(nestedResponses[3].asArray!.count, 3, "Field names array didn't have three elements. Had \(nestedResponses[3].asArray!.count) elements")
                    XCTAssertEqual(nestedResponses[4].asArray!.count, 3, "Values array didn't have three elements. Had \(nestedResponses[4].asArray!.count) elements")
                    XCTAssertEqual(nestedResponses[5].asArray!.count/2, 3, "There should have been 3 fields in \(self.key1), there were \(nestedResponses[5].asArray!.count/2) fields")
                }
            }
        }
    }

    func test_binarySafeHsetAndHmset() {
        setupTests() {
            var bytes: [UInt8] = [0xff, 0x00, 0xfe, 0x02]
            let expData1 = Data(bytes: bytes, count: bytes.count)
            bytes = [0x00, 0x01, 0x02, 0x03, 0x04]
            let expData2 = Data(bytes: bytes, count: bytes.count)
            bytes = [0xf0, 0xf1, 0xf2, 0xf3, 0xf4]
            let expData3 = Data(bytes: bytes, count: bytes.count)

            let multi = redis.multi()
            multi.hset(self.key1, field: self.field1, value: RedisString(expData1))
            multi.hmset(self.key1, fieldValuePairs: (self.field2, RedisString(expData2)), (self.field3, RedisString(expData3)))
            multi.hgetall(self.key1)

            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 3)  {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.IntegerValue(1), "\(self.field1) wasn't a new field in \(self.key1)")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.Status("OK"), "Fields 1,2,3 should have been set")
                    let innerResponses = nestedResponses[2].asArray!
                    XCTAssertEqual(innerResponses.count/2, 3, "There should have been 3 fields in \(self.key1), there were \(innerResponses.count/2) fields")
                    let valuesMap = [self.field1:expData1, self.field2:expData2, self.field3:expData3]
                    for idx in stride(from: 0, to: innerResponses.count-1, by:2) {
                        XCTAssertNotNil(valuesMap[innerResponses[idx].asString!.asString], "Unknown field \(innerResponses[idx].asString!.asString)")
                        XCTAssertEqual(valuesMap[innerResponses[idx].asString!.asString], innerResponses[idx+1].asString!.asData, "Value of \(innerResponses[idx].asString!.asData) wasn't '\(valuesMap[innerResponses[idx].asString!.asString])'. It was '\(innerResponses[idx+1].asString!.asData)'")
                    }
                }
            }
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

    private func setupTests(callback: () -> Void) {
        connectRedis() {(error: NSError?) in
            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")

            redis.del(self.key1) {(deleted: Int?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")

                callback()
            }
        }
    }
}
