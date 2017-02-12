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
import Dispatch

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

import Foundation
import XCTest


public class TestListsPart3: XCTestCase {
    static var allTests: [(String, (TestListsPart3) -> () throws -> Void)] {
        return [
            ("test_blpopBrpopAndBrpoplpushEmptyLists", test_blpopBrpopAndBrpoplpushEmptyLists),
            ("test_blpop", test_blpop),
            ("test_brpop", test_brpop),
            ("test_brpoplpush", test_brpoplpush)
        ]
    }

    let secondConnection = Redis()

    let queue = DispatchQueue(label: "unblocker", attributes: DispatchQueue.Attributes.concurrent)

    var key1: String { return "test1" }
    var key2: String { return "test2" }
    var key3: String { return "test3" }

    func localSetup(block: () -> Void) {
        connectRedis() {(error: NSError?) in
            if error != nil {
                XCTFail("Could not connect to Redis")
                return
            }

            redis.del(self.key1, self.key2, self.key3) {(deleted: Int?, error: NSError?) in
                block()
            }
        }
    }

    func extendedSetup(block: () -> Void) {
        localSetup() {
            let password = read(fileName: "password.txt")
            let host = read(fileName: "host.txt")

            self.secondConnection.connect(host: host, port: 6379) {(error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")

                self.secondConnection.auth(password) {(error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")

                    block()
                }
            }
        }
    }

    func test_blpopBrpopAndBrpoplpushEmptyLists() {
        localSetup() {
            redis.blpop(self.key1, self.key2, timeout: 4.0) {(retrievedValue: [RedisString?]?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssertNil(retrievedValue, "A blpop that timed out should have returned nil. It returned \(retrievedValue)")

                redis.brpop(self.key3, self.key1, timeout: 5.0) {(retrievedValue: [RedisString?]?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNil(retrievedValue, "A brpop that timed out should have returned nil. It returned \(retrievedValue)")

                    redis.brpoplpush(self.key2, destination: self.key2, timeout: 3.0) {(retrievedValue: RedisString?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNil(retrievedValue, "A brpoplpush that timed out should have returned nil. It returned \(retrievedValue)")
                    }
                }
            }
        }
    }

    func test_blpop() {
        extendedSetup() {
            let value1 = "testing 1 2 3"

            self.queue.async { [unowned self] in
                sleep(2)   // Wait a bit to let the main test block
                self.secondConnection.lpush(self.key2, values: value1) {(listSize: Int?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(listSize, "Result of lpush was nil, but \(self.key2) should exist")
                }
            }

            redis.blpop(self.key1, self.key2, self.key3, timeout: 4.0) {(retrievedValue: [RedisString?]?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssertNotNil(retrievedValue, "blpop should not have returned nil.")
                XCTAssertEqual(retrievedValue!.count, 2, "blpop should have returned an array of two elements. It returned an array of \(retrievedValue!.count) elements")
                XCTAssertEqual(retrievedValue![0], RedisString(self.key2), "blpop's return value element #0 should have been \(self.key2). It was \(retrievedValue![0])")
                XCTAssertEqual(retrievedValue![1], RedisString(value1), "blpop's return value element #1 should have been \(value1). It was \(retrievedValue![1])")
            }
        }
    }

    func test_brpop() {
        extendedSetup() {
            let value2 = "over the hill and through the woods"
            self.queue.async { [unowned self] in
                sleep(2)   // Wait a bit to let the main test block
                self.secondConnection.lpush(self.key3, values: value2) {(listSize: Int?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(listSize, "Result of lpush was nil, but \(self.key1) should exist")
                }
            }

            redis.brpop(self.key1, self.key2, self.key3, timeout: 4.0) {(retrievedValue: [RedisString?]?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssertNotNil(retrievedValue, "brpop should not have returned nil.")
                XCTAssertEqual(retrievedValue!.count, 2, "brpop should have returned an array of two elements. It returned an array of \(retrievedValue!.count) elements")
                XCTAssertEqual(retrievedValue![0], RedisString(self.key3), "brpop's return value element #0 should have been \(self.key3). It was \(retrievedValue![0])")
                XCTAssertEqual(retrievedValue![1], RedisString(value2), "brpop's return value element #1 should have been \(value2). It was \(retrievedValue![1])")
            }
        }
    }

    func test_brpoplpush() {
        extendedSetup() {
            let value3 = "to grandmothers house we go"

            self.queue.async { [unowned self] in
                sleep(2)   // Wait a bit to let the main test block
                self.secondConnection.lpush(self.key1, values: value3) {(listSize: Int?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(listSize, "Result of lpush was nil, but \(self.key1) should exist")
                }
            }

            redis.brpoplpush(self.key1, destination: self.key2, timeout: 4.0) {(retrievedValue: RedisString?, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssertNotNil(retrievedValue, "brpoplpush should not have returned nil.")
                XCTAssertEqual(retrievedValue!, RedisString(value3), "brpoplpush's return value  should have been \(value3). It was \(retrievedValue!)")
            }
        }
    }
}
