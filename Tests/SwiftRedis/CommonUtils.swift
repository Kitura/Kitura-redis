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
        let password = read(fileName: "password.txt")
        let host = read(fileName: "host.txt")

        redis.connect(host: host, port: 6379) {(error: NSError?) in
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

func read(fileName: String) -> String {
        // Read in a configuration file into an NSData
        let fileData = NSData(contentsOfFile: "Tests/SwiftRedis/\(fileName)")
        XCTAssertNotNil(fileData, "Failed to read in the \(fileName) file")

    #if os(Linux)
        let resultString = String(data: fileData!, encoding:NSUTF8StringEncoding)
    #else
        let resultString = String(data: fileData! as Data, encoding: String.Encoding.utf8)
    #endif

        guard
           let resultLiteral = resultString
        else {
            XCTFail("Error in \(fileName).")
            exit(1)
        }
    #if os(Linux)
        return resultLiteral.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines())
    #else
        return resultLiteral.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    #endif
    }

// Dummy class for test framework
class CommonUtils { }
