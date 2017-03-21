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

public class TestTransactionsPart2: XCTestCase {
    static var allTests: [(String, (TestTransactionsPart2) -> () throws -> Void)] {
        return [
            ("test_msetAndMget", test_msetAndMget),
            ("test_binarySafeMsetAndMget", test_binarySafeMsetAndMget),
            ("test_StringManipulation", test_StringManipulation),
            ("test_bitPosAndCountCommands", test_bitPosAndCountCommands),
            ("test_bitSetAndGetCommands", test_bitSetAndGetCommands),
            ("test_bitOpCommands", test_bitOpCommands)
        ]
    }

    let key1 = "test1"
    let key2 = "test2"
    let key3 = "test3"
    let key4 = "test4"
    let expVal1 = "Testing, 1 2 3"
    let expVal2 = "A testing we go, a testing we go"
    let expVal3 = "Hi ho, hi ho"
    let expVal4 = "it's off to test"
    let updVal1 = ", 5 4"

    func test_msetAndMget() {
        setupTests() {
            let multi = redis.multi()
            multi.mset((self.key1, self.expVal1), (self.key2, self.expVal2)).get(self.key1)
            multi.mget(self.key1, self.key3, self.key2)
            multi.mset((self.key2, self.expVal2), (self.key3, self.expVal3), (self.key4, self.expVal4), exists: false)
            multi.del(self.key2)
            multi.mset((self.key2, self.expVal2), (self.key3, self.expVal3), (self.key4, self.expVal4), exists: false)
            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 6) {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.Status("OK"), "mset didn't return an 'OK'")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.StringValue(RedisString(self.expVal1)), "get didn't return '\(self.expVal1), returned \(nestedResponses[1])")
                    let innerResponses = nestedResponses[2].asArray
                    XCTAssertNotNil(innerResponses, "mget is suppose to return an Array of responses")
                    XCTAssertEqual(innerResponses!.count, 3, "There are suppose to be 3 inner responses, there were \(innerResponses!.count)")
                    XCTAssertEqual(innerResponses![0], RedisResponse.StringValue(RedisString(self.expVal1)), "mget (0) didn't return '\(self.expVal1), returned \(innerResponses![0])")
                    XCTAssertEqual(innerResponses![1], RedisResponse.Nil, "mget (0) didn't return nil, returned \(innerResponses![1])")
                    XCTAssertEqual(innerResponses![2], RedisResponse.StringValue(RedisString(self.expVal2)), "mget (2) didn't return '\(self.expVal2), returned \(innerResponses![2])")
                    XCTAssertEqual(nestedResponses[3], RedisResponse.IntegerValue(0), "mset somehow succeeded to set the keys.")
                    XCTAssertEqual(nestedResponses[4], RedisResponse.IntegerValue(1), "del didn't return 1, returned \(nestedResponses[3])")
                    XCTAssertEqual(nestedResponses[5], RedisResponse.IntegerValue(1), "mset should have succeeded to set the keys.")
                }
            }
        }
    }

    func test_binarySafeMsetAndMget() {
        setupTests() {
            var bytes: [UInt8] = [0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6]
            let expDat1 = Data(bytes: bytes, count: bytes.count)
            bytes = [0xb1, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6]
            let expDat2 = Data(bytes: bytes, count: bytes.count)
            bytes = [0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6]
            let expDat3 = Data(bytes: bytes, count: bytes.count)
            bytes = [0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6]
            let expDat4 = Data(bytes: bytes, count: bytes.count)

            let multi = redis.multi()
            multi.mset((self.key1, RedisString(expDat1)), (self.key2, RedisString(expDat2))).get(self.key1)
            multi.mget(self.key1, self.key3, self.key2)
            multi.mset((self.key2, RedisString(expDat2)), (self.key3, RedisString(expDat3)), (self.key4, RedisString(expDat4)), exists: false)
            multi.del(self.key2)
            multi.mset((self.key2, RedisString(expDat2)), (self.key3, RedisString(expDat3)), (self.key4, RedisString(expDat4)), exists: false)
            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 6) {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.Status("OK"), "mset didn't return an 'OK'")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.StringValue(RedisString(expDat1)), "get didn't return '\(expDat1), returned \(nestedResponses[1])")
                    let innerResponses = nestedResponses[2].asArray
                    XCTAssertNotNil(innerResponses, "mget is suppose to return an Array of responses")
                    XCTAssertEqual(innerResponses!.count, 3, "There are suppose to be 3 inner responses, there were \(innerResponses!.count)")
                    XCTAssertEqual(innerResponses![0], RedisResponse.StringValue(RedisString(expDat1)), "mget (0) didn't return '\(expDat1), returned \(innerResponses![0])")
                    XCTAssertEqual(innerResponses![1], RedisResponse.Nil, "mget (0) didn't return nil, returned \(innerResponses![1])")
                    XCTAssertEqual(innerResponses![2], RedisResponse.StringValue(RedisString(expDat2)), "mget (2) didn't return '\(expDat2), returned \(innerResponses![2])")
                    XCTAssertEqual(nestedResponses[3], RedisResponse.IntegerValue(0), "mset somehow succeeded to set the keys.")
                    XCTAssertEqual(nestedResponses[4], RedisResponse.IntegerValue(1), "del didn't return 1, returned \(nestedResponses[3])")
                    XCTAssertEqual(nestedResponses[5], RedisResponse.IntegerValue(1), "mset should have succeeded to set the keys.")
                }
            }

        }
    }

    func test_StringManipulation() {
        setupTests() {
            let multi = redis.multi()
            multi.set(self.key1, value: self.expVal1).append(self.key1, value: self.expVal2).strlen(self.key1)
            multi.getrange(self.key1, start: 7, end: 11).setrange(self.key1, offset: 7, value: self.updVal1)
            multi.get(self.key1)
            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 6) {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.Status("OK"), "set didn't return an 'OK'")
                    let updatedLength = Int64(self.expVal1.characters.count+self.expVal2.characters.count)
                    XCTAssertEqual(nestedResponses[1], RedisResponse.IntegerValue(updatedLength), "Length of updated \(self.key1) is incorrect")
                    XCTAssertEqual(nestedResponses[2], RedisResponse.IntegerValue(updatedLength), "Length of updated \(self.key1) is incorrect")
                    XCTAssertEqual(nestedResponses[3], RedisResponse.StringValue(RedisString(", 1 2")), "Get of getrange wasn't ', 1 2' was \(nestedResponses[3])")
                    XCTAssertEqual(nestedResponses[4], RedisResponse.IntegerValue(updatedLength), "Length of updated \(self.key1) is incorrect")
                    let updatedValue = "Testing, 5 4 3A testing we go, a testing we go"
                    XCTAssertEqual(nestedResponses[5], RedisResponse.StringValue(RedisString(updatedValue)), "Value of updated \(self.key1) isn't '\(updatedValue), returned \(String(describing: nestedResponses[5].asString?.asString))")
                }
            }
        }
    }

    func test_bitPosAndCountCommands() {
        setupTests() {
            let bytes: [UInt8] = [0x00, 0x01, 0x01, 0x00]
            let expVal1 = Data(bytes: bytes, count: bytes.count)

            let multi = redis.multi()
            multi.set(self.key1, value: RedisString(expVal1))
            multi.bitcount(self.key1).bitcount(self.key1, start: 2, end: 2)
            /* Removed tests of bitpos - not in Redis 2.8.0
            multi.bitpos(self.key1, bit: true).bitpos(self.key1, bit: true, start: 2)
            multi.bitpos(self.key1, bit: true, start: 1, end: 2)
            */
            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 3) {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.Status("OK"), "set didn't return an 'OK'")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.IntegerValue(2), "Bit count should have been 2, was \(String(describing: nestedResponses[4].asInteger))")
                    XCTAssertEqual(nestedResponses[2], RedisResponse.IntegerValue(1), "Bit count should have been 1, was \(String(describing: nestedResponses[5].asInteger))")
                    /* Removed tests of bitpos - not in Redis 2.8.0
                    XCTAssertEqual(nestedResponses[3], RedisResponse.IntegerValue(15), "Bit position should have been 15, was \(nestedResponses[1].asInteger)")
                    XCTAssertEqual(nestedResponses[4], RedisResponse.IntegerValue(23), "Bit position should have been 23, was \(nestedResponses[1].asInteger)")
                    XCTAssertEqual(nestedResponses[5], RedisResponse.IntegerValue(15), "Bit position should have been 15, was \(nestedResponses[3].asInteger)")
                    */
                }
            }
        }
    }

    func test_bitSetAndGetCommands() {
        setupTests() {
            var bytes: [UInt8] = [0x00, 0x01, 0x01, 0x00]
            let expVal1 = Data(bytes: bytes, count: bytes.count)

            let multi = redis.multi()
            multi.set(self.key1, value: RedisString(expVal1)).getbit(self.key1, offset: 14)
            multi.setbit(self.key1, offset: 13, value: true).get(self.key1)
            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 4) {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.Status("OK"), "set didn't return an 'OK'")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.IntegerValue(0), "The bit should have been a 0, it was \(String(describing: nestedResponses[1].asInteger))")
                    XCTAssertEqual(nestedResponses[2], RedisResponse.IntegerValue(0), "The bit should have been a 0, it was \(String(describing: nestedResponses[2].asInteger))")

                    bytes = [0x00, 0x05, 0x01, 0x00]
                    let newVal1 = Data(bytes: bytes, count: bytes.count)
                    XCTAssertEqual(nestedResponses[3].asString?.asData, newVal1, "The updated bit string had a value of '\(String(describing: nestedResponses[3].asString?.asData))'")
                }
            }
        }
    }

    func test_bitOpCommands() {
        setupTests() {
            var bytes: [UInt8] = [0x00, 0x01, 0x01, 0x04]
            let expVal1 = Data(bytes: bytes, count: bytes.count)
            bytes = [0x00, 0x08, 0x08, 0x04]
            let expVal2 = Data(bytes: bytes, count: bytes.count)

            let multi = redis.multi()
            multi.mset((self.key1, RedisString(expVal1)), (self.key2, RedisString(expVal2)))
            multi.bitop(self.key3, and: self.key1, self.key2).get(self.key3)
            multi.bitop(self.key3, or: self.key1, self.key2).get(self.key3)
            multi.bitop(self.key3, xor: self.key1, self.key2).get(self.key3)
            multi.bitop(self.key3, not: self.key1).get(self.key3)

            multi.exec() {(response: RedisResponse) in
                if  let nestedResponses = self.baseAsserts(response: response, count: 9) {
                    XCTAssertEqual(nestedResponses[0], RedisResponse.Status("OK"), "mset didn't return an 'OK'")
                    XCTAssertEqual(nestedResponses[1], RedisResponse.IntegerValue(4), "Destination field length should have been 4, it was \(String(describing: nestedResponses[1].asInteger))")
                    bytes = [0x00, 0x00, 0x00, 0x04]
                    var newValue = Data(bytes: bytes, count: bytes.count)
                    XCTAssertEqual(nestedResponses[2].asString?.asData, newValue, "\(self.key3) after an and had a value of '\(String(describing: nestedResponses[2].asString?.asData))'")
                    XCTAssertEqual(nestedResponses[3], RedisResponse.IntegerValue(4), "Destination field length should have been 4, it was \(String(describing: nestedResponses[3].asInteger))")
                    bytes = [0x00, 0x09, 0x09, 0x04]
                    newValue = Data(bytes: bytes, count: bytes.count)
                    XCTAssertEqual(nestedResponses[4].asString?.asData, newValue, "\(self.key3) after an or had a value of '\(String(describing: nestedResponses[4].asString?.asData))'")
                    XCTAssertEqual(nestedResponses[5], RedisResponse.IntegerValue(4), "Destination field length should have been 4, it was \(String(describing: nestedResponses[5].asInteger))")
                    bytes = [0x00, 0x09, 0x09, 0x00]
                    newValue = Data(bytes: bytes, count: bytes.count)
                    XCTAssertEqual(nestedResponses[6].asString?.asData, newValue, "\(self.key3) after an xor had a value of '\(String(describing: nestedResponses[6].asString?.asData))'")
                    XCTAssertEqual(nestedResponses[7], RedisResponse.IntegerValue(4), "Destination field length should have been 4, it was \(String(describing: nestedResponses[7].asInteger))")
                    bytes = [0xff, 0xfe, 0xfe, 0xfb]
                    newValue = Data(bytes: bytes, count: bytes.count)
                    XCTAssertEqual(nestedResponses[8].asString?.asData, newValue, "\(self.key3) after a not had a value of '\(String(describing: nestedResponses[8].asString?.asData))'")
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
            if error != nil {
                XCTFail("Could not connect to Redis")
                return
            }

            redis.del(self.key1, self.key2, self.key3, self.key4) {(deleted: Int?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")

                callback()
            }
        }
    }
}
