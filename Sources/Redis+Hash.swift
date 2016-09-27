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

    /// Removes the specified fields from the hash stored at key. Specified fields that do not
    /// exist within this hash are ignored. If key does not exist, it is treated as an empty hash
    /// and this command returns 0.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter fields: removes the specified fields as a variadic parameter
    /// - Parameter callback: callback function containing the number of fields that were removed from
    ///             the hash, not including specified but non existing fields.
    public func hdel(_ key: String, fields: String..., callback: (Int?, NSError?) -> Void) {
        var command = ["HDEL", key]
        for field in fields {
            command.append(field)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Returns if field is an existing field in the hash stored at key
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter field: String value for field
    /// - Parameter callback: a callback function returning 1 if the hash contains field
    ///             0 if the hash does not contain field, or key does not exist
    public func hexists(_ key: String, field: String, callback: (Bool, NSError?) -> Void) {
        issueCommand("HEXISTS", key, field) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    /// Returns the value associated with field in the hash stored at key.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter field: String value for field
    /// - Parameter callback: a callback function returning the value associated with the field, or nil
    ///             when field is not present in the hash or key does not exist
    public func hget(_ key: String, field: String, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("HGET", key, field) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Returns all fields and values of the hash stored at key. In the returned value, every field
    /// name is followed by its value, so the length of the reply is twice the size of the hash.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter callback: a callback function returning the list of fields and their values stored in the
    ///             hash, or an empty list when key does not exist.
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
    
    /// Increments the number stored at field in the hash stored at key by increment
    ///
    /// - Parameter key: the String Parameter for they key
    /// - Parameter by: the value to increment by
    /// - Parameter callback: a function returning the value at field after the increment operation
    public func hincr(_ key: String, field: String, by: Int, callback: (Int?, NSError?) -> Void) {
        issueCommand("HINCRBY", key, field, String(by)) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    /// Increments the number stored at field in the hash stored at key by floating point increment
    ///
    /// - Parameter key: the String Parameter for they key
    /// - Parameter by: the value to increment by (Float)
    /// - Parameter callback: a function returning the value at field after the increment operation
    public func hincr(_ key: String, field: String, byFloat: Float, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("HINCRBYFLOAT", key, field, String(byFloat)) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Returns all field names in the hash stored at key
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter callback: a function returning the list of fields in the hash
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
    
    /// Returns the number of fields contained in the hash stored at key
    ///
    /// - Parameter key: the String Parameter for the key
    /// - Parameter callback: function returning the number of fields in the hash, or 0 when key does not exist
    public func hlen(_ key: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("HLEN", key) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Returns the values associated with the specified fields in the hash stored at key.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter fields: a variadic parameter for the fields
    /// - Parameter callback: a function returning a list of values associated with the given fields
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
    /// This command overwrites any existing fields in the hash. If key does not exist,
    /// a new key holding a hash is created.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter fieldValuePairs: a variadic parameter for the list of key values to set
    /// - Parameter callback: a function returning if successful
    public func hmset(_ key: String, fieldValuePairs: (String, String)..., callback: (Bool, NSError?) -> Void) {
        hmsetArrayOfKeyValues(key, fieldValuePairs: fieldValuePairs, callback: callback)
    }
    
    /// Sets the specified fields to their respective values in the hash stored at key.
    /// This command overwrites any existing fields in the hash. If key does not exist,
    /// a new key holding a hash is created.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter fieldValuePairs: a list of key values to set
    /// - Parameter callback: a function returning if successful
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
    /// - Parameter key: the String parameter for the key
    /// - Parameter fieldValuePairs: a list of key values to set
    /// - Parameter callback: a function returning if successful
    public func hmset(_ key: String, fieldValuePairs: (String, RedisString)..., callback: (Bool, NSError?) -> Void) {
        hmsetArrayOfKeyValues(key, fieldValuePairs: fieldValuePairs, callback: callback)
    }
    
    /// Sets the specified fields to their respective values in the hash stored at key.
    /// This command overwrites any existing fields in the hash. If key does not exist,
    /// a new key holding a hash is created.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter fieldValuePairs: a list of key values to set
    /// - Parameter callback: a function returning if successful
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
    
    /// Sets the specified fields to their respective values in the hash stored at key.
    /// This command overwrites any existing fields in the hash. If key does not exist,
    /// a new key holding a hash is created.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter field: the field name to set
    /// - Parameter value: the value to set in the field
    /// - Parameter exists: will set the value only if the field exists if true
    /// - Parameter callback: a function returning if successful
    public func hset(_ key: String, field: String, value: String, exists: Bool=true, callback: (Bool, NSError?) -> Void) {
        issueCommand(exists ? "HSET" : "HSETNX", key, field, value) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    /// Sets the specified fields to their respective values in the hash stored at key.
    /// This command overwrites any existing fields in the hash. If key does not exist,
    /// a new key holding a hash is created.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter field: the field name to set
    /// - Parameter value: the value to set in the field
    /// - Parameter exists: will set the value only if the field exists if true
    /// - Parameter callback: a function returning if successful
    public func hset(_ key: String, field: String, value: RedisString, exists: Bool=true, callback: (Bool, NSError?) -> Void) {
        issueCommand(RedisString(exists ? "HSET" : "HSETNX"), RedisString(key), RedisString(field), value) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    /// Returns the string length of the value associated with field in the hash stored at key.
    /// if the key or the field do not exist, 0 is returned.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter field: the field name
    /// - Parameter callback: a function returning the string length of the value associated with field
    public func hstrlen(_ key: String, field: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("HSTRLEN", key, field) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Returns all values in the hash stored at key.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter callback: a function returning a list of values in the hash
    public func hvals(_ key: String, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand("HVALS", key) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
}
