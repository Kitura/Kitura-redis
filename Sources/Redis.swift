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

// MARK: Redis

public class Redis {
    
    ///
    /// Redis Serialization Protocol handle
    ///
    private var respHandle: RedisResp?
    
    ///
    /// Whether the client is connected or not
    ///
    public var connected: Bool {
        return respHandle != nil ? respHandle?.status == .connected : false
    }
    
    ///
    /// Initializes a Redis instance
    ///
    public init () { }
    
    ///
    /// Connects to a redis server
    ///
    /// - Parameter ipAddress: the server IP address
    /// - Parameter port: port number
    /// - Parameter callback: callback function for on completion
    ///
    public func connect (host: String, port: Int32, callback: (NSError?) -> Void) {
        
        var error: NSError? = nil
        
        respHandle = RedisResp(host: host, port: port)
        if  respHandle!.status != .connected {
            error = createError("Failed to connect to Redis server", code: 2)
        }
        callback(error)
    }
    
    ///
    /// Authenticate against the server
    ///
    /// - Parameter pswd: String for the password
    /// - Parameter callback: callback function that is called after authenticating
    ///
    public func auth(_ pswd: String, callback: (NSError?) -> Void) {
        
        issueCommand("AUTH", pswd) {(response: RedisResponse) in
            let (_, error) = self.redisOkResponseHandler(response, nilOk: false)
            callback(error)
        }
    }
    
    ///
    /// Selects the database to use
    ///
    /// - Parameter db: numeric index for the database
    /// - Parameter callback: callback function for after the database is selected
    ///
    public func select(_ db: Int, callback: (NSError?) -> Void) {
        
        issueCommand("SELECT", String(db)) {(response: RedisResponse) in
            let (_, error) = self.redisOkResponseHandler(response, nilOk: false)
            callback(error)
        }
    }
    
    ///
    /// Ping the server to test if a connection is still alive
    ///
    /// - Parameter pingStr: String for the ping message
    /// - Parameter callback: callback function for after the pong is received
    ///
    public func ping(_ pingStr: String?=nil, callback: (NSError?) -> Void) {
        
        var command = ["PING"]
        if  let pingStr = pingStr  {
            command.append(pingStr)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            switch(response) {
            case .Status(let str):
                if  str == "PONG"  {
                    callback(nil)
                }
                else {
                    callback(self.createError("Status result other than 'PONG' received from Redis (\(str))", code: 2))
                }
            case .StringValue(let str):
                if  pingStr != nil  &&  pingStr! == str.asString {
                    callback(nil)
                }
                else {
                    callback(self.createError("String result other than '\(pingStr)' received from Redis (\(str))", code: 2))
                }
            case .Error(let error):
                callback(self.createError("Error: \(error)", code: 1))
            default:
                callback(self.createUnexpectedResponseError(response))
            }
        }
    }
    
