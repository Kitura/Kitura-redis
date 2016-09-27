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

/// Extend Redis by adding the Basic operations
extension Redis {

    /// Get the value of key.
    ///
    /// - Parameter key: String for the key name
    /// - Parameter callback: callback function with the value
    public func get(_ key: String, callback: (RedisString?, NSError?) -> Void) {
        
        issueCommand("GET", key) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Atomically sets key to value and returns the old value stored at key.
    ///
    /// - Parameter key: String for the key name
    /// - Parameter value: String value to set
    /// - Parameter callback: callback function with the old value
    public func getSet(_ key: String, value: String, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("GETSET", key, value) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Atomically sets key to value and returns the old value stored at key.
    ///
    /// - Parameter key: String for the key name
    /// - Parameter value: RedisString value to set
    /// - Parameter callback: callback function with the old value
    public func getSet(_ key: String, value: RedisString, callback: (RedisString?, NSError?) -> Void) {
        issueCommand(RedisString("GETSET"), RedisString(key), value) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Set key to hold the string value. If key already holds a value, it is overwritten.
    ///
    /// - Parameter key: String for the key name
    /// - Parameter value: String value to set
    /// - Parameter exists: if true will only set the key if it already exists
    /// - Parameter expiresIn: Set the specified expire time, in milliseconds
    /// - Parameter callback: callback function after setting the value
    public func set(_ key: String, value: String, exists: Bool?=nil, expiresIn: TimeInterval?=nil, callback: (Bool, NSError?) -> Void) {
        
        var command = ["SET", key, value]
        if  let exists = exists  {
            command.append(exists ? "XX" : "NX")
        }
        if  let expiresIn = expiresIn  {
            command.append("PX")
            command.append(String(Int(expiresIn * 1000.0)))
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            let (ok, error) = self.redisOkResponseHandler(response)
            callback(ok, _: error)
        }
    }
    
    /// Set key to hold the string value. If key already holds a value, it is overwritten.
    ///
    /// - Parameter key: String for the key name
    /// - Parameter value: RedisString value to set
    /// - Parameter exists: if true will only set the key if it already exists
    /// - Parameter expiresIn: Set the specified expire time, in milliseconds
    /// - Parameter callback: callback function after setting the value
    public func set(_ key: String, value: RedisString, exists: Bool?=nil, expiresIn: TimeInterval?=nil, callback: (Bool, NSError?) -> Void) {
        
        var command = [RedisString("SET"), RedisString(key), value]
        if  let exists = exists  {
            command.append(RedisString(exists ? "XX" : "NX"))
        }
        if  let expiresIn = expiresIn  {
            command.append(RedisString("PX"))
            command.append(RedisString(Int(expiresIn * 1000.0)))
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            let (ok, error) = self.redisOkResponseHandler(response)
            callback(ok, _: error)
        }
    }
    
    /// Removes the specified keys. A key is ignored if it does not exist
    ///
    /// - Parameter keys: Variadic parameter as a list of Strings
    /// - Parameter callback: callback function after deleting item
    public func del(_ keys: String..., callback: (Int?, NSError?) -> Void) {
        
        var command = ["DEL"]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Removes the specified keys. A key is ignored if it does not exist
    ///
    /// - Parameter keys: Variadic parameter as a list of Strings
    /// - Parameter callback: callback function after deleting item
    public func del(_ keys: RedisString..., callback: (Int?, NSError?) -> Void) {
        
        var command = [RedisString("DEL")]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Increments the number stored at key by an increment. If the key does not exist, it is set
    /// to 0 before performing the operation.
    /// **Note this is a string operation since Redis does not have a dedicated integer type**
    ///
    /// - Parameter key: String for the key name
    /// - Parameter by: number that will be added to the value at the key
    /// - Parameter callback: callback containing the value of the key after the increment
    public func incr(_ key: String, by: Int=1, callback: (Int?, NSError?) -> Void) {
        
        issueCommand("INCRBY", key, String(by)) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Increments the floating point number stored at key by an increment.
    /// If the key does not exist, it is set to 0 before performing the operation.
    /// **Note this is a string operation since Redis does not have a dedicated float type**
    ///
    /// - Parameter key: String for the key name
    /// - Parameter by: Floating point number that will be added to the value at the key
    /// - Parameter callback: callback containing the value of the key after the increment
    public func incr(_ key: String, byFloat: Float, callback: (RedisString?, NSError?) -> Void) {
        
        issueCommand("INCRBYFLOAT", key, String(byFloat)) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Decrements the integer number stored at key by an value.
    /// If the key does not exist, it is set to 0 before performing the operation.
    /// **Note this is a string operation since Redis does not have a dedicated float type**
    ///
    /// - Parameter key: String for the key name
    /// - Parameter by: Integer number that will be subtracted to the value at the key
    /// - Parameter callback: callback containing the value of the key after the increment
    public func decr(_ key: String, by: Int=1, callback: (Int?, NSError?) -> Void) {
        issueCommand("DECRBY", key, String(by)) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Returns the value of all specified keys.
    ///
    /// - Parameter keys: variadic parameter of key values
    /// - Parameter callback: function returning a list of values
    public func mget(_ keys: String..., callback: ([RedisString?]?, NSError?) -> Void) {
        
        var command = ["MGET"]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    /// Sets a set key value pairs in the database
    ///
    /// - Parameter keyValuePairs: a tuple variadic parameter containing a keys and values
    /// - Parameter exists: will set the value only if the key already exists if true
    /// - Parameter callback: a callback function with whether it was successful
    public func mset(_ keyValuePairs: (String, String)..., exists: Bool=true, callback: (Bool, NSError?) -> Void) {
        msetArrayOfKeyValues(keyValuePairs, exists: exists, callback: callback)
    }
    
    /// Sets a set key value pairs in the database
    ///
    /// - Parameter keyValuePairs: a list of tuples containing a keys and values
    /// - Parameter exists: will set the value only if the key already exists if true
    /// - Parameter callback: a callback function with whether it was successful
    public func msetArrayOfKeyValues(_ keyValuePairs: [(String, String)], exists: Bool=true, callback: (Bool, NSError?) -> Void) {
        var command = [exists ? "MSET" : "MSETNX"]
        for (key, value) in keyValuePairs {
            command.append(key)
            command.append(value)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            if  exists {
                let (ok, error) = self.redisOkResponseHandler(response, nilOk: false)
                callback(ok, _: error)
            }
            else {
                self.redisBoolResponseHandler(response, callback: callback)
            }
        }
    }
    
    /// Sets the given keys to their respective values. MSET replaces existing values with new values
    ///
    /// - Parameter keyValuePairs: a list of tuples containing a keys and values
    /// - Parameter exists: will set the value only if the key already exists if true
    /// - Parameter callback: a callback function with whether it was successful
    public func mset(_ keyValuePairs: (String, RedisString)..., exists: Bool=true, callback: (Bool, NSError?) -> Void) {
        msetArrayOfKeyValues(keyValuePairs, exists: exists, callback: callback)
    }
    
    /// Sets the given keys to their respective values. MSET replaces existing values with new values
    ///
    /// - Parameter keyValuePairs: a list of tuples containing a keys and values
    /// - Parameter exists: will set the value only if the key already exists if true
    /// - Parameter callback: a callback function with whether it was successful
    public func msetArrayOfKeyValues(_ keyValuePairs: [(String, RedisString)], exists: Bool=true, callback: (Bool, NSError?) -> Void) {
        var command = [RedisString(exists ? "MSET" : "MSETNX")]
        for (key, value) in keyValuePairs {
            command.append(RedisString(key))
            command.append(value)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            if  exists {
                let (ok, error) = self.redisOkResponseHandler(response, nilOk: false)
                callback(ok, _: error)
            }
            else {
                self.redisBoolResponseHandler(response, callback: callback)
            }
        }
    }
    
    /// If the key already exists and is a string, this command appends the value at the end of the string
    ///
    /// - Parameter key: the key as a String
    /// - Parameter value: the value to set
    /// - Parameter callback: a callback returning the length of the string after the append operation
    public func append(_ key: String, value: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("APPEND", key, value) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Returns the substring of the string value stored at key, determined by the offsets start and end.
    /// Negative offsets can be used in order to provide an offset starting from the end of the string.
    ///
    /// - Parameter key: the key as a String
    /// - Parameter start: Integer index for the start of the string
    /// - Parameter end: Integer index for the end of the string
    /// - Parameter callback: a callback returning the substring
    public func getrange(_ key: String, start: Int, end: Int, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("GETRANGE", key, String(start), String(end)) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Overwrites part of the string stored at key, starting at the specified offset, for the entire length of value
    ///
    /// - Parameter key: the key as a String
    /// - Parameter offset: Integer index for the start of the string
    /// - Parameter callback: a callback returning the length of the string after it was modified by the command
    public func setrange(_ key: String, offset: Int, value: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("SETRANGE", key, String(offset), value) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Returns the length of the string value stored at key
    ///
    /// - Parameter key: the key as a String
    /// - Parameter callback: a callback returning the length of the string
    public func strlen(_ key: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("STRLEN", key) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Returns the bit value at offset in the string value stored at key.
    ///
    /// - Parameter key: the key as a String
    /// - Parameter offset: offset in the string value
    /// - Parameter callback: a callback returning the bit value stored at offset
    public func getbit(_ key: String, offset: Int, callback: (Bool, NSError?) -> Void) {
        issueCommand("GETBIT", key, String(offset)) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    /// Sets or clears the bit value at offset in the string value stored at key.
    ///
    /// - Parameter key: the key as a String
    /// - Parameter offset: offset in the string value
    /// - Parameter value: the bit value to set
    /// - Parameter callback: a callback returning the original bit value stored at offset
    public func setbit(_ key: String, offset: Int, value: Bool, callback: (Bool, NSError?) -> Void) {
        issueCommand("SETBIT", key, String(offset), value ? "1" : "0") {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    /// Count the number of set bits (population counting) in a string.
    ///
    /// - Parameter key: the key as a String
    /// - Parameter callback: a callback returning the number of bits set to 1.
    public func bitcount(_ key: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("BITCOUNT", key) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Count the number of set bits (population counting) in a string.
    ///
    /// - Parameter key: the key as a String
    /// - Parameter start: the starting index in the string
    /// - Parameter end: the end index in the string
    /// - Parameter callback: a callback returning the number of bits set to 1.
    public func bitcount(_ key: String, start: Int, end: Int, callback: (Int?, NSError?) -> Void) {
        issueCommand("BITCOUNT", key, String(start), String(end)) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Return the position of the first bit set to 1 or 0 in a string
    ///
    /// - Parameter key: the key as a String
    /// - Parameter bit: the value to compare against
    /// - Parameter callback: a callback returning the index in the string where bit is value of bit
    public func bitpos(_ key: String, bit:Bool, callback: (Int?, NSError?) -> Void) {
        issueCommand("BITPOS", key, bit ? "1" : "0") {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Return the position of the first bit set to 1 or 0 in a string
    ///
    /// - Parameter key: the key as a String
    /// - Parameter bit: the value to compare against
    /// - Parameter start: the starting index in the string
    /// - Parameter callback: a callback returning the index in the string where bit is value of bit
    public func bitpos(_ key: String, bit:Bool, start: Int, callback: (Int?, NSError?) -> Void) {
        issueCommand("BITPOS", key, bit ? "1" : "0", String(start)) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Return the position of the first bit set to 1 or 0 in a string
    ///
    /// - Parameter key: the key as a String
    /// - Parameter bit: the value to compare against
    /// - Parameter start: the starting index in the string
    /// - Parameter end: the ending index in the string
    /// - Parameter callback: a callback returning the index in the string where bit is value of bit
    public func bitpos(_ key: String, bit:Bool, start: Int, end: Int, callback: (Int?, NSError?) -> Void) {
        issueCommand("BITPOS", key, bit ? "1" : "0", String(start), String(end)) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Perform a bitwise AND operation between multiple keys and store the result in the destination key.
    ///
    /// - Parameter destKey: the key as a String
    /// - Parameter and: variadic parameter for list of AND operands
    /// - Parameter callback: a callback returning the size of the string stored in the destination key
    public func bitop(_ destKey: String, and: String..., callback: (Int?, NSError?) -> Void) {
        var command = ["BITOP", "AND", destKey]
        for key in and {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Perform a bitwise OR operation between multiple keys and store the result in the destination key.
    ///
    /// - Parameter destKey: the key as a String
    /// - Parameter and: variadic parameter for list of OR operands
    /// - Parameter callback: a callback returning the size of the string stored in the destination key
    public func bitop(_ destKey: String, or: String..., callback: (Int?, NSError?) -> Void) {
        var command = ["BITOP", "OR", destKey]
        for key in or {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Perform a bitwise XOR operation between multiple keys and store the result in the destination key.
    ///
    /// - Parameter destKey: the key as a String
    /// - Parameter and: variadic parameter for list of XOR operands
    /// - Parameter callback: a callback returning the size of the string stored in the destination key
    public func bitop(_ destKey: String, xor: String..., callback: (Int?, NSError?) -> Void) {
        var command = ["BITOP", "XOR", destKey]
        for key in xor {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Perform a bitwise NOT operation between multiple keys and store the result in the destination key.
    ///
    /// - Parameter destKey: the key as a String
    /// - Parameter and: variadic parameter for list of NOT operands
    /// - Parameter callback: a callback returning the size of the string stored in the destination key
    public func bitop(_ destKey: String, not: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("BITOP", "NOT", destKey, not) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Returns if a key exists
    ///
    /// - Parameter keys: the variadic parameter for a string of keys
    /// - Parameter callback: a callback returning 1 if the key exists
    public func exists(_ keys: String..., callback: (Int?, NSError?) -> Void) {
        var command = ["EXISTS"]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Move key from the currently selected database to the specified destination database.
    /// When key already exists in the destination database, or it does not exist in the source database,
    /// it does nothing. It is possible to use MOVE as a locking primitive because of this.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter callback: a callback returning 1 if the key was moved
    public func move(_ key: String, toDB: Int, callback: (Bool, NSError?) -> Void) {
        issueCommand("MOVE", key, String(toDB)) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    /// Renames key to newKey. It returns an error when the source and destination names are the same,
    /// or when key does not exist. If newKey already exists it is overwritten, when this happens RENAME
    /// executes an implicit DEL operation, so if the deleted key contains a very big value it may cause high
    /// latency even if RENAME itself is usually a constant-time operation.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter newKey: destination key value
    /// - Parameter callback: a callback returning 1 if the key was renamed
    public func rename(_ key: String, newKey: String, exists: Bool=true, callback: (Bool, NSError?) -> Void) {
        if  exists  {
            issueCommand("RENAME", key, newKey) {(response: RedisResponse) in
                let (renamed, error) = self.redisOkResponseHandler(response, nilOk: false)
                callback(renamed, _: error)
            }
        }
        else {
            issueCommand("RENAMENX", key, newKey) {(response: RedisResponse) in
                self.redisBoolResponseHandler(response, callback: callback)
            }
        }
    }
    
    /// Set a timeout on key. After the timeout has exprired, the key will automatically be deleted. A key with an
    /// associated timeout is often said to be volatile in Redis terminology.
    /// The timeout will only be cleared by commands that delete or overwrite the contents of the key, including
    /// DEL, SET, GETSET and all the *STORE commands.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter inTime: number of milliseconds expiration time
    /// - Parameter callback: callback function containing the value 1 if the timeout was set.
    public func expire(_ key: String, inTime: TimeInterval, callback: (Bool, NSError?) -> Void) {
        issueCommand("PEXPIRE", key, String(Int(inTime * 1000.0))) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    /// Set a timeout on key. After the timeout has exprired, the key will automatically be deleted. A key with an
    /// associated timeout is often said to be volatile in Redis terminology.
    /// The timeout will only be cleared by commands that delete or overwrite the contents of the key, including
    /// DEL, SET, GETSET and all the *STORE commands.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter atDate: timestamp for when the expiration happens
    /// - Parameter callback: callback function containing the value 1 if the timeout was set.
    public func expire(_ key: String, atDate: NSDate, callback: (Bool, NSError?) -> Void) {
        issueCommand("PEXPIREAT", key, String(Int(atDate.timeIntervalSince1970 * 1000.0))) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    /// Remove the existing timeout on key, turning the key from volatile (a key with an expire set)
    /// to persistent (a key that will never expire as no timeout is associated)
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter callback: callback function containing the value 1 if the timeout was removed.
    public func persist(_ key: String, callback: (Bool, NSError?) -> Void) {
        issueCommand("PERSIST", key) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    /// Like TTL this command returns the remaining time to live of a key that has an expire set,
    /// with the sole difference that TTL returns the amount of remaining time in seconds while PTTL
    /// returns it in milliseconds.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter callback: callback function containing the value in milliseconds for the remaining time to live
    ///   -2 if the key does not exist
    ///   -1 if the key exists but no associated expire.
    public func ttl(_ key: String, callback: (TimeInterval?, NSError?) -> Void) {
        issueCommand("PTTL", key) {(response: RedisResponse) in
            switch(response) {
            case .IntegerValue(let num):
                if  num >= 0  {
                    callback(TimeInterval(Double(num)/1000.0), nil)
                }
                else {
                    callback(TimeInterval(num), nil)
                }
            case .Error(let error):
                callback(nil, _: self.createError("Error: \(error)", code: 1))
            default:
                callback(nil, _: self.createUnexpectedResponseError(response))
            }
        }
    }
}
