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

var redis = Redis()

func connectRedis (authenticate: Bool = true, callback: (NSError?) -> Void) {
    if !redis.connected {
        let password = read(fileName: "password.txt")
        let host = read(fileName: "host.txt")

        redis.connect(host: host, port: 6379) {(error: NSError?) in
            if authenticate {
                redis.auth(password, callback: callback)
            } else {
                callback(error)
            }
        }
    } else {
        callback(nil)
    }
}

func setup(major: Int, minor: Int, micro: Int, callback: () -> Void) {
    connectRedis() {(err) in
        if let err = err {
            XCTFail(String(describing: err))
            return
        }
        
        redis.info { (info: RedisInfo?, err) in
            if let err = err {
                XCTFail(String(describing: err))
                return
            }
            
            if let info = info, info.server.checkVersionCompatible(major: major, minor: minor, micro: micro) {
                redis.flushdb(callback: { (_, err) in
                    if let err = err {
                        XCTFail(String(describing: err))
                        return
                    }
                    
                    callback()
                })
            }
        }
    }
}

func read(fileName: String) -> String {
        // Read in a configuration file into an NSData
    do {
        var pathToTests = #file
        if pathToTests.hasSuffix("CommonUtils.swift") {
            pathToTests = pathToTests.replacingOccurrences(of: "CommonUtils.swift", with: "")
        }
        let fileData = try Data(contentsOf: URL(fileURLWithPath: "\(pathToTests)\(fileName)"))
        XCTAssertNotNil(fileData, "Failed to read in the \(fileName) file")

        let resultString = String(data: fileData, encoding: String.Encoding.utf8)

        guard
           let resultLiteral = resultString
        else {
            XCTFail("Error in \(fileName).")
            exit(1)
        }
        return resultLiteral.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    } catch {
        XCTFail("Error in \(fileName).")
        exit(1)
    }
}

// Dummy class for test framework
class CommonUtils { }
