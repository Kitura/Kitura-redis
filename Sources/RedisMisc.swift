/**
 * Copyright IBM Corporation 2016, 2017
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

import Foundation

/// A class for working with Redis "binary" strings. All data is stored as a UTF-8 string.
public class RedisString: CustomStringConvertible {
    fileprivate let data: Data

    /// Initialize a `RedisString`
    ///
    /// - Parameter data: A Data struct containing the binary data to be stored in this `RedisString`.
    public init(_ data: Data) {
        self.data = data
    }

    /// Initialize a `RedisString`
    ///
    /// - Parameter value: A String value to be stored in this `RedisString` in UTF-8 form.
    public convenience init(_ value: String) {
        // String.data(encoding:) will return nil on Linux on an empty string
        // eventually this needs to be changed in swift-corelibs-foundation
        // the "?? Data()" ensures that an empty Data is added if the "arg" is empty
        let data = value.data(using: String.Encoding.utf8) ?? Data()
        self.init(data)
    }

    /// Initialize a `RedisString`
    ///
    /// - Parameter value: An Int value to be stored in this `RedisString` in UTF-8 form.
    public convenience init(_ value: Int) {
        self.init(String(value))
    }

    /// Initialize a `RedisString`
    ///
    /// - Parameter value: A Double value to be stored in this `RedisString` in UTF-8 form.
    public convenience init(_ value: Double) {
        self.init(String(value))
    }

    /// Get the binary contents of the `RedisString` object
    ///
    /// - Returns: A Data struct containing the contents of the `RedisString` object.
    public var asData: Data { return data }

    /// Get the contents of the `RedisString` object in the form of a String
    ///
    /// - Returns: The contents of the `RedisString` object as a String.
    public var asString: String {
        return String(data: data, encoding: String.Encoding.utf8)!
    }

    /// Get the contents of the `RedisString` object in the form of an Int
    ///
    /// - Returns: The contents of the `RedisString` object as an Int.
    public var asInteger: Int { return Int(self.asString)! }

    /// Get the contents of the `RedisString` object in the form of a Double
    ///
    /// - Returns: The contents of the `RedisString` object as a Double.
    public var asDouble: Double { return Double(self.asString)! }

    /// Get a String form, if possible, of the contents `RedisString` object
    ///
    /// - Returns: The contents of the `RedisString` object as a String, if the contents
    ///           isn't UTF-8, an error message is returned.
    public var description: String {
        let text = String(data: data, encoding: String.Encoding.utf8)
        return text ?? "A non-UTF-8 string"
    }
}

/// Implement the `Equatable` protocol for the `RedisString` class.
extension RedisString: Equatable {}

/// Compare two `RedisString` objects.
public func == (lhs: RedisString, rhs: RedisString) -> Bool {
    return lhs.data == rhs.data
}

/// A "raw" response from a Redis server
public enum RedisResponse {
    /// An array response from a Redis server. The value is an array of the individual
    /// responses that made up the array response.
    case Array([RedisResponse])

    /// An error from the Redis server.
    case Error(String)

    /// An Integer value returned from the Redis server.
    case IntegerValue(Int64)

    /// A Null response returned from the Redis server.
    case Nil

    /// A status response (Simple string, OK) returned from the Redis server.
    case Status(String)

    /// A Bulk string response returned from the Redis server.
    case StringValue(RedisString)

    /// Extract an "array" response from the `RedisResponse` enum
    ///
    /// - Returns: An array of `RedisResponse` enums or nil, if the Redis response
    ///           wasn't an array response.
    public var asArray: [RedisResponse]? {
        let result: [RedisResponse]?
        switch(self) {
        case .Array(let responses):
            result = responses
        default:
            result = nil
        }
        return result
    }

    /// Extract an error response from the `RedisResponse` enum
    ///
    /// - Returns: The error message as a String or nil, if the Redis response
    ///           wasn't an error response.
    public var asError: String? {
        let result: String?
        switch(self) {
        case .Error(let str):
            result = str
        default:
            result = nil
        }
        return result
    }

    /// Extract an Integer response from the `RedisResponse` enum
    ///
    /// - Returns: The response as a Int64 or nil, if the Redis response
    ///           wasn't an Integer response.
    public var asInteger: Int64? {
        let result: Int64?
        switch(self) {
            case .IntegerValue(let num):
                result = num
            default:
                result = nil
        }
        return result
    }

    /// Extract a Simple String response from the `RedisResponse` enum
    ///
    /// - Returns: The response as a String or nil, if the Redis response
    ///           wasn't a Simple String response.
    public var asStatus: String? {
        let result: String?
        switch(self) {
        case .Status(let str):
            result = str
        default:
            result = nil
        }
        return result
    }

    /// Extract a Bulk String response from the `RedisResponse` enum
    ///
    /// - Returns: The response as a String or nil, if the Redis response
    ///           wasn't a Bulk String response.
    public var asString: RedisString? {
        let result: RedisString?
        switch(self) {
        case .StringValue(let str):
            result = str
        default:
            result = nil
        }
        return result
    }
}

/// Implement the `Equatable` protocol for the `RedisResponse` enum.
extension RedisResponse: Equatable {}

/// Compare two `RedisResponse` enums.
public func == (lhs: RedisResponse, rhs: RedisResponse) -> Bool {
    switch (lhs, rhs) {
    case (.Array(let lhv), .Array(let rhv)):
        return lhv == rhv
    case (.Error, .Error):
        return true
    case (.IntegerValue(let lhv), .IntegerValue(let rhv)):
        return lhv == rhv
    case (.Nil, .Nil):
        return true
    case (.Status(let lhv), .Status(let rhv)):
        return lhv == rhv
    case (.StringValue(let lhv), .StringValue(let rhv)):
        return lhv == rhv
    default:
        return false
    }
}
