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
#elseif os(OSX)
    import Darwin
#endif

import Foundation
import XCTest

let redis = Redis()

func connectRedis (callback: (NSError?) -> Void) {
    if !redis.connected  {
        var host = "localhost"
        let hostCStr = getenv("SWIFT_REDIS_HOST") 
        if  hostCStr != nil {
            if  let hostStr = NSString(UTF8String: hostCStr) {
                host = hostStr.bridge()
            }
        }
        redis.connect(host, port: 6379, callback: callback)
    }
    else {
        callback(nil)
    }
}

public struct AuthTests: XCTestCase {
    
    let key = "authTestKey"
    
    public var allTests : [(String, () throws -> Void)] {
        return [
            ("test_ConnectWithAuth", test_ConnectWithAuth)
        ]
    }
    
    func test_ConnectWithAuth() {
        connectRedis() {(error: NSError?) in
            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
            
            let expectedValue = "Hi ho, hi ho, we are so secured"
            redis.set(self.key, value: expectedValue) {(wasSet: Bool, error: NSError?) in
                XCTAssertNotNil(error, "Error was nil")
                XCTAssertFalse(wasSet, "Set \(self.key) without authenticating")
                
                let pswdCstr = getenv("SWIFT_REDIS_AUTH_PSWD")
                XCTAssert(pswdCstr != nil, "Didn't get a password")
                
                let pswd = NSString(UTF8String: pswdCstr)
                XCTAssertNotNil(pswd, "Password wasn't a UTF-8 string")
                
                redis.auth(pswd!.bridge()) {(error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    
                    redis.set(self.key, value: expectedValue) {(wasSet: Bool, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssert(wasSet, "Failed to set \(self.key)")
                        
                        redis.get(self.key) {(returnedValue: RedisString?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertEqual(returnedValue!.asString, expectedValue, "Returned value was not '\(expectedValue)'")
                        }
                    }
                }
            }
        }
    }
}