    ///
    /// Echos a message
    ///
    /// - Parameter str: String for the message
    /// - Parameter callback: callback function with the response
    ///
    public func echo(_ str: String, callback: (RedisString?, NSError?) -> Void) {
        
        issueCommand("ECHO", str) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Returns information and statistics about the server
    ///
    /// Returns: Bulk string reply: as a collection of text lines.
    ///
    public func info(callback: (RedisString?, NSError?) -> Void) {
        issueCommand("INFO") {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Returns information and statistics about the server
    ///
    /// Returns: RedisInfo reply: Struct containing some client and server information
    ///
    public func info(callback: (RedisInfo?, NSError?) -> Void) {
        issueCommand("INFO") {(response: RedisResponse) in
            self.redisDictionaryResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Get the value of key.
    ///
    /// - Parameter key: String for the key name
    /// - Parameter callback: callback function with the value
    ///
    public func get(_ key: String, callback: (RedisString?, NSError?) -> Void) {
        
        issueCommand("GET", key) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Atomically sets key to value and returns the old value stored at key.
    ///
    /// - Parameter key: String for the key name
    /// - Parameter value: String value to set
    /// - Parameter callback: callback function with the old value
    ///
    public func getSet(_ key: String, value: String, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("GETSET", key, value) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Atomically sets key to value and returns the old value stored at key.
    ///
    /// - Parameter key: String for the key name
    /// - Parameter value: RedisString value to set
    /// - Parameter callback: callback function with the old value
    ///
    public func getSet(_ key: String, value: RedisString, callback: (RedisString?, NSError?) -> Void) {
        issueCommand(RedisString("GETSET"), RedisString(key), value) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    
    ///
    /// Set key to hold the string value. If key already holds a value, it is overwritten.
    ///
    /// - Parameter key: String for the key name
    /// - Parameter value: String value to set
    /// - Parameter exists: if true will only set the key if it already exists
    /// - Parameter expiresIn: Set the specified expire time, in milliseconds
    /// - Parameter callback: callback function after setting the value
    ///
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
    
    ///
    /// Set key to hold the string value. If key already holds a value, it is overwritten.
    ///
    /// - Parameter key: String for the key name
    /// - Parameter value: RedisString value to set
    /// - Parameter exists: if true will only set the key if it already exists
    /// - Parameter expiresIn: Set the specified expire time, in milliseconds
    /// - Parameter callback: callback function after setting the value
    ///
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
    
    ///
    /// Removes the specified keys. A key is ignored if it does not exist
    ///
    /// - Parameter keys: Variadic parameter as a list of Strings
    /// - Parameter callback: callback function after deleting item
    ///
    public func del(_ keys: String..., callback: (Int?, NSError?) -> Void) {
        
        var command = ["DEL"]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Removes the specified keys. A key is ignored if it does not exist
    ///
    /// - Parameter keys: Variadic parameter as a list of Strings
    /// - Parameter callback: callback function after deleting item
    ///
    public func del(_ keys: RedisString..., callback: (Int?, NSError?) -> Void) {
        
        var command = [RedisString("DEL")]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Increments the number stored at key by an increment. If the key does not exist, it is set
    /// to 0 before performing the operation.
    /// **Note this is a string operation since Redis does not have a dedicated integer type**
    ///
    /// - Parameter key: String for the key name
    /// - Parameter by: number that will be added to the value at the key
    /// - Parameter callback: callback containing the value of the key after the increment
    ///
    public func incr(_ key: String, by: Int=1, callback: (Int?, NSError?) -> Void) {
        
        issueCommand("INCRBY", key, String(by)) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Increments the floating point number stored at key by an increment.
    /// If the key does not exist, it is set to 0 before performing the operation.
    /// **Note this is a string operation since Redis does not have a dedicated float type**
    ///
    /// - Parameter key: String for the key name
    /// - Parameter by: Floating point number that will be added to the value at the key
    /// - Parameter callback: callback containing the value of the key after the increment
    ///
    public func incr(_ key: String, byFloat: Float, callback: (RedisString?, NSError?) -> Void) {
        
        issueCommand("INCRBYFLOAT", key, String(byFloat)) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Decrements the integer number stored at key by an value.
    /// If the key does not exist, it is set to 0 before performing the operation.
    /// **Note this is a string operation since Redis does not have a dedicated float type**
    ///
    /// - Parameter key: String for the key name
    /// - Parameter by: Integer number that will be subtracted to the value at the key
    /// - Parameter callback: callback containing the value of the key after the increment
    ///
    public func decr(_ key: String, by: Int=1, callback: (Int?, NSError?) -> Void) {
        issueCommand("DECRBY", key, String(by)) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Returns the value of all specified keys.
    ///
    /// - Parameter keys: variadic parameter of key values
    /// - Parameter callback: function returning a list of values
    ////
    public func mget(_ keys: String..., callback: ([RedisString?]?, NSError?) -> Void) {
        
        var command = ["MGET"]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Sets a set key value pairs in the database
    ///
    /// - Parameter keyValuePairs: a tuple variadic parameter containing a keys and values
    /// - Parameter exists: will set the value only if the key already exists if true
    /// - Parameter callback: a callback function with whether it was successful
    ///
    public func mset(_ keyValuePairs: (String, String)..., exists: Bool=true, callback: (Bool, NSError?) -> Void) {
        msetArrayOfKeyValues(keyValuePairs, exists: exists, callback: callback)
    }
    
    ///
    /// Sets a set key value pairs in the database
    ///
    /// - Parameter keyValuePairs: a list of tuples containing a keys and values
    /// - Parameter exists: will set the value only if the key already exists if true
    /// - Parameter callback: a callback function with whether it was successful
    ///
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
    
    ///
    /// Sets the given keys to their respective values. MSET replaces existing values with new values
    ///
    /// - Parameter keyValuePairs: a list of tuples containing a keys and values
    /// - Parameter exists: will set the value only if the key already exists if true
    /// - Parameter callback: a callback function with whether it was successful
    ///
    public func mset(_ keyValuePairs: (String, RedisString)..., exists: Bool=true, callback: (Bool, NSError?) -> Void) {
        msetArrayOfKeyValues(keyValuePairs, exists: exists, callback: callback)
    }
    
    ///
    /// Sets the given keys to their respective values. MSET replaces existing values with new values
    ///
    /// - Parameter keyValuePairs: a list of tuples containing a keys and values
    /// - Parameter exists: will set the value only if the key already exists if true
    /// - Parameter callback: a callback function with whether it was successful
    ///
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
    
    ///
    /// If the key already exists and is a string, this command appends the value at the end of the string
    ///
    /// - Parameter key: the key as a String
    /// - Parameter value: the value to set
    /// - Parameter callback: a callback returning the length of the string after the append operation
    ///
    public func append(_ key: String, value: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("APPEND", key, value) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Returns the substring of the string value stored at key, determined by the offsets start and end.
    /// Negative offsets can be used in order to provide an offset starting from the end of the string.
    ///
    /// - Parameter key: the key as a String
    /// - Parameter start: Integer index for the start of the string
    /// - Parameter end: Integer index for the end of the string
    /// - Parameter callback: a callback returning the substring
    ///
    public func getrange(_ key: String, start: Int, end: Int, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("GETRANGE", key, String(start), String(end)) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Overwrites part of the string stored at key, starting at the specified offset, for the entire length of value
    ///
    /// - Parameter key: the key as a String
    /// - Parameter offset: Integer index for the start of the string
    /// - Parameter callback: a callback returning the length of the string after it was modified by the command
    ///
    
    public func setrange(_ key: String, offset: Int, value: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("SETRANGE", key, String(offset), value) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Returns the length of the string value stored at key
    ///
    /// - Parameter key: the key as a String
    /// - Parameter callback: a callback returning the length of the string
    ///
    public func strlen(_ key: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("STRLEN", key) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Returns the bit value at offset in the string value stored at key.
    ///
    /// - Parameter key: the key as a String
    /// - Parameter offset: offset in the string value
    /// - Parameter callback: a callback returning the bit value stored at offset
    ///
    public func getbit(_ key: String, offset: Int, callback: (Bool, NSError?) -> Void) {
        issueCommand("GETBIT", key, String(offset)) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Sets or clears the bit value at offset in the string value stored at key.
    ///
    /// - Parameter key: the key as a String
    /// - Parameter offset: offset in the string value
    /// - Parameter value: the bit value to set
    /// - Parameter callback: a callback returning the original bit value stored at offset
    ///
    public func setbit(_ key: String, offset: Int, value: Bool, callback: (Bool, NSError?) -> Void) {
        issueCommand("SETBIT", key, String(offset), value ? "1" : "0") {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Count the number of set bits (population counting) in a string.
    ///
    /// - Parameter key: the key as a String
    /// - Parameter callback: a callback returning the number of bits set to 1.
    ///
    public func bitcount(_ key: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("BITCOUNT", key) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Count the number of set bits (population counting) in a string.
    ///
    /// - Parameter key: the key as a String
    /// - Parameter start: the starting index in the string
    /// - Parameter end: the end index in the string
    /// - Parameter callback: a callback returning the number of bits set to 1.
    ///
    public func bitcount(_ key: String, start: Int, end: Int, callback: (Int?, NSError?) -> Void) {
        issueCommand("BITCOUNT", key, String(start), String(end)) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Return the position of the first bit set to 1 or 0 in a string
    ///
    /// - Parameter key: the key as a String
    /// - Parameter bit: the value to compare against
    /// - Parameter callback: a callback returning the index in the string where bit is value of bit
    ///
    public func bitpos(_ key: String, bit:Bool, callback: (Int?, NSError?) -> Void) {
        issueCommand("BITPOS", key, bit ? "1" : "0") {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Return the position of the first bit set to 1 or 0 in a string
    ///
    /// - Parameter key: the key as a String
    /// - Parameter bit: the value to compare against
    /// - Parameter start: the starting index in the string
    /// - Parameter callback: a callback returning the index in the string where bit is value of bit
    ///
    public func bitpos(_ key: String, bit:Bool, start: Int, callback: (Int?, NSError?) -> Void) {
        issueCommand("BITPOS", key, bit ? "1" : "0", String(start)) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Return the position of the first bit set to 1 or 0 in a string
    ///
    /// - Parameter key: the key as a String
    /// - Parameter bit: the value to compare against
    /// - Parameter start: the starting index in the string
    /// - Parameter end: the ending index in the string
    /// - Parameter callback: a callback returning the index in the string where bit is value of bit
    ///
    public func bitpos(_ key: String, bit:Bool, start: Int, end: Int, callback: (Int?, NSError?) -> Void) {
        issueCommand("BITPOS", key, bit ? "1" : "0", String(start), String(end)) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Perform a bitwise AND operation between multiple keys and store the result in the destination key.
    ///
    /// - Parameter destKey: the key as a String
    /// - Parameter and: variadic parameter for list of AND operands
    /// - Parameter callback: a callback returning the size of the string stored in the destination key
    ///
    public func bitop(_ destKey: String, and: String..., callback: (Int?, NSError?) -> Void) {
        var command = ["BITOP", "AND", destKey]
        for key in and {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Perform a bitwise OR operation between multiple keys and store the result in the destination key.
    ///
    /// - Parameter destKey: the key as a String
    /// - Parameter and: variadic parameter for list of OR operands
    /// - Parameter callback: a callback returning the size of the string stored in the destination key
    ///
    public func bitop(_ destKey: String, or: String..., callback: (Int?, NSError?) -> Void) {
        var command = ["BITOP", "OR", destKey]
        for key in or {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Perform a bitwise XOR operation between multiple keys and store the result in the destination key.
    ///
    /// - Parameter destKey: the key as a String
    /// - Parameter and: variadic parameter for list of XOR operands
    /// - Parameter callback: a callback returning the size of the string stored in the destination key
    ///
    public func bitop(_ destKey: String, xor: String..., callback: (Int?, NSError?) -> Void) {
        var command = ["BITOP", "XOR", destKey]
        for key in xor {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Perform a bitwise NOT operation between multiple keys and store the result in the destination key.
    ///
    /// - Parameter destKey: the key as a String
    /// - Parameter and: variadic parameter for list of NOT operands
    /// - Parameter callback: a callback returning the size of the string stored in the destination key
    ///
    public func bitop(_ destKey: String, not: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("BITOP", "NOT", destKey, not) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Returns if a key exists
    ///
    /// - Parameter keys: the variadic parameter for a string of keys
    /// - Parameter callback: a callback returning 1 if the key exists
    ///
    public func exists(_ keys: String..., callback: (Int?, NSError?) -> Void) {
        var command = ["EXISTS"]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Move key from the currently selected database to the specified destination database.
    /// When key already exists in the destination database, or it does not exist in the source database,
    /// it does nothing. It is possible to use MOVE as a locking primitive because of this.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter callback: a callback returning 1 if the key was moved
    ///
    public func move(_ key: String, toDB: Int, callback: (Bool, NSError?) -> Void) {
        issueCommand("MOVE", key, String(toDB)) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Renames key to newKey. It returns an error when the source and destination names are the same,
    /// or when key does not exist. If newKey already exists it is overwritten, when this happens RENAME
    /// executes an implicit DEL operation, so if the deleted key contains a very big value it may cause high
    /// latency even if RENAME itself is usually a constant-time operation.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter newKey: destination key value
    /// - Parameter callback: a callback returning 1 if the key was renamed
    ///
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
    
    ///
    /// Set a timeout on key. After the timeout has exprired, the key will automatically be deleted. A key with an
    /// associated timeout is often said to be volatile in Redis terminology.
    /// The timeout will only be cleared by commands that delete or overwrite the contents of the key, including
    /// DEL, SET, GETSET and all the *STORE commands.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter inTime: number of milliseconds expiration time
    /// - Parameter callback: callback function containing the value 1 if the timeout was set.
    ///
    public func expire(_ key: String, inTime: TimeInterval, callback: (Bool, NSError?) -> Void) {
        issueCommand("PEXPIRE", key, String(Int(inTime * 1000.0))) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Set a timeout on key. After the timeout has exprired, the key will automatically be deleted. A key with an
    /// associated timeout is often said to be volatile in Redis terminology.
    /// The timeout will only be cleared by commands that delete or overwrite the contents of the key, including
    /// DEL, SET, GETSET and all the *STORE commands.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter atDate: timestamp for when the expiration happens
    /// - Parameter callback: callback function containing the value 1 if the timeout was set.
    ///
    public func expire(_ key: String, atDate: NSDate, callback: (Bool, NSError?) -> Void) {
        issueCommand("PEXPIREAT", key, String(Int(atDate.timeIntervalSince1970 * 1000.0))) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Remove the existing timeout on key, turning the key from volatile (a key with an expire set)
    /// to persistent (a key that will never expire as no timeout is associated)
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter callback: callback function containing the value 1 if the timeout was removed.
    ///
    public func persist(_ key: String, callback: (Bool, NSError?) -> Void) {
        issueCommand("PERSIST", key) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Like TTL this command returns the remaining time to live of a key that has an expire set,
    /// with the sole difference that TTL returns the amount of remaining time in seconds while PTTL
    /// returns it in milliseconds.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter callback: callback function containing the value in milliseconds for the remaining time to live
    ///   -2 if the key does not exist
    ///   -1 if the key exists but no associated expire.
    ///
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
    
    //
    // MARK: Hash functions
    //
    
    ///
    /// Removes the specified fields from the hash stored at key. Specified fields that do not
    /// exist within this hash are ignored. If key does not exist, it is treated as an empty hash
    /// and this command returns 0.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter fields: removes the specified fields as a variadic parameter
    /// - Parameter callback: callback function containing the number of fields that were removed from
    ///             the hash, not including specified but non existing fields.
    ///
    public func hdel(_ key: String, fields: String..., callback: (Int?, NSError?) -> Void) {
        var command = ["HDEL", key]
        for field in fields {
            command.append(field)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Returns if field is an existing field in the hash stored at key
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter field: String value for field
    /// - Parameter callback: a callback function returning 1 if the hash contains field
    ///             0 if the hash does not contain field, or key does not exist
    ///
    public func hexists(_ key: String, field: String, callback: (Bool, NSError?) -> Void) {
        issueCommand("HEXISTS", key, field) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Returns the value associated with field in the hash stored at key.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter field: String value for field
    /// - Parameter callback: a callback function returning the value associated with the field, or nil
    ///             when field is not present in the hash or key does not exist
    ///
    public func hget(_ key: String, field: String, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("HGET", key, field) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Returns all fields and values of the hash stored at key. In the returned value, every field
    /// name is followed by its value, so the length of the reply is twice the size of the hash.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter callback: a callback function returning the list of fields and their values stored in the
    ///             hash, or an empty list when key does not exist.
    ///
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
    
    ///
    /// Increments the number stored at field in the hash stored at key by increment
    ///
    /// - Parameter key: the String Parameter for they key
    /// - Parameter by: the value to increment by
    /// - Parameter callback: a function returning the value at field after the increment operation
    ///
    public func hincr(_ key: String, field: String, by: Int, callback: (Int?, NSError?) -> Void) {
        issueCommand("HINCRBY", key, field, String(by)) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Increments the number stored at field in the hash stored at key by floating point increment
    ///
    /// - Parameter key: the String Parameter for they key
    /// - Parameter by: the value to increment by (Float)
    /// - Parameter callback: a function returning the value at field after the increment operation
    ///
    public func hincr(_ key: String, field: String, byFloat: Float, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("HINCRBYFLOAT", key, field, String(byFloat)) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Returns all field names in the hash stored at key
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter callback: a function returning the list of fields in the hash
    ///
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
    
    ///
    /// Returns the number of fields contained in the hash stored at key
    ///
    /// - Parameter key: the String Parameter for the key
    /// - Parameter callback: function returning the number of fields in the hash, or 0 when key does not exist
    ///
    public func hlen(_ key: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("HLEN", key) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Returns the values associated with the specified fields in the hash stored at key.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter fields: a variadic parameter for the fields
    /// - Parameter callback: a function returning a list of values associated with the given fields
    ///
    public func hmget(_ key: String, fields: String..., callback: ([RedisString?]?, NSError?) -> Void) {
        var command = ["HMGET", key]
        for field in fields {
            command.append(field)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Sets the specified fields to their respective values in the hash stored at key.
    /// This command overwrites any existing fields in the hash. If key does not exist,
    /// a new key holding a hash is created.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter fieldValuePairs: a variadic parameter for the list of key values to set
    /// - Parameter callback: a function returning if successful
    ///
    public func hmset(_ key: String, fieldValuePairs: (String, String)..., callback: (Bool, NSError?) -> Void) {
        hmsetArrayOfKeyValues(key, fieldValuePairs: fieldValuePairs, callback: callback)
    }
    
    ///
    /// Sets the specified fields to their respective values in the hash stored at key.
    /// This command overwrites any existing fields in the hash. If key does not exist,
    /// a new key holding a hash is created.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter fieldValuePairs: a list of key values to set
    /// - Parameter callback: a function returning if successful
    ///
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
    
    ///
    /// Sets the specified fields to their respective values in the hash stored at key.
    /// This command overwrites any existing fields in the hash. If key does not exist,
    /// a new key holding a hash is created.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter fieldValuePairs: a list of key values to set
    /// - Parameter callback: a function returning if successful
    ///
    public func hmset(_ key: String, fieldValuePairs: (String, RedisString)..., callback: (Bool, NSError?) -> Void) {
        hmsetArrayOfKeyValues(key, fieldValuePairs: fieldValuePairs, callback: callback)
    }
    
    ///
    /// Sets the specified fields to their respective values in the hash stored at key.
    /// This command overwrites any existing fields in the hash. If key does not exist,
    /// a new key holding a hash is created.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter fieldValuePairs: a list of key values to set
    /// - Parameter callback: a function returning if successful
    ///
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
    
    ///
    /// Sets the specified fields to their respective values in the hash stored at key.
    /// This command overwrites any existing fields in the hash. If key does not exist,
    /// a new key holding a hash is created.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter field: the field name to set
    /// - Parameter value: the value to set in the field
    /// - Parameter exists: will set the value only if the field exists if true
    /// - Parameter callback: a function returning if successful
    ///
    public func hset(_ key: String, field: String, value: String, exists: Bool=true, callback: (Bool, NSError?) -> Void) {
        issueCommand(exists ? "HSET" : "HSETNX", key, field, value) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Sets the specified fields to their respective values in the hash stored at key.
    /// This command overwrites any existing fields in the hash. If key does not exist,
    /// a new key holding a hash is created.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter field: the field name to set
    /// - Parameter value: the value to set in the field
    /// - Parameter exists: will set the value only if the field exists if true
    /// - Parameter callback: a function returning if successful
    ///
    public func hset(_ key: String, field: String, value: RedisString, exists: Bool=true, callback: (Bool, NSError?) -> Void) {
        issueCommand(RedisString(exists ? "HSET" : "HSETNX"), RedisString(key), RedisString(field), value) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Returns the string length of the value associated with field in the hash stored at key.
    /// if the key or the field do not exist, 0 is returned.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter field: the field name
    /// - Parameter callback: a function returning the string length of the value associated with field
    ///
    public func hstrlen(_ key: String, field: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("HSTRLEN", key, field) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Returns all values in the hash stored at key.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter callback: a function returning a list of values in the hash
    ///
    public func hvals(_ key: String, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand("HVALS", key) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Returns the sorted set cardinality (number of elements) of the sorted set stored at key.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter callback: a function returning the sorted set cardinality of the sorted set
    ///
    public func zcard(_ key: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("ZCARD", key) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Removes the specified members from the sorted set stored at key. Non existing members are ignored.
    /// An error is returned when key exists and does not hold a sorted set.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter members: a  variadic parameter containing the member(s)
    /// - Parameter callback: a function returning the number of members removed from the sorted set
    ///
    public func zrem(_ key: String, members: String..., callback: (Int?, NSError?) -> Void) {
        zremArrayOfMembers(key, members: members, callback: callback)
    }
    
    ///
    /// Removes the specified members from the sorted set stored at key. Non existing members are ignored.
    /// An error is returned when key exists and does not hold a sorted set.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter members: a  variadic parameter containing the member(s)
    /// - Parameter callback: a function returning the number of members removed from the sorted set
    ///
    public func zremArrayOfMembers(_ key: String, members: [String], callback: (Int?, NSError?) -> Void) {
        var command = ["ZREM"]
        command.append(key)
        for element in members {
            command.append(element)
        }
        issueCommandInArray(command) { (response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    ///
    /// Returns the specified range of elements in the sorted set stored at key
    ///
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter start: the start of index of the set
    /// - Parameter stop:  the end of the index of the set
    /// - Parameter callback: a function returning the array of specified range of elements in the sorted set
    ///
    public func zrange(_ key: String, start: Int, stop: Int, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand("ZRANGE", key, String(start), String(stop)) { (response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Return the number of elements added to the sorted sets, not including elements already existing for which the score was
    /// updated.
    ///
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter tuples: a tuple variadic parameter containing a score(s) and member(s)
    /// - Parameter callback: a function returning the number of elements added to the sorted sets
    
    public func zadd(_ key: String, tuples: (Int,String)..., callback: (Int?, NSError?) -> Void) {
        zaddArrayOfScoreMembers(key, tuples: tuples, callback: callback)
    }
    
    ///
    /// Return the number of elements added to the sorted sets, not including elements already existing for which the score was
    /// updated.
    ///
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter tuples: a tuple variadic parameter containing a score(s) and member(s)
    /// - Parameter callback: a function returning the number of elements added to the sorted sets
    
    public func zaddArrayOfScoreMembers(_ key: String, tuples: [(Int,String)], callback: (Int?, NSError?) -> Void) {
        var command = ["ZADD"]
        command.append(key)
        for tuple in tuples {
            command.append(String(tuple.0))
            command.append(tuple.1)
        }
        issueCommandInArray(command) { (response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Removes all elements in the sorted set stored at key with a score between min and max (inclusive).
    ///
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter min: the String parameter for the min
    /// - Parameter max: the String parameter for the max
    /// - Parameter callback: a function returning removes all elements in the sorted set
    
    public func zremrangebyscore(_ key: String, min: String, max: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("ZREMRANGEBYSCORE",key, min, max) { (response) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Delete all the keys of the currently selected DB. This command never fails.
    ///
    ///
    /// - Parameter callback: a function returning response
    ///
    public func flushdb(callback: (Bool, NSError?) -> Void) {
        issueCommand("FLUSHDB") { (response: RedisResponse) in
            let (ok, error) = self.redisOkResponseHandler(response)
            callback(ok, _: error)
        }
    }
    
    

    //
    // MARK: List functions
    //
    
    ///
    /// Retrieve an item from one of many lists, potentially blocking until one of the lists has an element
    ///
    /// - Parameter keys: the keys of the lists to check for an element
    /// - Parameter timeout: Amount of time to wait or zero to wait for ever
    ///
    public func blpop(_ keys: String..., timeout: TimeInterval, callback: ([RedisString?]?, NSError?) -> Void) {
        
        var command = ["BLPOP"]
        for key in keys {
            command.append(key)
        }
        command.append(String(Int(timeout)))
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }///
    /// Retrieve an item from the end of one of many lists, potentially blocking until one of the lists has an element
    ///
    /// - Parameter keys: the keys of the lists to check for an element
    /// - Parameter timeout: Amount of time to wait or zero to wait for ever
    ///
    public func brpop(_ keys: String..., timeout: TimeInterval, callback: ([RedisString?]?, NSError?) -> Void) {
        
        var command = ["BRPOP"]
        for key in keys {
            command.append(key)
        }
        command.append(String(Int(timeout)))
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Remove and return the last value of a list and push it onto another list, blocking until there is an item to pop
    ///
    /// - Parameter source: The list to pop an item from
    /// - Parameter destination: The list to push the poped item ontoParameter source: The list to pop an item from
    /// - Parameter destination: The list to push the poped item onto
    ///
    public func brpoplpush(_ source: String, destination: String, timeout: TimeInterval, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("BRPOPLPUSH", source, destination, String(Int(timeout))) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Retrieve an element from a list by index
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter index: The index of the element to retrieve
    ///
    public func lindex(_ key: String, index: Int, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("LINDEX", key, String(index)) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Insert a value into a list before or after a pivot
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter before: Whether the value is inserted before or after the pivot
    /// - Parameter pivot: The pivot around which the value will be inserted
    /// - Parameter value: The value to be inserted
    ///
    public func linsert(_ key: String, before: Bool, pivot: String, value: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("LINSERT", key, (before ? "BEFORE" : "AFTER"), pivot, value) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Insert a value into a list before or after a pivot
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter before: Whether the value is inserted before or after the pivot
    /// - Parameter pivot: The pivot around which the value will be inserted
    /// - Parameter value: The value to be inserted
    ///
    public func linsert(_ key: String, before: Bool, pivot: RedisString, value: RedisString, callback: (Int?, NSError?) -> Void) {
        issueCommand(RedisString("LINSERT"), RedisString(key), RedisString(before ? "BEFORE" : "AFTER"), pivot, value) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Get the length of a list
    ///
    /// - Parameter key: the String parameter for the key
    ///
    public func llen(_ key: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("LLEN", key) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Pop a value from a list
    ///
    /// - Parameter key: the String parameter for the key
    ///
    public func lpop(_ key: String, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("LPOP", key) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Push a set of values on to a list
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: A variadic parameter of the values to be pushed on to the list
    ///
    public func lpush(_ key: String, values: String..., callback: (Int?, NSError?) -> Void) {
        lpushArrayOfValues(key, values: values, callback: callback)
    }
    
    ///
    /// Push a set of values on to a list
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: An array parameter of the values to be pushed on to the list
    ///
    public func lpushArrayOfValues(_ key: String, values: [String], callback: (Int?, NSError?) -> Void) {
        var command = ["LPUSH", key]
        for value in values {
            command.append(value)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Push a set of values on to a list
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: A variadic parameter of the values to be pushed on to the list
    ///
    public func lpush(_ key: String, values: RedisString..., callback: (Int?, NSError?) -> Void) {
        lpushArrayOfValues(key, values: values, callback: callback)
    }
    
    ///
    /// Push a set of values on to a list
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: An array parameter of the values to be pushed on to the list
    ///
    public func lpushArrayOfValues(_ key: String, values: [RedisString], callback: (Int?, NSError?) -> Void) {
        var command = [RedisString("LPUSH"), RedisString(key)]
        for value in values {
            command.append(value)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Push a value on to a list, only if the list exists
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: An array parameter of the values to be pushed on to the list
    ///
    public func lpushx(_ key: String, value: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("LPUSHX", key, value) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Push a value on to a list, only if the list exists
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: An array parameter of the values to be pushed on to the list
    ///
    public func lpushx(_ key: String, value: RedisString, callback: (Int?, NSError?) -> Void) {
        issueCommand(RedisString("LPUSHX"), RedisString(key), value) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Retrieve a group of elements from a list as specified by a range
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter start: The index to start retrieving from
    /// - Parameter end: The index to stop at
    ///
    public func lrange(_ key: String, start: Int, end: Int, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand("LRANGE", key, String(start), String(end)) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Remove a number of elements that match the supplied value from the list
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter count: the number of elements to remove
    /// - Parameter value: the value of the eleemnts to remove
    ///
    public func lrem(_ key: String, count: Int, value: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("LREM", key, String(count), value) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Remove a number of elements that match the supplied value from the list
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter count: the number of elements to remove
    /// - Parameter value: the value of the eleemnts to remove
    ///
    public func lrem(_ key: String, count: Int, value: RedisString, callback: (Int?, NSError?) -> Void) {
        issueCommand(RedisString("LREM"), RedisString(key), RedisString(count), value) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Set a value in a list to a new value
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter index: the index of the value in the list to be updated
    /// - Parameter value: The new value for the element of the list
    ///
    public func lset(_ key: String, index: Int, value: String, callback: (Bool, NSError?) -> Void) {
        issueCommand("LSET", key, String(index), value) {(response: RedisResponse) in
            let (ok, error) = self.redisOkResponseHandler(response)
            callback(ok, _: error)
        }
    }
    
    ///
    /// Set a value in a list to a new value
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter index: the index of the value in the list to be updated
    /// - Parameter value: The new value for the element of the list
    ///
    public func lset(_ key: String, index: Int, value: RedisString, callback: (Bool, NSError?) -> Void) {
        issueCommand(RedisString("LSET"), RedisString(key), RedisString(index), value) {(response: RedisResponse) in
            let (ok, error) = self.redisOkResponseHandler(response)
            callback(ok, _: error)
        }
    }
    
    ///
    /// Trim a list to a new size
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter start: the starting of the list to keep
    /// - Parameter end: the ending point of the list to keep
    ///
    public func ltrim(_ key: String, start: Int, end: Int, callback: (Bool, NSError?) -> Void) {
        issueCommand("LTRIM", key, String(start), String(end)) {(response: RedisResponse) in
            let (ok, error) = self.redisOkResponseHandler(response)
            callback(ok, _: error)
        }
    }
    
    ///
    /// Remove and return the last value of a list
    ///
    /// - Parameter key: the String parameter for the key
    ///
    public func rpop(_ key: String, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("RPOP", key) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Remove and return the last value of a list and push it onto another list
    ///
    /// - Parameter source: The list to pop an item from
    /// - Parameter destination: The list to push the poped item onto
    ///
    public func rpoplpush(_ source: String, destination: String, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("RPOPLPUSH", source, destination) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Append a set of values to a list
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: A variadic parameter of the values to be pushed on to the list
    ///
    public func rpush(_ key: String, values: String..., callback: (Int?, NSError?) -> Void) {
        rpushArrayOfValues(key, values: values, callback: callback)
    }
    
    ///
    /// Append a set of values to a list
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: An array parameter of the values to be pushed on to the list
    ///
    public func rpushArrayOfValues(_ key: String, values: [String], callback: (Int?, NSError?) -> Void) {
        var command = ["RPUSH", key]
        for value in values {
            command.append(value)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Append a set of values to a list
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: A variadic parameter of the values to be pushed on to the list
    ///
    public func rpush(_ key: String, values: RedisString..., callback: (Int?, NSError?) -> Void) {
        rpushArrayOfValues(key, values: values, callback: callback)
    }
    
    ///
    /// Append a set of values to a list
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: An array parameter of the values to be pushed on to the list
    ///
    public func rpushArrayOfValues(_ key: String, values: [RedisString], callback: (Int?, NSError?) -> Void) {
        var command = [RedisString("RPUSH"), RedisString(key)]
        for value in values {
            command.append(value)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    
    
    ///
    /// Append a value to a list, only if the list exists
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: An array parameter of the values to be pushed on to the list
    ///
    public func rpushx(_ key: String, value: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("RPUSHX", key, value) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Append a value to a list, only if the list exists
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: An array parameter of the values to be pushed on to the list
    ///
    public func rpushx(_ key: String, value: RedisString, callback: (Int?, NSError?) -> Void) {
        issueCommand(RedisString("RPUSHX"), RedisString(key), value) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }


    ///
    /// Add one or more members to a set
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter memebers: an variadic parameter of the values to be added to the set
    ///
    /// Returns: Integer reply: the number of elements that were added to the set, not including all the elements already present into the set.
    ///
    public func sadd(_ key: String, members: String..., callback: (Int?, NSError?) -> Void) {
        saddArrayOfMembers(key, members: members, callback: callback)
    }

    ///
    /// Add one or more members to a set
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter memebers: an array parameter of the values to be added to the set
    ///
    /// Returns: Integer reply: the number of elements that were added to the set, not including all the elements already present into the set.
    ///
    public func saddArrayOfMembers(_ key: String, members: [String], callback: (Int?, NSError?) -> Void) {
        var command = ["SADD", key]
        for member in members {
            command.append(member)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    ///
    /// Add one or more members to a set
    ///
    /// - Parameter key: the RedisString parameter for the key
    /// - Parameter memebers: an variadic parameter of the values to be added to the set
    ///
    /// Returns: Integer reply: the number of elements that were added to the set, not including all the elements already present into the set.
    ///
    public func sadd(_ key: RedisString, members: RedisString..., callback: (Int?, NSError?) -> Void) {
        saddArrayOfMembers(key, members: members, callback: callback)
    }
    
    ///
    /// Add one or more members to a set
    ///
    /// - Parameter key: the RedisString parameter for the key
    /// - Parameter memebers: an array parameter of the values to be added to the set
    ///
    /// Returns: Integer reply: the number of elements that were added to the set, not including all the elements already present into the set.
    ///
    public func saddArrayOfMembers(_ key: RedisString, members: [RedisString], callback: (Int?, NSError?) -> Void) {
        var command = [RedisString("SADD"), key]
        for member in members {
            command.append(member)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Get the number of members in a set
    /// - Parameter key: the String paramter for the key
    ///
    /// Returns: Integer reply: the cardinality (number of elements) of the set, or 0 if key does not exist.
    ///
    public func scard(_ key: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("SCARD", key) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    ///
    /// Get the number of members in a set
    /// - Parameter key: the RedisString paramter for the key
    ///
    /// Returns: Integer reply: the cardinality (number of elements) of the set, or 0 if key does not exist.
    ///
    public func scard(_ key: RedisString, callback: (Int?, NSError?) -> Void) {
        issueCommand(RedisString("SCARD"), key) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    ///
    /// Subtract multiple sets
    ///
    /// - Parameter keys: an variadic parameter of the keys to get the difference from
    ///
    /// Returns: Array reply: list with members of the resulting set.
    ///
    public func sdiff(keys: String..., callback: ([RedisString?]?, NSError?) -> Void) {
        sdiffArrayOfKeys(keys: keys, callback: callback)
    }

    ///
    /// Subtract multiple sets
    ///
    /// - Parameter keys: an array parameter of the keys to get the difference from
    ///
    /// Returns: Array reply: list with members of the resulting set.
    ///
    public func sdiffArrayOfKeys(keys: [String], callback: ([RedisString?]?, NSError?) -> Void) {
        var command = ["SDIFF"]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Subtract multiple sets
    ///
    /// - Parameter keys: an variadic parameter of the keys to get the difference from
    ///
    /// Returns: Array reply: list with members of the resulting set.
    public func sdiff(keys: RedisString..., callback: ([RedisString?]?, NSError?) -> Void) {
        sdiffArrayOfKeys(keys: keys, callback: callback)
    }
    
    ///
    /// Subtract multiple sets
    ///
    /// - Parameter keys: an array parameter of the keys to get the difference from
    ///
    /// Returns: Array reply: list with members of the resulting set.
    ///
    public func sdiffArrayOfKeys(keys: [RedisString], callback: ([RedisString?]?, NSError?) -> Void) {
        var command = [RedisString("SDIFF")]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Subtract multiple sets and store the resulting set in a key
    ///
    /// - Parameter destination: the destination of the result,
    ///                             if destination already exists, it is overwritten
    /// - Paramter keys: a variadic parameter of the keys to get the difference from
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
    ///
    public func sdiffstore(destination: String, keys: String...,
        callback: (Int?, NSError?) -> Void) {
        self.sdiffstoreArrayOfKeys(destination: destination, keys: keys, callback: callback)
    }
    
    ///
    /// Subtract multiple sets and store the resulting set in a key
    ///
    /// - Parameter destination: the destination of the result
    /// - Paramter keys: a array parameter of the keys to get the difference from
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
    ///
    public func sdiffstoreArrayOfKeys(destination: String, keys: [String],
                                      callback: (Int?, NSError?) -> Void) {
        
        var command = ["sdiffstore"]
        for key in keys {
            command.append(key)
        }
        self.issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Subtract multiple sets and store the resulting set in a key
    ///
    /// - Parameter destination: the destination of the result,
    ///                             if destination already exists, it is overwritten
    /// - Paramter keys: a variadic parameter of the keys to get the difference from
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
    ///
    public func sdiffstore(destination: RedisString, keys: RedisString...,
                           callback: (Int?, NSError?) -> Void) {
        self.sdiffstoreArrayOfKeys(destination: destination, keys: keys, callback: callback)
    }
    
    ///
    /// Subtract multiple sets and store the resulting set in a key
    ///
    /// - Parameter destination: the destination of the result
    /// - Paramter keys: a array parameter of the keys to get the difference from
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
    ///
    public func sdiffstoreArrayOfKeys(destination: RedisString, keys: [RedisString],
        callback: (Int?, NSError?) -> Void) {
        
        var command = [RedisString("sdiffstore")]
        for key in keys {
            command.append(key)
        }
        self.issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Get all the members in a set
    ///
    /// - Parameter key: the String parameter for the key
    ///
    /// Returns: Array reply: all elements of the set.
    ///
    public func smembers(_ key: String, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand(RedisString("SMEMBERS"), RedisString(key)) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Get all the members in a set
    ///
    /// - Parameter key: the RedisString parameter for the key
    ///
    /// Returns: Array reply: all elements of the set.
    ///
    public func smembers(_ key: RedisString, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand(RedisString("SMEMBERS"), key) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Intersect multiple sets
    ///
    /// - Parameter keys: a variadic parameter of the keys to intersect from
    ///
    /// Returns: Array reply: list with members of the resulting set.
    ///
    public func sinter(_ keys: String..., callback: ([RedisString?]?, NSError?) -> Void) {
        self.sinterArrayOfKeys(keys, callback: callback)
    }
    
    ///
    /// Intersect multiple sets
    ///
    /// - Parameter keys: an array parameter of the keys to intersect from
    ///
    /// Returns: Array reply: list with members of the resulting set.
    ///
    public func sinterArrayOfKeys(_ keys: [String], callback: ([RedisString?]?, NSError?) -> Void) {
        var command = ["SINTER"]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Intersect multiple sets
    ///
    /// - Parameter keys: a variadic parameter of the keys to intersect from
    ///
    /// Returns: Array reply: list with members of the resulting set.
    ///
    public func sinter(_ keys: RedisString..., callback: ([RedisString?]?, NSError?) -> Void) {
        self.sinterArrayOfKeys(keys, callback: callback)
    }
    
    ///
    /// Intersect multiple sets
    ///
    /// - Parameter keys: an array parameter of the keys to intersect from
    ///
    /// Returns: Array reply: list with members of the resulting set.
    ///
    public func sinterArrayOfKeys(_ keys: [RedisString], callback: ([RedisString?]?, NSError?) -> Void) {
        var command = [RedisString("SINTER")]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Intersect multiple sets and store the resulting set in a key
    ///
    /// - Parameter destination: the destination of the result
    /// - Parameter keys: a variadic parameter of the keys to intersect from
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
    ///
    public func sinterstore(_ destination: String, keys: String..., callback: (Int?, NSError?) -> Void) {
        self.sinterstoreArrayOfKeys(destination, keys: keys, callback: callback)
    }
    
    ///
    /// Intersect multiple sets and store the resulting set in a key
    ///
    /// - Parameter destination: the destination of the result
    /// - Parameter keys: an array parameter of the keys to intersect from
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
    ///
    public func sinterstoreArrayOfKeys(_ destination: String, keys: [String], callback: (Int?, NSError?) -> Void) {
        var command = ["SINTERSTORE", destination]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Intersect multiple sets and store the resulting set in a key
    ///
    /// - Parameter destination: the destination of the result
    /// - Parameter keys: a variadic parameter of the keys to intersect from
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
    ///
    public func sinterstore(_ destination: RedisString, keys: RedisString..., callback: (Int?, NSError?) -> Void) {
        self.sinterstoreArrayOfKeys(destination, keys: keys, callback: callback)
    }
    
    ///
    /// Intersect multiple sets and store the resulting set in a key
    ///
    /// - Parameter destination: the destination of the result
    /// - Parameter keys: an array parameter of the keys to intersect from
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
    ///
    public func sinterstoreArrayOfKeys(_ destination: RedisString, keys: [RedisString], callback: (Int?, NSError?) -> Void) {
        var command = [RedisString("SINTERSTORE"), destination]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Determine if a given value is a member of a set
    ///
    /// - Parameter key: the String paramter for the key
    /// - Parameter member: the String paramter for the member
    ///
    /// Returns: Bool reply: True if element is a member of the set,
    ///                      False if the element isn't a member of the set, or if key doesn't exist.
    ///
    public func sismember(_ key: String, member: String, callback: (Bool?, NSError?) -> Void) {
        issueCommand("SISMEMBER", key, member) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Determine if a given value is a member of a set
    ///
    /// - Parameter key: the RedisString paramter for the key
    /// - Parameter member: the RedisString paramter for the member
    ///
    /// Returns: Bool reply: True if element is a member of the set,
    ///                      False if the element isn't a member of the set, or if key doesn't exist.
    ///
    public func sismember(_ key: RedisString, member: RedisString, callback: (Bool?, NSError?) -> Void) {
        issueCommand(RedisString("SISMEMBER"), key, member) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Move a member from one set to another
    ///
    /// - Parameter source: the Source set from where to move the member from
    /// - Parameter destination: the Destination set from where to move the member to
    /// - Parameter member: the String parameter for the member to be moved
    ///
    /// Returns: Bool reply: True if element is moved,
    ///                      False if the element isn't a member of source and
    ///                             no operation was performed.
    ///
    public func smove(source: String, destination: String, member: String, callback: (Bool?, NSError?) -> Void) {
        issueCommand("SMOVE", source, destination, member) {
            (response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Move a member from one set to another
    ///
    /// - Parameter source: the Source set from where to move the member from
    /// - Parameter destination: the Destination set from where to move the member to
    /// - Parameter member: the RedisString parameter for the member to be moved
    ///
    /// Returns: Bool reply: True if element is moved,
    ///                      False if the element isn't a member of source and
    ///                             no operation was performed.
    ///
    public func smove(source: RedisString, destination: RedisString, member: RedisString, callback: (Bool?, NSError?) -> Void) {
        issueCommand(RedisString("SMOVE"), source, destination, member) {
            (response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Remove and return one or multiple random members from a set
    ///
    /// - Parameter key: the String parameter for the key
    ///
    /// Returns: Bulk string reply: the removed element, or nil when key does not exist.
    ///
    public func spop(_ key: String, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("SPOP", key) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Remove and return one or multiple random members from a set
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter count: the number of members to pop
    ///
    /// Returns: Bulk string reply: the removed element, or nil when key does not exist.
    ///
    public func spop(_ key: String, count: Int, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand("SPOP", key, String(count)) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Remove and return one or multiple random members from a set
    ///
    /// - Parameter key: the RedisString parameter for the key
    ///
    /// Returns: Bulk string reply: the removed element, or nil when key does not exist.
    ///
    public func spop(_ key: RedisString, callback: (RedisString?, NSError?) -> Void) {
        issueCommand(RedisString("SPOP"), key) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Remove and return one or multiple random members from a set
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter count: the number of members to pop
    ///
    /// Returns: Bulk string reply: the removed element, or nil when key does not exist.
    ///
    public func spop(_ key: RedisString, count: Int, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand(RedisString("SPOP"), key, RedisString(count)) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Get one or multiple random members from a set
    ///
    /// - Parameter key: the String parameter for the key
    ///
    /// Returns: Bulk string reply: the randomly selected element, or nil when key does not exist.
    ///
    public func srandmember(_ key: String, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("SRANDMEMBER", key) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Get one or multiple random members from a set
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter count: the number of members to return
    ///
    /// Returns: Array reply: an array of elements, or an empty array when key does not exist.
    ///
    public func srandmember(_ key: String, count: Int, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand("SRANDMEMBER", key, String(count)) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Get one or multiple random members from a set
    ///
    /// - Parameter key: the RedisString parameter for the key
    ///
    /// Returns: Bulk string reply: the randomly selected element, or nil when key does not exist.
    ///
    public func srandmember(_ key: RedisString, callback: (RedisString?, NSError?) -> Void) {
        issueCommand(RedisString("SRANDMEMBER"), key) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Get one or multiple random members from a set
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter count: the number of members to return
    ///
    /// Returns: Array reply: an array of elements, or an empty array when key does not exist.
    ///
    public func srandmember(_ key: RedisString, count: Int, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand(RedisString("SRANDMEMBER"), key, RedisString(count)) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Remove one or more members from a set
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter members: the variadic parameter for the members to be removed
    ///
    /// Returns: Integer reply: the number of members that were removed from the set,
    ///                         not including non existing members.
    ///
    public func srem(_ key: String, members: String..., callback: (Int?, NSError?) -> Void) {
        self.sremArrayOfMembers(key, members: members, callback: callback)
    }
    
    ///
    /// Remove one or more members from a set
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter members: the Array parameter for the members to be removed
    ///
    /// Returns: Integer reply: the number of members that were removed from the set,
    ///                         not including non existing members.
    ///
    public func sremArrayOfMembers(_ key: String, members: [String], callback: (Int?, NSError?) -> Void) {
        var command = ["SREM", key]
        for member in members {
            command.append(member)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    ///
    /// Remove one or more members from a set
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter members: the variadic parameter for the members to be removed
    ///
    /// Returns: Integer reply: the number of members that were removed from the set,
    ///                         not including non existing members.
    ///
    public func srem(_ key: RedisString, members: RedisString..., callback: (Int?, NSError?) -> Void) {
        self.sremArrayOfMembers(key, members: members, callback: callback)
    }
    
    ///
    /// Remove one or more members from a set
    ///
    /// - Parameter key: the RedisString parameter for the key
    /// - Parameter members: the array parameter for the members to be removed
    ///
    /// Returns: Integer reply: the number of members that were removed from the set,
    ///                         not including non existing members.
    ///
    public func sremArrayOfMembers(_ key: RedisString, members: [RedisString], callback: (Int?, NSError?) -> Void) {
        var command = [RedisString("SREM"), key]
        for member in members {
            command.append(member)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    ///
    /// Add multiple sets
    ///
    /// - Parameter keys: a variadic parater for the keys to union
    ///
    /// Returns: Array reply: list with members of the resulting set.
    ///
    public func sunion(_ keys: String..., callback: ([RedisString?]?, NSError?) -> Void) {
        self.sunionArrofOfKeys(keys, callback: callback)
    }
    
    ///
    /// Add multiple sets
    ///
    /// - Parameter keys: a variadic parater for the keys to union
    ///
    /// Returns: Array reply: list with members of the resulting set.
    ///
    public func sunionArrofOfKeys(_ keys: [String], callback: ([RedisString?]?, NSError?) -> Void) {
        var command = ["SUNION"]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Add multiple sets
    ///
    /// - Parameter keys: a variadic parater for the keys to union
    ///
    /// Returns: Array reply: list with members of the resulting set.
    ///
    public func sunion(_ keys: RedisString..., callback: ([RedisString?]?, NSError?) -> Void) {
        self.sunionArrofOfKeys(keys, callback: callback)
    }
    
    ///
    /// Add multiple sets
    ///
    /// - Parameter keys: a variadic parater for the keys to union
    ///
    /// Returns: Array reply: list with members of the resulting set.
    ///
    public func sunionArrofOfKeys(_ keys: [RedisString], callback: ([RedisString?]?, NSError?) -> Void) {
        var command = [RedisString("SUNION")]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Add multiple sets
    ///
    /// - Parameter keys: a variadic parater for the keys to union
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
    ///
    public func sunionstore(_ destination: String, keys: String..., callback: (Int?, NSError?) -> Void) {
        self.sunionstoreArrofOfKeys(destination, keys: keys, callback: callback)
    }
    
    ///
    /// Add multiple sets
    ///
    /// - Parameter keys: a variadic parater for the keys to union
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
    ///
    public func sunionstoreArrofOfKeys(_ destination: String, keys: [String], callback: (Int?, NSError?) -> Void) {
        var command = ["SUNIONSTORE", destination]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Add multiple sets
    ///
    /// - Parameter keys: a variadic parater for the keys to union
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
    ///
    public func sunionstore(_ destination: RedisString, keys: RedisString..., callback: (Int?, NSError?) -> Void) {
        self.sunionstoreArrofOfKeys(destination, keys: keys, callback: callback)
    }
    
    ///
    /// Add multiple sets
    ///
    /// - Parameter keys: a variadic parater for the keys to union
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
    ///
    public func sunionstoreArrofOfKeys(_ destination: RedisString, keys: [RedisString], callback: (Int?, NSError?) -> Void) {
        var command = [RedisString("SUNIONSTORE"), destination]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    ///
    /// Iterates elements of Sets types.
    ///
    /// - Paramter key: the String parameter for the key
    /// - Paramter cursor: iterator
    /// - Parameter match: glob-style pattern
    /// - parameter count: amount of work that should be done at every call in order to retrieve elements from the collection
    ///
    /// Returns: Array reply: a two elements multi-bulk reply:
    ///                         first element is a string representing an unsigned 64 bit number (the cursor),
    ///                         the second element is a multi-bulk with an array of elements.
    ///
    public func sscan(_ key: String, cursor: Int, match: String? = nil, count: Int? = nil,
                      callback: (RedisString?, [RedisString?]?, NSError?) -> Void) {
        if let match = match, let count = count {
            issueCommand("SSCAN", key, String(cursor), "MATCH", match, "COUNT", String(count)) {(response: RedisResponse) in
                self.redisScanResponseHandler(response, callback: callback)
            }
        } else if let match = match {
            issueCommand("SSCAN", key, String(cursor), "MATCH", match) {(response: RedisResponse) in
                self.redisScanResponseHandler(response, callback: callback)
            }
        } else if let count = count {
            issueCommand("SSCAN", key, String(cursor), "COUNT", String(count)) {(response: RedisResponse) in
                self.redisScanResponseHandler(response, callback: callback)
            }
        } else {
            issueCommand("SSCAN", key, String(cursor)) {(response: RedisResponse) in
                self.redisScanResponseHandler(response, callback: callback)
            }
        }
    }
    
    ///
    /// Iterates elements of Sets types.
    ///
    /// - Paramter key: the String parameter for the key
    /// - Paramter cursor: iterator
    /// - Parameter match: glob-style pattern
    /// - parameter count: amount of work that should be done at every call in order to retrieve elements from the collection
    ///
    /// Returns: Array reply: a two elements multi-bulk reply:
    ///                         first element is a string representing an unsigned 64 bit number (the cursor),
    ///                         the second element is a multi-bulk with an array of elements.
    ///
    public func sscan(_ key: RedisString, cursor: Int, match: RedisString? = nil, count: Int? = nil,
                      callback: (RedisString?, [RedisString?]?, NSError?) -> Void) {
        let SSCAN = RedisString("SSCAN")
        let MATCH = RedisString("MATCH")
        let COUNT = RedisString("COUNT")
        if let match = match, let count = count {
            issueCommand(SSCAN, key, RedisString(cursor), MATCH, match, COUNT, RedisString(count)) {(response: RedisResponse) in
                self.redisScanResponseHandler(response, callback: callback)
            }
        } else if let match = match {
            issueCommand(SSCAN, key, RedisString(cursor), MATCH, match) {(response: RedisResponse) in
                self.redisScanResponseHandler(response, callback: callback)
            }
        } else if let count = count {
            issueCommand(SSCAN, key, RedisString(cursor), COUNT, RedisString(count)) {(response: RedisResponse) in
                self.redisScanResponseHandler(response, callback: callback)
            }
        } else {
            issueCommand(SSCAN, key, RedisString(cursor)) {(response: RedisResponse) in
                self.redisScanResponseHandler(response, callback: callback)
            }
        }
    }
    
    //
    //  MARK: Transaction support
    //
    
    public func multi() -> RedisMulti {
        return RedisMulti(redis: self)
    }
    
    
    //
    //  MARK: Base API functions
    //
    
    public func issueCommand(_ stringArgs: String..., callback: (RedisResponse) -> Void) {
        issueCommandInArray(stringArgs, callback: callback)
    }
    
    public func issueCommandInArray(_ stringArgs: [String], callback: (RedisResponse) -> Void) {
        guard  let respHandle = respHandle, respHandle.status == .connected else {
            callback(RedisResponse.Error("Not connected to Redis server"))
            return
        }
        
        guard  stringArgs.count > 0  else {
            callback(RedisResponse.Error("Empty command"))
            return
        }
        
        respHandle.issueCommand(stringArgs, callback: callback)
    }
    
    public func issueCommand(_ stringArgs: RedisString..., callback: (RedisResponse) -> Void) {
        issueCommandInArray(stringArgs, callback: callback)
    }
    
    public func issueCommandInArray(_ stringArgs: [RedisString], callback: (RedisResponse) -> Void) {
        guard  let respHandle = respHandle, respHandle.status == .connected else {
            callback(RedisResponse.Error("Not connected to Redis server"))
            return
        }
        
        guard  stringArgs.count > 0  else {
            callback(RedisResponse.Error("Empty command"))
            return
        }
        
        respHandle.issueCommand(stringArgs, callback: callback)
    }
    
    //
    //  MARK: Helper functions
    //
    
    private func redisBoolResponseHandler(_ response: RedisResponse, callback: (Bool, NSError?) -> Void) {
        switch(response) {
        case .IntegerValue(let num):
            if  num == 0  || num == 1 {
                callback(num == 1, nil)
            }
            else {
                callback(false, _: createUnexpectedResponseError(response))
            }
        case .Error(let error):
            callback(false, _: createError("Error: \(error)", code: 1))
        default:
            callback(false, _: createUnexpectedResponseError(response))
        }
    }
    
    private func redisIntegerResponseHandler(_ response: RedisResponse, callback: (Int?, NSError?) -> Void) {
        switch(response) {
        case .IntegerValue(let num):
            callback(Int(num), nil)
        case .Error(let error):
            callback(nil, _: createError("Error: \(error)", code: 1))
        default:
            callback(nil, _: createUnexpectedResponseError(response))
        }
    }
    
    private func redisOkResponseHandler(_ response: RedisResponse, nilOk: Bool=true) -> (Bool, NSError?) {
        switch(response) {
        case .Status(let str):
            if  str == "OK"  {
                return (true, nil)
            }
            else {
                return (false, createError("Status result other than 'OK' received from Redis", code: 2))
            }
        case .Nil:
            return (false, nilOk ? nil : createUnexpectedResponseError(response))
        case .Error(let error):
            return (false, createError("Error: \(error)", code: 1))
        default:
            return (false, createUnexpectedResponseError(response))
        }
    }
    
    private func redisStringResponseHandler(_ response: RedisResponse, callback: (RedisString?, NSError?) -> Void) {
        switch(response) {
        case .StringValue(let str):
            callback(str, nil)
        case .Nil:
            callback(nil, nil)
        case .Error(let error):
            callback(nil, _: createError("Error: \(error)", code: 1))
        default:
            callback(nil, _: createUnexpectedResponseError(response))
        }
    }
    
    private func redisStringArrayResponseHandler(_ response: RedisResponse, callback: ([RedisString?]?, NSError?) -> Void) {
        var error: NSError? = nil
        var result: [RedisString?]?
        
        switch(response) {
        case .Array(let responses):
            var strings = [RedisString?]()
            for innerResponse in responses {
                switch(innerResponse) {
                case .StringValue(let str):
                    strings.append(str)
                case .Nil:
                    strings.append(nil)
                default:
                    error = self.createUnexpectedResponseError(response)
                }
            }
            result = strings
        case .Nil:
            result = nil
        case .Error(let err):
            error = self.createError("Error: \(err)", code: 1)
        default:
            error = self.createUnexpectedResponseError(response)
        }
        callback(error == nil ? result : nil, _: error)
    }
    
    private func redisScanResponseHandler(_ response: RedisResponse, callback: (RedisString?, [RedisString?]?, NSError?) -> Void) {
        var error: NSError? = nil
        var cursor: RedisString?
        var result: [RedisString?]?
        
        switch(response) {
        case .Array(let responses):
            var strings = [RedisString?]()
            for innerResponse in responses {
                switch(innerResponse) {
                case .StringValue(let str):
                    cursor = str
                case.Array(let innerArray):
                    for val in innerArray {
                        switch(val) {
                        case .StringValue(let str):
                            strings.append(str)
                        case .Nil:
                            strings.append(nil)
                        default:
                            error = self.createUnexpectedResponseError(response)
                        }
                    }
                default:
                    error = self.createUnexpectedResponseError(response)
                }
            }
            result = strings
        case .Nil:
            result = nil
        case .Error(let err):
            error = self.createError("Error: \(err)", code: 1)
        default:
            error = self.createUnexpectedResponseError(response)
        }
        
        if(error == nil) {
            callback(cursor, result, nil)
        } else {
            callback(nil, nil, error)
        }
    }
    
    private func redisDictionaryResponseHandler(_ response: RedisResponse, callback: (RedisInfo?, NSError?) -> Void) {
        switch(response){
        case .StringValue(let str):
            callback(RedisInfo(str), nil)
        case .Nil:
            callback(nil, nil)
        case .Error(let error):
            callback(nil, _: createError("Error: \(error)", code: 1))
        default:
            callback(nil, _: createUnexpectedResponseError(response))
        }
    }
    
    private func createUnexpectedResponseError(_ response: RedisResponse) -> NSError {
        return createError("Unexpected result received from Redis \(response)", code: 2)
    }
    
    private func createError(_ errorMessage: String, code: Int) -> NSError {
        #if os(Linux)
            let userInfo: [String: Any]
        #else
            let userInfo: [String: String]
        #endif
        userInfo = [NSLocalizedDescriptionKey: errorMessage]
        return NSError(domain: "RedisDomain", code: code, userInfo: userInfo)
    }
    
    private func createRedisError(_ redisError: String) -> NSError {
        return createError(redisError, code: 1)
    }
}

public struct RedisInfo {
    
    public let server: RedisInfoServer
    public let client: RedisInfoClient

    public init(_ redisReply: RedisString) {
        
        let convertedStr = redisReply.asString
        let newline = "\r\n"
        let strArray = convertedStr.components(separatedBy: newline)
        var parsedInfo: [String: String] = [:]
        
        for val in strArray {
            let pos = val.range(of: ":")
            if let pos = pos {
                parsedInfo[val.substring(to: pos.lowerBound)] = val.substring(from: pos.upperBound)
            }
        }
        
        server = RedisInfoServer(parsedInfo)
        client = RedisInfoClient(parsedInfo)
    }
    
    public struct RedisInfoClient {
        public let connected_clients: Int
        public let blocked_clients: Int

        fileprivate init(_ redisInfo: [String: String]) {
            self.connected_clients = Int(redisInfo["connected_clients"]!)!
            self.blocked_clients = Int(redisInfo["blocked_clients"]!)!
        }
    }
    
    public struct RedisInfoServer {
        
        public let redis_version: String
        public let redis_mode: String
        public let os: String
        public let arch_bits: Int
        public let process_id: Int
        public let tcp_port: Int
        public let uptime_in_seconds: Int
        public let uptime_in_days: Int
        
        fileprivate init(_ redisInfo: [String: String]) {
            self.redis_version = redisInfo["redis_version"]!
            self.redis_mode = redisInfo["redis_mode"]!
            self.os = redisInfo["os"]!
            self.arch_bits = Int(redisInfo["arch_bits"]!)!
            self.process_id = Int(redisInfo["process_id"]!)!
            self.tcp_port = Int(redisInfo["tcp_port"]!)!
            self.uptime_in_seconds  = Int(redisInfo["uptime_in_seconds"]!)!
            self.uptime_in_days  = Int(redisInfo["uptime_in_days"]!)!
        }
        
        public func checkVersionIsNewerOrSame(_ versionToCompare: String) -> Bool {

            let v = self.redis_version.components(separatedBy: ".")
            let vToCompare = versionToCompare.components(separatedBy: ".")
        
            if vToCompare.count == 3 {
                return v[0] >= vToCompare[0] && v[1] >= vToCompare[1] && v[2] >= vToCompare[2]
            } else if vToCompare.count == 2 {
                return v[0] >= vToCompare[0] && v[1] >= vToCompare[1]
            } else {
                return v[0] >= vToCompare[0]
            }
        }
    }
    
}
