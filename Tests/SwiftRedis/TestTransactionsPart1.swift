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

public class TestTransactionsPart1: XCTestCase {
    static var allTests : [(String, TestTransactionsPart1 -> () throws -> Void)] {
        return [
            ("testSetPlusGetAndDel", testSetPlusGetAndDel),
            ("testBinarySafeSetAndGet", testBinarySafeSetAndGet),
            ("testSetExistsOptions", testSetExistsOptions),
            ("testSetExpirationOption", testSetExpirationOption),
            ("testIncrDecr", testIncrDecr),
            ("testConnectionCommands", testConnectionCommands)
        ]
    }

    let key1 = "test1"
    let key2 = "test2"
    let expVal1 = "Testing, 1 2 3"
    let expVal2 = "A testing we go, a testing we go"

    func testSetPlusGetAndDel() {
        setupTests() {
            let multi = redis.multi()
            multi.set(self.key1, value: self.expVal1).getSet(self.key1, value: self.expVal2)
            multi.get(self.key1).del(self.key1).get(self.key1)
            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 5)  {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.Status("OK"), "Set didn't return an 'OK'")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.StringValue(RedisString(self.expVal1)), "getSet didn't return '\(self.expVal1), returned \(nestedResponses[1])")
                    XCTAssertEqual(nestedResponses[2], RedisResponse.StringValue(RedisString(self.expVal2)), "get didn't return '\(self.expVal2), returned \(nestedResponses[2])")
                    XCTAssertEqual(nestedResponses[3], RedisResponse.IntegerValue(1), "del didn't return 1, returned \(nestedResponses[3])")
                    XCTAssertEqual(nestedResponses[4], RedisResponse.Nil, "\(self.key1) shouldn't exist anymore")
                }
            }
        }
    }

    func testBinarySafeSetAndGet() {
        setupTests() {
            var bytes: [UInt8] = [0xff, 0x00, 0xfe, 0x02]
            let expData1 = RedisString(NSData(bytes: bytes, length: bytes.count))
            bytes = [0x00, 0x44, 0x88, 0xcc]
            let expData2 = RedisString(NSData(bytes: bytes, length: bytes.count))

            let multi = redis.multi()
            multi.set(self.key1, value: expData1).getSet(self.key1, value: expData2).get(self.key1)
            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 3)  {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.Status("OK"), "Set didn't return an 'OK'")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.StringValue(expData1), "getSet didn't return '\(expData1), returned \(nestedResponses[1])")
                    XCTAssertEqual(nestedResponses[2], RedisResponse.StringValue(expData2), "get didn't return '\(expData2), returned \(nestedResponses[2])")
                }
            }
        }
    }

    func testSetExistsOptions() {
        setupTests() {
            let multi = redis.multi()
            multi.set(self.key2, value: self.expVal1, exists: true).get(self.key2)
            multi.set(self.key2, value: self.expVal1, exists: false).get(self.key2)
            multi.set(self.key2, value: self.expVal2, exists: false)
            multi.del(self.key2)
            multi.set(self.key2, value: self.expVal2, exists: false).get(self.key2)
            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 8)  {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.Nil, "Shouldn't have set \(self.key2)")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.Nil, "\(self.key2) shouldn't exist")
                    XCTAssertEqual(nestedResponses[2], RedisResponse.Status("OK"), "Set didn't return an 'OK'")
                    XCTAssertEqual(nestedResponses[3], RedisResponse.StringValue(RedisString(self.expVal1)), "get didn't return '\(self.expVal1), returned \(nestedResponses[3])")
                    XCTAssertEqual(nestedResponses[4], RedisResponse.Nil, "\(self.key2) shouldn't have been set, it already exists")
                    XCTAssertEqual(nestedResponses[5], RedisResponse.IntegerValue(1), "Del didn't return a 1, returned \(nestedResponses[5])")
                    XCTAssertEqual(nestedResponses[6], RedisResponse.Status("OK"), "Set didn't return an 'OK'")
                    XCTAssertEqual(nestedResponses[7], RedisResponse.StringValue(RedisString(self.expVal2)), "getSet didn't return '\(self.expVal2), returned \(nestedResponses[7])")
                }
            }
        }
    }

    func testSetExpirationOption() {
        setupTests() {
            let multi = redis.multi()
            multi.set(self.key1, value: self.expVal1, expiresIn: 2.750).get(self.key1)
            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 2)  {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.Status("OK"), "Failed to set \(self.key1)")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.StringValue(RedisString(self.expVal1)), "get didn't return '\(self.expVal1), returned \(nestedResponses[1])")

                    usleep(3000000)

                    redis.get(self.key1) {(returnedValue: RedisString?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNil(returnedValue, "\(self.key1) shouldn't exist any more")
                    }
                }
            }
        }
    }

    func testIncrDecr() {
        setupTests() {
            let intValue = 101
            let intInc = 5
            let dblValue: Double = 84.75
            let fltInc: Float = 8.5

            let multi = redis.multi()
            multi.set(self.key1, value: String(intValue)).incr(self.key1, by: intInc).decr(self.key1)
            multi.set(self.key2, value: String(dblValue)).incr(self.key2, byFloat: fltInc)
            multi.get(self.key1).get(self.key2)
            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 7)  {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.Status("OK"), "Set of \(self.key1) didn't return an 'OK'")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.IntegerValue(Int64(intValue+intInc)), "After incr \(self.key1) wasn't equal to \(intValue+intInc), was \(nestedResponses[1])")
                    XCTAssertEqual(nestedResponses[2], RedisResponse.IntegerValue(Int64(intValue+intInc-1)), "After decr \(self.key1) wasn't equal to \(intValue+intInc-1), was \(nestedResponses[2])")
                    XCTAssertEqual(nestedResponses[3], RedisResponse.Status("OK"), "Set of \(self.key2) didn't return an 'OK'")
                    XCTAssertEqual(nestedResponses[4], RedisResponse.StringValue(RedisString(dblValue+Double(fltInc))), "After incr \(self.key2) wasn't equal to \(dblValue+Double(fltInc)), was \(nestedResponses[4])")
                }
            }
        }
    }

    func testConnectionCommands() {
        setupTests() {
            let multi = redis.multi()
            multi.set(self.key1, value: self.expVal1).select(1).get(self.key1)
            multi.set(self.key1, value: self.expVal2).select(0).get(self.key1)
            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 6)  {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.Status("OK"), "Set didn't return an 'OK'")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.Status("OK"), "Select(1) didn't return an 'OK'")
                    XCTAssertEqual(nestedResponses[2], RedisResponse.Nil, "\(self.key1) in DB 1 shouldn't have a value")
                    XCTAssertEqual(nestedResponses[3], RedisResponse.Status("OK"), "Set didn't return an 'OK'")
                    XCTAssertEqual(nestedResponses[4], RedisResponse.Status("OK"), "Select(0) didn't return an 'OK'")
                    XCTAssertEqual(nestedResponses[5], RedisResponse.StringValue(RedisString(self.expVal1)), "get didn't return '\(self.expVal2), returned \(nestedResponses[5])")
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

            redis.del(self.key1, self.key2) {(deleted: Int?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")

                redis.select(1) {(error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")

                    redis.del(self.key1, self.key2) {(deleted: Int?, error: NSError?) in
                        redis.select(0) {(error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")

                            callback()
                        }
                    }
                }
            }
        }
    }
}
