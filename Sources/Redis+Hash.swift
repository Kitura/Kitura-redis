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

/// Extend Redis by adding the Hash operations
extension Redis {
    
    //
    //  MARK: Hash API functions
    //

    /// Removes the specified fields from the hash stored at a key. Specified fields that do not
    /// exist within this hash are ignored. If key does not exist, it is treated as an empty hash
    /// and this command returns 0.
    ///
    /// - Parameter key: The key.
    /// - Parameter fields: The list of fields to remove.
    /// - Parameter callback: The callback function, the Int will contain the number of fields that
    ///             were removed from the hash, not including specified but non existing fields.
    ///             NSError will be non-nil if an error occurred.
    public func hdel(_ key: String, fields: String..., callback: (Int?, NSError?) -> Void) {
        var command = ["HDEL", key]
        for field in fields {
            command.append(field)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    /// Determine if the specified field exists in the hash stored at a key
    ///
    /// - Parameter key: The key.
    /// - Parameter field: The field.
    /// - Parameter callback: The callback function, Bool will contain true if the hash exists
    ///                      and contains the specified field.
    ///                      NSError will be non-nil if an error occurred.
    public func hexists(_ key: String, field: String, callback: (Bool, NSError?) -> Void) {
        issueCommand("HEXISTS", key, field) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    /// Get the value associated with a field in the hash stored at a key.
    ///
    /// - Parameter key: The key.
    /// - Parameter field: The field.
    /// - Parameter callback: The callback function returning the value associated with the field,
    ///                      or nil when field is not present in the hash or key does not exist.
    ///                      NSError will be non-nil if an error occurred.
    public func hget(_ key: String, field: String, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("HGET", key, field) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }

    /// Get all fields and values of the hash stored at a key.
    ///
    /// - Parameter key: The key.
    /// - Parameter callback: The callback function, the Dictionary<String, RedisString> contains
    ///                      the field names and their associated values that are stored in the
    ///                      hash, it is empty if key does not exist.
    ///                      NSError will be non-nil if an error occurred.
    public func hgetall(_ key: String, callback: ([String: RedisString], NSError?) -> Void) {
        issueCommand("HGETALL", key) {(response: RedisResponse) in
            var values = [String: RedisString]()
            var error: NSError? = nil

            switch(response) {
            case .Array(let responses):
                for idx in stride(from: 0, to: responses.count-1, by: 2) {
                    switch(responses[idx]) {
                    case .StringValue(let field):
                        switch(responses[idx+1]) {
                        case .StringValue(let value):
                            values[field.asString] = value
                        default:
                            error = self.createUnexpectedResponseError(response)
                        }
                    default:
                        error = self.createUnexpectedResponseError(response)
                    }
                }
            case .Error(let err):
                error = self.createError("Error: \(err)", code: 1)
            default:
                error = self.createUnexpectedResponseError(response)
            }
            callback(values, _: error)
        }
    }

    /// Increments the number stored in a field in the hash stored at a key by a value
    ///
    /// - Parameter key: The key.
    /// - Parameter field: The field.
    /// - Parameter by: The value to increment by.
    /// - Parameter callback: The callback function, the Int will contain the value of
    ///                      the field after it was incremented.
    ///                      NSError will be non-nil if an error occurred.
    public func hincr(_ key: String, field: String, by: Int, callback: (Int?, NSError?) -> Void) {
        issueCommand("HINCRBY", key, field, String(by)) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    /// Increments the number stored in a field in the hash stored at a key by floating point value
    ///
    /// - Parameter key: The key.
    /// - Parameter field: The field.
    /// - Parameter byFloat: The floating point value to increment by.
    /// - Parameter callback: The callback function, the `RedisString` will contain the value of
    ///                      the field after it was incremented.
    ///                      NSError will be non-nil if an error occurred.
    public func hincr(_ key: String, field: String, byFloat: Float, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("HINCRBYFLOAT", key, field, String(byFloat)) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    /// Get all of the field names in the hash stored at a key
    ///
    /// - Parameter key: The key.
    /// - Parameter callback: The callback function, the Array<String> will contain
    ///                      the list of the fields names in the hash.
    ///                      NSError will be non-nil if an error occurred.
    public func hkeys(_ key: String, callback: ([String]?, NSError?) -> Void) {
        issueCommand("HKEYS", key) {(response: RedisResponse) in
            var error: NSError? = nil
            var strings = [String]()

            switch(response) {
            case .Array(let responses):
                for innerResponse in responses {
                    switch(innerResponse) {
                    case .StringValue(let str):
                        strings.append(str.asString)
                    default:
                        error = self.createUnexpectedResponseError(response)
                    }
                }
            case .Error(let err):
                error = self.createError("Error: \(err)", code: 1)
            default:
                error = self.createUnexpectedResponseError(response)
            }
            callback(error == nil ? strings : nil, _: error)
        }
    }
    
    /// Get the number of fields contained in the hash stored at a key
    ///
    /// - Parameter key: The key.
    /// - Parameter callback: The callback function, the Int will contain the number
    ///                      of fields in the hash, or 0 when the key does not exist.
    ///                      NSError will be non-nil if an error occurred.
    public func hlen(_ key: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("HLEN", key) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    /// Get the values associated with the specified fields in the hash stored at a key.
    ///
    /// - Parameter key: The key.
    /// - Parameter fields: The list of field names.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain the list
    ///                      of values associated with the given fields, in the order the field
    ///                      names were specified. NSError will be non-nil if an error occurred.
    public func hmget(_ key: String, fields: String..., callback: ([RedisString?]?, NSError?) -> Void) {
        var command = ["HMGET", key]
        for field in fields {
            command.append(field)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }

    /// Sets the specified fields to their respective values in the hash stored at key.
    /// This command overwrites any existing fields in the hash. If the key does not exist,
    /// a new key holding a hash is created.
    ///
    /// - Parameter key: The key.
    /// - Parameter fieldValuePairs: The list of field name value tuples to set.
    /// - Parameter callback: The callback function, the Bool will contain true if the
    ///                      fields were set. NSError will be non-nil if an error occurred.
    public func hmset(_ key: String, fieldValuePairs: (String, String)..., callback: (Bool, NSError?) -> Void) {
        hmsetArrayOfKeyValues(key, fieldValuePairs: fieldValuePairs, callback: callback)
    }

    /// Sets the specified fields to their respective values in the hash stored at key.
    /// This command overwrites any existing fields in the hash. If key does not exist,
    /// a new key holding a hash is created.
    ///
    /// - Parameter key: The key.
    /// - Parameter fieldValuePairs: The array of field name value tuples to set.
    /// - Parameter callback: The callback function, the Bool will contain true if the
    ///                      fields were set. NSError will be non-nil if an error occurred.
    public func hmsetArrayOfKeyValues(_ key: String, fieldValuePairs: [(String, String)], callback: (Bool, NSError?) -> Void) {
        var command = ["HMSET", key]
        for (field, value) in fieldValuePairs {
            command.append(field)
            command.append(value)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            let (ok, error) = self.redisOkResponseHandler(response, nilOk: false)
            callback(ok, _: error)
        }
    }

    /// Sets the specified fields to their respective values in the hash stored at key.
    /// This command overwrites any existing fields in the hash. If key does not exist,
    /// a new key holding a hash is created.
    ///
    /// - Parameter key: The key.
    /// - Parameter fieldValuePairs: The list of field name value tuples to set. With values as `RedisString`s.
    /// - Parameter callback: The callback function, the Bool will contain true if the
    ///                      fields were set. NSError will be non-nil if an error occurred.
    public func hmset(_ key: String, fieldValuePairs: (String, RedisString)..., callback: (Bool, NSError?) -> Void) {
        hmsetArrayOfKeyValues(key, fieldValuePairs: fieldValuePairs, callback: callback)
    }

    /// Sets the specified fields to their respective values in the hash stored at key.
    /// This command overwrites any existing fields in the hash. If key does not exist,
    /// a new key holding a hash is created.
    ///
    /// - Parameter key: The key.
    /// - Parameter fieldValuePairs: The array of field name value tuples to set. With values as `RedisString`s.
    /// - Parameter callback: The callback function, the Bool will contain true if the
    ///                      fields were set. NSError will be non-nil if an error occurred.
    public func hmsetArrayOfKeyValues(_ key: String, fieldValuePairs: [(String, RedisString)], callback: (Bool, NSError?) -> Void) {
        var command = [RedisString("HMSET"), RedisString(key)]
        for (field, value) in fieldValuePairs {
            command.append(RedisString(field))
            command.append(value)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            let (ok, error) = self.redisOkResponseHandler(response, nilOk: false)
            callback(ok, _: error)
        }
    }
    
    /// Iterates fields of Hash types and their associated values.
    ///
    /// - Parameter key: The key of the hash.
    /// - parameter cursor: Where to begin iterating.
    /// - parameter match: Glob-style pattern to match elements against.
    /// - parameter count: Amount of elements to try to iterate.
    /// - parameter callback: The callback function.
    /// - parameter newCursor: The new cursor to be used to continue iterating
    ///                        remaining elements. If 0, all elements have been
    ///                        iterated.
    /// - parameter res: The results of the scan.
    /// - parameter err: The error, if one occured.
    public func hscan(key: String, cursor: Int, match: String?=nil, count: Int?=nil,
                      callback: (_ newCursor: RedisString?, _ res: [RedisString?]?, _ err: NSError?) -> Void) {
        if let match = match, let count = count {
            issueCommand("HSCAN", key, String(cursor), "MATCH", match, "COUNT", String(count)) {(response: RedisResponse) in
                self.redisScanResponseHandler(response, callback: callback)
            }
        } else if let match = match {
            issueCommand("HSCAN", key, String(cursor), "MATCH", match) {(response: RedisResponse) in
                self.redisScanResponseHandler(response, callback: callback)
            }
        } else if let count = count {
            issueCommand("HSCAN", key, String(cursor), "COUNT", String(count)) {(response: RedisResponse) in
                self.redisScanResponseHandler(response, callback: callback)
            }
        } else {
            issueCommand("HSCAN", key, String(cursor)) {(response: RedisResponse) in
                self.redisScanResponseHandler(response, callback: callback)
            }
        }
    }

    /// Sets the specified field in a hash stored at a key to a value. This command overwrites
    /// an existing field in the hash. If key does not exist, a new key holding a hash is created.
    ///
    /// - Parameter key: The key.
    /// - Parameter field: The name of the field name to set.
    /// - Parameter value: The value to set the field to.
    /// - Parameter exists: If true, will set the value only if the field exists.
    /// - Parameter callback: The callback function, the Bool will contain true if the
    ///                      field was set. NSError will be non-nil if an error occurred.
    public func hset(_ key: String, field: String, value: String, exists: Bool=true, callback: (Bool, NSError?) -> Void) {
        issueCommand(exists ? "HSET" : "HSETNX", key, field, value) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }

    /// Sets the specified field in a hash stored at a key to a value. This command overwrites
    /// an existing field in the hash. If key does not exist, a new key holding a hash is created.
    ///
    /// - Parameter key: The key.
    /// - Parameter field: The name of the field name to set.
    /// - Parameter value: The value in the form of a `RedisString` to set the field to.
    /// - Parameter exists: If true, will set the value only if the field exists
    /// - Parameter callback: The callback function, the Bool will contain true if the
    ///                      field was set. NSError will be non-nil if an error occurred.
    public func hset(_ key: String, field: String, value: RedisString, exists: Bool=true, callback: (Bool, NSError?) -> Void) {
        issueCommand(RedisString(exists ? "HSET" : "HSETNX"), RedisString(key), RedisString(field), value) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    /// Get the string length of the value in a field in a hash stored at a key.
    /// If the key or the field do not exist, 0 is returned.
    ///
    /// - Parameter key: The key.
    /// - Parameter field: The name of the field.
    /// - Parameter callback: The callback function, the Int will contain the string length
    ///                      of the value in the specified field.
    ///                      NSError will be non-nil if an error occurred.
    public func hstrlen(_ key: String, field: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("HSTRLEN", key, field) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    /// Get all of the values in the hash stored at a key.
    ///
    /// - Parameter key: The key.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain the
    ///                      list of values in the hash.
    ///                      NSError will be non-nil if an error occurred.
    public func hvals(_ key: String, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand("HVALS", key) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
}
