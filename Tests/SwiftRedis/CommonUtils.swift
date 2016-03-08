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

#if os(Linux)
    import Glibc
#elseif os(OSX)
    import Darwin
#endif

import XCTest
import Foundation

import SwiftRedis


var redis = Redis()

func connectRedis (authenticate: Bool = true, callback: (NSError?) -> Void) {
    if !redis.connected  {
        let password = readPassword()
        let host = "localhost"

        redis.connect(host, port: 6379) {(error: NSError?) in
            if authenticate {
                redis.auth(password, callback: callback)
            }
            else {
                callback(nil)
            }
        }
    }
    else {
        callback(nil)
    }
}

func readPassword() -> String {
        // Read in credentials an NSData
        let passwordData = NSData(contentsOfFile: "Tests/SwiftRedis/password.txt")
        XCTAssertNotNil(passwordData, "Failed to read in the password.txt file")

        let password = String(data: passwordData!, encoding:NSUTF8StringEncoding)

        guard
           let passwordLiteral = password
        else {
            XCTFail("Error in password.txt.")
            exit(1)
        }

        return passwordLiteral
    }

// Dummy class for test framework
class CommonUtils { }
