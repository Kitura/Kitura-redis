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
    public func hdel(key: String, field: String, fields: String...) throws -> Int {
        var command = ["HDEL", key, field]
        for field in fields {
            command.append(field)
        }
        return try redisIntegerResponseHandler(issueCommand(command))
    }

    /// Determine if the specified field exists in the hash stored at a key
    ///
    /// - Parameter key: The key.
    /// - Parameter field: The field.
    /// - Parameter callback: The callback function, Bool will contain true if the hash exists
    ///                      and contains the specified field.
    ///                      NSError will be non-nil if an error occurred.
    public func hexists(key: String, field: String) throws -> Bool {
        return try redisBoolResponseHandler(issueCommand("HEXISTS", key, field))
    }
    
    /// Get the value associated with a field in the hash stored at a key.
    ///
    /// - Parameter key: The key.
    /// - Parameter field: The field.
    /// - Parameter callback: The callback function returning the value associated with the field,
    ///                      or nil when field is not present in the hash or key does not exist.
    ///                      NSError will be non-nil if an error occurred.
    public func hget(key: String, field: String) throws -> RedisString? {
        return try redisStringResponseHandler(issueCommand("HGET", key, field))
    }

    /// Get all fields and values of the hash stored at a key.
    ///
    /// - Parameter key: The key.
    /// - Parameter callback: The callback function, the Dictionary<String, RedisString> contains
    ///                      the field names and their associated values that are stored in the
    ///                      hash, it is empty if key does not exist.
    ///                      NSError will be non-nil if an error occurred.
    public func hgetall(key: String) throws -> [String: RedisString] {
        let res = try issueCommand("HGETALL", key)
        var vals = [String: RedisString]()
        switch(res) {
        case .Array(let responses):
            for i in stride(from: 0, to: responses.count-1, by: 2) {
                switch(responses[i]) {
                case .StringValue(let field):
                    switch(responses[i+1]) {
                    case .StringValue(let value):
                        vals[field.asString] = value
                    default:
                        throw createUnexpectedResponseError(res)
                    }
                default:
                    throw createUnexpectedResponseError(res)
                }
            }
        case .Error(let err):
            throw createError(err, code: 1)
        default:
            throw createUnexpectedResponseError(res)
        }
        return vals
    }
    
    /// Increments the number stored in a field in the hash stored at a key by a value
    ///
    /// - Parameter key: The key.
    /// - Parameter field: The field.
    /// - Parameter by: The value to increment by.
    /// - Parameter callback: The callback function, the Int will contain the value of
    ///                      the field after it was incremented.
    ///                      NSError will be non-nil if an error occurred.
    public func hincrby(key: String, field: String, increment: Int) throws -> Int {
        return try redisIntegerResponseHandler(issueCommand("HINCRBY", key, field, String(increment)))
    }

    /// Increments the number stored in a field in the hash stored at a key by floating point value
    ///
    /// - Parameter key: The key.
    /// - Parameter field: The field.
    /// - Parameter byFloat: The floating point value to increment by.
    /// - Parameter callback: The callback function, the `RedisString` will contain the value of
    ///                      the field after it was incremented.
    ///                      NSError will be non-nil if an error occurred.
    public func hincrbyfloat(key: String, field: String, increment: Float) throws -> RedisString {
        return try redisStringResponseHandler(issueCommand("HINCRBYFLOAT", key, field, String(increment)))
    }
    
    /// Get all of the field names in the hash stored at a key
    ///
    /// - Parameter key: The key.
    /// - Parameter callback: The callback function, the Array<String> will contain
    ///                      the list of the fields names in the hash.
    ///                      NSError will be non-nil if an error occurred.
    public func hkeys(key: String) throws -> [String] {
        let res = try issueCommand("HKEYS", key)
        var strings = [String]()
        switch(res) {
        case .Array(let responses):
            for innerResponse in responses {
                switch(innerResponse) {
                case .StringValue(let str):
                    strings.append(str.asString)
                default:
                    throw createUnexpectedResponseError(res)
                }
            }
        case .Error(let err):
            throw createError(err, code: 1)
        default:
            throw createUnexpectedResponseError(res)
        }
        return strings
    }
    
    /// Get the number of fields contained in the hash stored at a key
    ///
    /// - Parameter key: The key.
    /// - Parameter callback: The callback function, the Int will contain the number
    ///                      of fields in the hash, or 0 when the key does not exist.
    ///                      NSError will be non-nil if an error occurred.
    public func hlen(key: String) throws -> Int {
        return try redisIntegerResponseHandler(issueCommand("HLEN", key))
    }

    /// Get the values associated with the specified fields in the hash stored at a key.
    ///
    /// - Parameter key: The key.
    /// - Parameter fields: The list of field names.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain the list
    ///                      of values associated with the given fields, in the order the field
    ///                      names were specified. NSError will be non-nil if an error occurred.
    public func hmget(key: String, field: String, fields: String...) throws -> [RedisString?] {
        var command = ["HMGET", key, field]
        for field in fields {
            command.append(field)
        }
        return try redisStringArrayResponseHandler(issueCommand(command))
    }

    /// Sets the specified fields to their respective values in the hash stored at key.
    /// This command overwrites any existing fields in the hash. If the key does not exist,
    /// a new key holding a hash is created.
    ///
    /// - Parameter key: The key.
    /// - Parameter fieldValuePairs: The list of field name value tuples to set.
    /// - Parameter callback: The callback function, the Bool will contain true if the
    ///                      fields were set. NSError will be non-nil if an error occurred.
    public func hmset(key: String, fieldValuePair: (String, String), fieldValuePairs: (String, String)...) throws -> Bool {
        return try hmset(key: key, fieldValuePair: fieldValuePair, fieldValuePairs: fieldValuePairs)
    }

    /// Sets the specified fields to their respective values in the hash stored at key.
    /// This command overwrites any existing fields in the hash. If key does not exist,
    /// a new key holding a hash is created.
    ///
    /// - Parameter key: The key.
    /// - Parameter fieldValuePairs: The array of field name value tuples to set.
    /// - Parameter callback: The callback function, the Bool will contain true if the
    ///                      fields were set. NSError will be non-nil if an error occurred.
    public func hmset(key: String, fieldValuePair: (String, String), fieldValuePairs: [(String, String)]) throws -> Bool {
        var command = ["HMSET", key, fieldValuePair.0, fieldValuePair.1]
        for (field, value) in fieldValuePairs {
            command.append(field)
            command.append(value)
        }
        return try redisOkResponseHandler(issueCommand(command), nilOk: false)
    }
    
    /// Sets the specified fields to their respective values in the hash stored at key.
    /// This command overwrites any existing fields in the hash. If key does not exist,
    /// a new key holding a hash is created.
    ///
    /// - Parameter key: The key.
    /// - Parameter fieldValuePairs: The list of field name value tuples to set. With values as `RedisString`s.
    /// - Parameter callback: The callback function, the Bool will contain true if the
    ///                      fields were set. NSError will be non-nil if an error occurred.
    public func hmset(key: String, fieldValuePair: (String, RedisString), fieldValuePairs: (String, RedisString)...) throws -> Bool {
        return try hmset(key: key, fieldValuePair: fieldValuePair, fieldValuePairs: fieldValuePairs)
    }

    /// Sets the specified fields to their respective values in the hash stored at key.
    /// This command overwrites any existing fields in the hash. If key does not exist,
    /// a new key holding a hash is created.
    ///
    /// - Parameter key: The key.
    /// - Parameter fieldValuePairs: The array of field name value tuples to set. With values as `RedisString`s.
    /// - Parameter callback: The callback function, the Bool will contain true if the
    ///                      fields were set. NSError will be non-nil if an error occurred.
    public func hmset(key: String, fieldValuePair: (String, RedisString), fieldValuePairs: [(String, RedisString)]) throws -> Bool {
        var command = [RedisString("HMSET"), RedisString(key), RedisString(fieldValuePair.0), fieldValuePair.1]
        for (field, value) in fieldValuePairs {
            command.append(RedisString(field))
            command.append(value)
        }
        return try redisOkResponseHandler(issueCommand(command), nilOk: false)
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
    public func hscan(key: String, cursor: Int, match: String?=nil, count: Int?=nil) throws -> (RedisString, [RedisString]) {
        var command = ["HSCAN", key, String(cursor)]
        if let match = match, let count = count {
            command.append("MATCH")
            command.append(match)
            command.append("COUNT")
            command.append(String(count))
        }
        if let match = match, count == nil {
            command.append("MATCH")
            command.append(match)
        }
        if let count = count, match == nil {
            command.append("COUNT")
            command.append(String(count))
        }
        return try redisScanResponseHandler(issueCommand(command))
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
    public func hset(key: String, field: String, value: String, exists: Bool=true) throws -> Bool {
        return try redisBoolResponseHandler(issueCommand(exists ? "HSET" : "HSETNX", key, field, value))
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
    public func hset(key: String, field: String, value: RedisString, exists: Bool=true) throws -> Bool {
        return try redisBoolResponseHandler(issueCommand(RedisString(exists ? "HSET" : "HSETNX"), RedisString(key), RedisString(field), value))
    }
    
    /// Get the string length of the value in a field in a hash stored at a key.
    /// If the key or the field do not exist, 0 is returned.
    ///
    /// - Parameter key: The key.
    /// - Parameter field: The name of the field.
    /// - Parameter callback: The callback function, the Int will contain the string length
    ///                      of the value in the specified field.
    ///                      NSError will be non-nil if an error occurred.
    public func hstrlen(key: String, field: String) throws -> Int {
        return try redisIntegerResponseHandler(issueCommand("HSTRLEN", key, field))
    }
    
    /// Get all of the values in the hash stored at a key.
    ///
    /// - Parameter key: The key.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain the
    ///                      list of values in the hash.
    ///                      NSError will be non-nil if an error occurred.
    public func hvals(key: String) throws -> [RedisString] {
        return try redisStringArrayResponseHandler(issueCommand("HVALS", key))
    }
}