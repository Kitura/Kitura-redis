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

/// Extend Redis by adding the Basic operations
extension Redis {
    
    //
    //  MARK: Basic API functions
    //
    
    /// If the key already exists and is a string, this command appends the value at the end of the string
    ///
    /// - Parameter key: The key.
    /// - Parameter value: The value to append.
    /// - Parameter callback: The callback function, the Int will contain the length of the string after
    ///                      the append operation. NSError will be non-nil if an error occurred.
    public func append(_ key: String, value: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("APPEND", key, value) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Count the number of set bits (population counting) in a string.    ///
    /// - Parameter key: The key.
    /// - Parameter callback: The callback function, the Int will contain the number of bits
    ///                      set to 1. NSError will be non-nil if an error occurred.
    public func bitcount(_ key: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("BITCOUNT", key) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Count the number of set bits (population counting) in a string.
    ///
    /// - Parameter key: The key.
    /// - Parameter start: The starting index in the string to count from
    /// - Parameter end: The ending index in the string to count to.
    /// - Parameter callback: The callback function, the Int will contain the number of bits
    ///                      set to 1. NSError will be non-nil if an error occurred.
    public func bitcount(_ key: String, start: Int, end: Int, callback: (Int?, NSError?) -> Void) {
        issueCommand("BITCOUNT", key, String(start), String(end)) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Used in BITFIELD
    public enum BitfieldSubcommand {
        // (type, offset)
        case get(String, Int)
        
        // (type, offset, value)
        case set(String, String, Int)
        
        // (type, offset, increment)
        case incrby(String, String, Int)
        
        // (wrap/sat/fail)
        case overflow(BitfieldOverflow)
        
        public enum BitfieldOverflow: String {
            case WRAP, SAT, FAIL
        }
    }
    
    /// Treats a Redis string as a array of bits, and is capable of addressing 
    /// specific integer fields of varying bit widths and arbitrary non 
    /// (necessary) aligned offset.
    /// https://redis.io/commands/bitfield
    ///
    /// - parameter key: The key of the string to manipulate.
    /// - parameter subcommands: `BitfieldSubcommand`s to do on the string.
    /// - parameter callback: The callback function.
    /// - parameter res: An array with each entry being the corresponding result 
    ///                  of the sub command given at the same position. OVERFLOW 
    ///                  subcommands don't count as generating a reply.
    /// - parameter err: The error, if one occurred.
    public func bitfield(key: String, subcommands: BitfieldSubcommand..., callback: (_ res: [RedisResponse?]?, _ err: NSError?) -> Void) {
        bitfieldArrayOfSubcommands(key: key, subcommands: subcommands, callback: callback)
    }
    
    /// Treats a Redis string as a array of bits, and is capable of addressing
    /// specific integer fields of varying bit widths and arbitrary non
    /// (necessary) aligned offset.
    /// https://redis.io/commands/bitfield
    ///
    /// - parameter key: The key of the string to manipulate.
    /// - parameter subcommands: `BitfieldSubcommand`s to do on the string.
    /// - parameter callback: The callback function.
    /// - parameter res: An array with each entry being the corresponding result
    ///                  of the sub command given at the same position. OVERFLOW
    ///                  subcommands don't count as generating a reply.
    /// - parameter err: The error, if one occurred.
    public func bitfieldArrayOfSubcommands(key: String, subcommands: [BitfieldSubcommand], callback: (_ res: [RedisResponse?]?, _ err: NSError?) -> Void) {
        var command = ["BITFIELD", key]
        for subcommand in subcommands {
            switch(subcommand) {
            case .get(let type, let offset):
                command.append("GET")
                command.append(String(type))
                command.append(String(offset))
            case .set(let type, let offset, let value):
                command.append("SET")
                command.append(type)
                command.append(String(offset))
                command.append(String(value))
            case .incrby(let type, let offset, let incr):
                command.append("INCRBY")
                command.append(type)
                command.append(String(offset))
                command.append(String(incr))
            case .overflow(let overflow):
                command.append("OVERFLOW")
                command.append(overflow.rawValue)
            }
        }
        issueCommandInArray(command) { (res) in
            redisArrayResponseHandler(response: res, callback: callback)
        }
    }
    
    /// Perform a bitwise AND operation between multiple keys and store the result at the destination key.
    ///
    /// - Parameter destKey: The destination key.
    /// - Parameter and: The list of keys whose values will be AND'ed.
    /// - Parameter callback: The callback function, the Int will contain the length of the string
    ///                      stored at the destination key. NSError will be non-nil if an error occurred.
    public func bitop(_ destKey: String, and: String..., callback: (Int?, NSError?) -> Void) {
        var command = ["BITOP", "AND", destKey]
        for key in and {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Perform a bitwise NOT operation on the value at a key and store the result at the destination key.
    ///
    /// - Parameter destKey: The destination key.
    /// - Parameter not: The key of the value to be NOT'ed.
    /// - Parameter callback: The callback function, the Int will contain the length of the string
    ///                      stored at the destination key. NSError will be non-nil if an error occurred.
    public func bitop(_ destKey: String, not: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("BITOP", "NOT", destKey, not) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Perform a bitwise OR operation between multiple keys and store the result at the destination key.
    ///
    /// - Parameter destKey: The destination key.
    /// - Parameter or: The list of keys whose values will be OR'ed.
    /// - Parameter callback: The callback function, the Int will contain the length of the string
    ///                      stored at the destination key. NSError will be non-nil if an error occurred.
    public func bitop(_ destKey: String, or: String..., callback: (Int?, NSError?) -> Void) {
        var command = ["BITOP", "OR", destKey]
        for key in or {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Perform a bitwise XOR operation between multiple keys and store the result at the destination key.
    ///
    /// - Parameter destKey: The destination key.
    /// - Parameter xor: The list of keys whose values will be XOR'ed.
    /// - Parameter callback: The callback function, the Int will contain the length of the string
    ///                      stored at the destination key. NSError will be non-nil if an error occurred.
    public func bitop(_ destKey: String, xor: String..., callback: (Int?, NSError?) -> Void) {
        var command = ["BITOP", "XOR", destKey]
        for key in xor {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Return the position of the first bit set to 1 or 0 in a string
    ///
    /// - Parameter key: The key.
    /// - Parameter bit: The value to compare against.
    /// - Parameter callback: The callback function, the Int will contain the index in the
    ///                      string where the bit value matches the comparison value.
    ///                      NSError will be non-nil if an error occurred.
    public func bitpos(_ key: String, bit: Bool, callback: (Int?, NSError?) -> Void) {
        issueCommand("BITPOS", key, bit ? "1" : "0") {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Return the position of the first bit set to 1 or 0 in a string
    ///
    /// - Parameter key: The key.
    /// - Parameter bit: The value to compare against.
    /// - Parameter start: The starting index in the string to search from.
    /// - Parameter callback: The callback function, the Int will contain the index in the
    ///                      string where the bit value matches the comparison value.
    ///                      NSError will be non-nil if an error occurred.
    public func bitpos(_ key: String, bit: Bool, start: Int, callback: (Int?, NSError?) -> Void) {
        issueCommand("BITPOS", key, bit ? "1" : "0", String(start)) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Return the position of the first bit set to 1 or 0 in a string
    ///
    /// - Parameter key: The key.
    /// - Parameter bit: The value to compare against.
    /// - Parameter start: The starting index in the string to search from.
    /// - Parameter end: The ending index in the string to search until.
    /// - Parameter callback: The callback function, the Int will contain the index in the
    ///                      string where the bit value matches the comparison value.
    ///                      NSError will be non-nil if an error occurred.
    public func bitpos(_ key: String, bit: Bool, start: Int, end: Int, callback: (Int?, NSError?) -> Void) {
        issueCommand("BITPOS", key, bit ? "1" : "0", String(start), String(end)) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    /// Decrements the integer number stored at the key by a value.
    /// If the key does not exist, it is set to 0 before performing the operation.
    ///
    /// - Parameter key: The key.
    /// - Parameter by: An integer number that will be subtracted from the value at the key.
    /// - Parameter callback: The callback function, the Int will be the value of the key after
    ///                      the decrement. NSError will be non-nil if an error occurred.
    ///
    /// - Note: This is a string operation since Redis does not have a dedicated integer type
    public func decr(_ key: String, by: Int=1, callback: (Int?, NSError?) -> Void) {
        issueCommand("DECRBY", key, String(by)) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Removes the specified keys. A key is ignored if it does not exist
    ///
    /// - Parameter keys: A list of keys.
    /// - Parameter callback: callback function, the Int is the number of keys deleted.
    ///                      NSError will be non-nil if an error occurred.
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
    /// - Parameter keys: A list of keys in the form of `RedisString`s.
    /// - Parameter callback: The callback function, the Int is the number of keys deleted.
    ///                      NSError will be non-nil if an error occurred.
    public func del(_ keys: RedisString..., callback: (Int?, NSError?) -> Void) {
        
        var command = [RedisString("DEL")]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Check if one or more keys exist
    ///
    /// - Parameter keys: A list of keys.
    /// - Parameter callback: The callback function, the Int will contain the number of the specified
    ///                      keys that exist. NSError will be non-nil if an error occurred.
    public func exists(_ keys: String..., callback: (Int?, NSError?) -> Void) {
        var command = ["EXISTS"]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Set a timeout on a key. After the timeout has expired, the key will automatically be deleted.
    /// A key with an associated timeout is often said to be volatile in Redis terminology.
    ///
    /// - Parameter key: The key.
    /// - Parameter inTime: The expiration period as a number of milliseconds.
    /// - Parameter callback: The callback function, the Bool will contain true if the timeout
    ///                      was set. NSError will be non-nil if an error occurred.
    public func expire(_ key: String, inTime: TimeInterval, callback: (Bool, NSError?) -> Void) {
        issueCommand("PEXPIRE", key, String(Int(inTime * 1000.0))) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    /// Set a timeout on a key. After the timeout has expired, the key will automatically be deleted.
    /// A key with an associated timeout is often said to be volatile in Redis terminology.
    ///
    /// - Parameter key: The key.
    /// - Parameter atDate: The key's expiration specified as a timestamp.
    /// - Parameter callback: The callback function, the Bool will contain true if the timeout
    ///                      was set. NSError will be non-nil if an error occurred.
    public func expire(_ key: String, atDate: NSDate, callback: (Bool, NSError?) -> Void) {
        issueCommand("PEXPIREAT", key, String(Int(atDate.timeIntervalSince1970 * 1000.0))) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    /// Returns all keys matching `pattern`.
    ///
    /// - parameter pattern: The glob-style pattern to match against.
    /// - parameter callback: The callback function.
    /// - parameter res: List of keys matching `pattern`.
    /// - parameter err: The error, if one occurred.
    public func keys(pattern: String, callback: (_ res: [RedisString?]?, _ err: NSError?) -> Void) {
        issueCommand("KEYS", pattern) { (res) in
            redisStringArrayResponseHandler(res, callback: callback)
        }
    }

    /// Get the value of a key.
    ///
    /// - Parameter key: The key.
    /// - Parameter callback: The callback function with the value of the key.
    ///                      NSError will be non-nil if an error occurred.
    public func get(_ key: String, callback: (RedisString?, NSError?) -> Void) {
        
        issueCommand("GET", key) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Returns the bit at an offset in the string value stored at the key.
    ///
    /// - Parameter key: The key.
    /// - Parameter offset: The offset in the string value.
    /// - Parameter callback: The callback function, the Bool will conatain the bit value stored
    ///                      at the offset. NSError will be non-nil if an error occurred.
    public func getbit(_ key: String, offset: Int, callback: (Bool, NSError?) -> Void) {
        issueCommand("GETBIT", key, String(offset)) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }

    /// Returns a substring of the string value stored at the key, determined by the offsets start and end.
    /// Negative offsets can be used in order to provide an offset starting from the end of the string.
    ///
    /// - Parameter key: The key.
    /// - Parameter start: Integer index for the starting position of the substring.
    /// - Parameter end: Integer index for the ending position of the substring.
    /// - Parameter callback: The callback function, the `RedisString` will contain the substring.
    ///                      NSError will be non-nil if an error occurred.
    public func getrange(_ key: String, start: Int, end: Int, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("GETRANGE", key, String(start), String(end)) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Atomically sets a key to a value and returns the old value stored at the key.
    ///
    /// - Parameter key: The key.
    /// - Parameter value: The String value to set.
    /// - Parameter callback: The callback function, the `RedisString` will contain the old value.
    ///                      NSError will be non-nil if an error occurred.
    public func getSet(_ key: String, value: String, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("GETSET", key, value) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Atomically sets a key to a value and returns the old value stored at the key.
    ///
    /// - Parameter key: The key.
    /// - Parameter value: The `RedisString` value to set.
    /// - Parameter callback: The callback function, the `RedisString` will contain the old value.
    ///                      NSError will be non-nil if an error occurred.
    public func getSet(_ key: String, value: RedisString, callback: (RedisString?, NSError?) -> Void) {
        issueCommand(RedisString("GETSET"), RedisString(key), value) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Increments the number stored at the key by a value. If the key does not exist,
    /// it is set to 0 before performing the operation.
    ///
    /// - Parameter key: The key.
    /// - Parameter by: A number that will be added to the value at the key.
    /// - Parameter callback: The callback function, the Int will be the value of the key after
    ///                      the increment. NSError will be non-nil if an error occurred.
    ///
    /// - Note: This is a string operation since Redis does not have a dedicated integer type
    public func incr(_ key: String, by: Int=1, callback: (Int?, NSError?) -> Void) {
        
        issueCommand("INCRBY", key, String(by)) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Increments the floating point number stored at the key by a value.
    /// If the key does not exist, it is set to 0 before performing the operation.
    ///
    /// - Parameter key: The key.
    /// - Parameter byFloat: A floating point number that will be added to the value at the key.
    /// - Parameter callback: The callback function, the `RedisString` will be the value of the key
    ///                      after the increment. NSError will be non-nil if an error occurred.
    ///
    /// - Note: This is a string operation since Redis does not have a dedicated float type
    public func incr(_ key: String, byFloat: Float, callback: (RedisString?, NSError?) -> Void) {
        
        issueCommand("INCRBYFLOAT", key, String(byFloat)) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Returns the value of all the specified keys.
    ///
    /// - Parameter keys: The list of keys.
    /// - Parameter callback: The callback function, the array of `RedisString` will be the
    ///                      values returned for the keys, in the order of the keys.
    ///                      NSError will be non-nil if an error occurred.
    public func mget(_ keys: String..., callback: ([RedisString?]?, NSError?) -> Void) {
        
        var command = ["MGET"]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    /// Move a key from the currently selected database to the specified destination database.
    /// When the key already exists in the destination database, or it does not exist in the
    /// source database, nothing is done.
    ///
    /// - Parameter key: The key.
    /// - Parameter toDB: The number of the database to move the key to.
    /// - Parameter callback: The callback function, the Bool will be true if the key was moved.
    ///                      NSError will be non-nil if an error occurred.
    public func move(_ key: String, toDB: Int, callback: (Bool, NSError?) -> Void) {
        issueCommand("MOVE", key, String(toDB)) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    /// Sets a set key value pairs in the database
    ///
    /// - Parameter keyValuePairs: A list of tuples containing a key and a value.
    /// - Parameter exists: If true, will set the value only if the key already exists.
    /// - Parameter callback: The callback function, the Bool will be true if the keys were set.
    ///                      NSError will be non-nil if an error occurred.
    public func mset(_ keyValuePairs: (String, String)..., exists: Bool=true, callback: (Bool, NSError?) -> Void) {
        msetArrayOfKeyValues(keyValuePairs, exists: exists, callback: callback)
    }

    /// Sets a set key value pairs in the database
    ///
    /// - Parameter keyValuePairs: An array of tuples containing a key and a value.
    /// - Parameter exists: If true, will set the value only if the key already exists.
    /// - Parameter callback: The callback function, the Bool will be true if the keys were set.
    ///                      NSError will be non-nil if an error occurred.
    public func msetArrayOfKeyValues(_ keyValuePairs: [(String, String)], exists: Bool=true, callback: (Bool, NSError?) -> Void) {
        var command = [exists ? "MSET" : "MSETNX"]
        for (key, value) in keyValuePairs {
            command.append(key)
            command.append(value)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            if exists {
                let (ok, error) = self.redisOkResponseHandler(response, nilOk: false)
                callback(ok, _: error)
            } else {
                self.redisBoolResponseHandler(response, callback: callback)
            }
        }
    }

    /// Sets the given keys to their respective values.
    ///
    /// - Parameter keyValuePairs: A list of tuples containing a key and value in the form of a `RedisString`.
    /// - Parameter exists: If true, will set the value only if the key already exists.
    /// - Parameter callback: The callback function, the Bool will be true if the keys were set.
    ///                      NSError will be non-nil if an error occurred.
    public func mset(_ keyValuePairs: (String, RedisString)..., exists: Bool=true, callback: (Bool, NSError?) -> Void) {
        msetArrayOfKeyValues(keyValuePairs, exists: exists, callback: callback)
    }

    /// Sets the given keys to their respective values.
    ///
    /// - Parameter keyValuePairs: An array of tuples containing a key and a value in the form of a `RedisString`.
    /// - Parameter exists: If true, will set the value only if the key already exists.
    /// - Parameter callback: The callback function, the Bool will be true if the keys were set.
    ///                      NSError will be non-nil if an error occurred.
    public func msetArrayOfKeyValues(_ keyValuePairs: [(String, RedisString)], exists: Bool=true, callback: (Bool, NSError?) -> Void) {
        var command = [RedisString(exists ? "MSET" : "MSETNX")]
        for (key, value) in keyValuePairs {
            command.append(RedisString(key))
            command.append(value)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            if exists {
                let (ok, error) = self.redisOkResponseHandler(response, nilOk: false)
                callback(ok, _: error)
            } else {
                self.redisBoolResponseHandler(response, callback: callback)
            }
        }
    }

    /// Remove the existing timeout on a key, turning the key from volatile (a key with an expiration)
    /// to persistent (a key that will never expire as no timeout is associated with it)
    ///
    /// - Parameter key: The key.
    /// - Parameter callback: The callback function, the Bool will contain true if the timeout
    ///                      was removed. NSError will be non-nil if an error occurred.
    public func persist(_ key: String, callback: (Bool, NSError?) -> Void) {
        issueCommand("PERSIST", key) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    /// Return a random key from the currently selected database.
    ///
    /// - parameter callback: The callback function.
    /// - parameter res: The random key, or nil when the database is empty.
    /// - parameter err: The error, if one occurred.
    public func randomkey(callback: (_ res: RedisString?, _ err: NSError?) -> Void) {
        issueCommand("RANDOMKEY") { (res) in
            redisStringResponseHandler(res, callback: callback)
        }
    }

    /// Renames a key. It returns an error if the original and new names are the same,
    /// or when the original key does not exist.
    ///
    /// - Parameter key: The key.
    /// - Parameter newKey: The new name for the key.
    /// - Parameter exists: If true, will rename the key even if the newKey already exists.
    /// - Parameter callback: The callback function, the Bool will be true if the key was renamed.
    ///                      NSError will be non-nil if an error occurred.
    public func rename(_ key: String, newKey: String, exists: Bool=true, callback: (Bool, NSError?) -> Void) {
        if  exists {
            issueCommand("RENAME", key, newKey) {(response: RedisResponse) in
                let (renamed, error) = self.redisOkResponseHandler(response, nilOk: false)
                callback(renamed, _: error)
            }
        } else {
            issueCommand("RENAMENX", key, newKey) {(response: RedisResponse) in
                self.redisBoolResponseHandler(response, callback: callback)
            }
        }
    }

    /// Iterates the set of keys in the currently selected Redis database.
    ///
    /// - parameter cursor: Where to begin iterating.
    /// - parameter match: Glob-style pattern to match elements against.
    /// - parameter count: Amount of elements to try to iterate.
    /// - parameter callback: The callback function.
    /// - parameter newCursor: The new cursor to be used to continue iterating
    ///                        remaining elements. If 0, all elements have been
    ///                        iterated.
    /// - parameter res: The results of the scan.
    /// - parameter err: The error, if one occured.
    public func scan(cursor: Int, match: String?=nil, count: Int?=nil, callback: (_ newCursor: RedisString?, _ res: [RedisString?]?, _ err: NSError?) -> Void) {
        if let match = match, let count = count {
            issueCommand("SCAN", String(cursor), "MATCH", match, "COUNT", String(count)) {(res: RedisResponse) in
                redisScanResponseHandler(res, callback: callback)
            }
        } else if let match = match {
            issueCommand("SCAN", String(cursor), "MATCH", match) {(res: RedisResponse) in
                redisScanResponseHandler(res, callback: callback)
            }
        } else if let count = count {
            issueCommand("SCAN", String(cursor), "COUNT", String(count)) {(res: RedisResponse) in
                redisScanResponseHandler(res, callback: callback)
            }
        } else {
            issueCommand("SCAN", String(cursor)) {(res: RedisResponse) in
                redisScanResponseHandler(res, callback: callback)
            }
        }
    }

    
    /// Set a key to hold a value. If key already holds a value, it is overwritten.
    ///
    /// - Parameter key: The key.
    /// - Parameter value: The String value to set.
    /// - Parameter exists: If true will only set the key if it already exists. If false will only set the key if it doesn't already exist.
    /// - Parameter expiresIn: If not nil, the expiration time, in milliseconds.
    /// - Parameter callback: The callback function after setting the value. Bool will be
    ///                      true if the key was set. NSError will be non-nil if an error occurred.
    public func set(_ key: String, value: String, exists: Bool?=nil, expiresIn: TimeInterval?=nil, callback: (Bool, NSError?) -> Void) {
        
        var command = ["SET", key, value]
        if let exists = exists {
            command.append(exists ? "XX" : "NX")
        }
        if let expiresIn = expiresIn {
            command.append("PX")
            command.append(String(Int(expiresIn * 1000.0)))
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            let (ok, error) = self.redisOkResponseHandler(response)
            callback(ok, _: error)
        }
    }

    /// Set a key to hold a value. If key already holds a value, it is overwritten.
    ///
    /// - Parameter key: The key.
    /// - Parameter value: The `RedisString` value to set.
    /// - Parameter exists: If true will only set the key if it already exists. If false will only set the key if it doesn't already exist.
    /// - Parameter expiresIn: If not nil, the expiration time, in milliseconds.
    /// - Parameter callback: The callback function after setting the value. Bool will be
    ///                      true if the key was set. NSError will be non-nil if an error occurred.
    public func set(_ key: String, value: RedisString, exists: Bool?=nil, expiresIn: TimeInterval?=nil, callback: (Bool, NSError?) -> Void) {
        
        var command = [RedisString("SET"), RedisString(key), value]
        if let exists = exists {
            command.append(RedisString(exists ? "XX" : "NX"))
        }
        if let expiresIn = expiresIn {
            command.append(RedisString("PX"))
            command.append(RedisString(Int(expiresIn * 1000.0)))
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            let (ok, error) = self.redisOkResponseHandler(response)
            callback(ok, _: error)
        }
    }

    /// Sets the bit value at an offset in the string value stored at the key.
    ///
    /// - Parameter key: The key.
    /// - Parameter offset: The offset in the string value.
    /// - Parameter value: The bit value to set.
    /// - Parameter callback: The callback function, the Bool will conatain the original bit value
    ///                      stored at the offset. NSError will be non-nil if an error occurred.
    public func setbit(_ key: String, offset: Int, value: Bool, callback: (Bool, NSError?) -> Void) {
        issueCommand("SETBIT", key, String(offset), value ? "1" : "0") {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    /// Overwrites part of the string stored at key, starting at the specified offset, for the entire length of value
    ///
    /// - Parameter key: The key.
    /// - Parameter offset: Integer index for the starting position within the key's value to overwrite.
    /// - Parameter value: The String value to overwrite the value of the key with.
    /// - Parameter callback: The callback function, the Int will contain the length of the key's value
    ///                      after it was modified by the command. NSError will be non-nil if an error occurred.
    public func setrange(_ key: String, offset: Int, value: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("SETRANGE", key, String(offset), value) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// A parameter of the SORT command
    /// (offset, count)
    public typealias Limit = (Int, Int)
    
    /// Returns or stores the elements contained in the list, set or sorted set
    /// at key.
    ///
    /// - parameter key: They key for the list, set, or sorted set.
    /// - parameter pattern: Pattern used to generate keys used for sorting.
    /// - parameter limit: (offset, count) where `offset` is the  number of
    ///                    elements to skip in the result, and `count` is the
    ///                    number of elements to return starting from `offset`.
    /// - parameter get: Pattern to use to retrieve an external key based on the
    ///                  elements in the list. Multiple `get`s can be chained to
    ///                  retrieve multiple external keys.
    /// - parameter desc: Sort the list from large to small.
    /// - parameter alpha: Sort the list of string values lexicographically.
    /// - parameter store: The key to where the result should be stored.
    /// - parameter callback: The callback function.
    /// - parameter res: The list of sorted elements. If `store` is used, array
    ///                  contains one element indicating number of values
    ///                  stored.
    /// - parameter err: The error, if one occurred.
    public func sort(key: String, by pattern: String?=nil, limit: Limit?=nil, get: String..., desc: Bool?=false, alpha: Bool?=false, store: String?=nil, callback: (_ res: [RedisString?]?, _ err: NSError?) -> Void) {
        sortArrayOfGetPatterns(key: key, by: pattern, limit: limit, get: get, desc: desc, alpha: alpha, store: store, callback: callback)
    }
    
    /// Returns or stores the elements contained in the list, set or sorted set
    /// at key.
    ///
    /// - parameter key: They key for the list, set, or sorted set.
    /// - parameter pattern: Pattern used to generate keys used for sorting.
    /// - parameter limit: (offset, count) where `offset` is the  number of 
    ///                    elements to skip in the result, and `count` is the 
    ///                    number of elements to return starting from `offset`.
    /// - parameter get: Pattern to use to retrieve an external key based on the
    ///                  elements in the list. Multiple `get`s can be chained to
    ///                  retrieve multiple external keys.
    /// - parameter desc: Sort the list from large to small.
    /// - parameter alpha: Sort the list of string values lexicographically.
    /// - parameter store: The key to where the result should be stored.
    /// - parameter callback: The callback function.
    /// - parameter res: The list of sorted elements. If `store` is used, array
    ///                  contains one element indicating number of values
    ///                  stored.
    /// - parameter err: The error, if one occurred.
    public func sortArrayOfGetPatterns(key: String, by pattern: String?=nil, limit: Limit?=nil, get: [String], desc: Bool?=false, alpha: Bool?=false, store: String?=nil, callback: (_ res: [RedisString?]?, _ err: NSError?) -> Void) {
        var command = ["SORT", key]
        if let pattern = pattern {
            command.append("BY")
            command.append(pattern)
        }
        if let limit = limit {
            command.append("LIMIT")
            command.append(String(limit.0))
            command.append(String(limit.1))
        }
        for pattern in get {
            command.append("GET")
            command.append(pattern)
        }
        if let desc = desc, desc {
            command.append("DESC")
        }
        if let alpha = alpha, alpha {
            command.append("ALPHA")
        }
        if let destination = store {
            command.append("STORE")
            command.append(destination)
        }
        issueCommandInArray(command) { (res) in
            redisStringArrayOrIntegerResponseHandler(res, callback: callback)
        }
    }
    
    /// Returns the length of the string value stored at the key
    ///
    /// - Parameter key: The key.
    /// - Parameter callback: The callback function, the Int will contain the length of the string.
    ///                      NSError will be non-nil if an error occurred.
    public func strlen(_ key: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("STRLEN", key) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Alters the last access time of a key(s). A key is ignored if it does not 
    /// exist.
    ///
    /// - parameter key: The key to touch.
    /// - parameter keys: Additional keys to touch.
    /// - parameter callback: The callback function.
    /// - parameter res: The number of keys that were touched.
    /// - parameter err: The error, if one occurred.
    public func touch(key: String, keys: String..., callback: (_ res: Int?, _ err: NSError?) -> Void) {
        touchArrayOfKeys(key: key, keys: keys, callback: callback)
    }
    
    /// Alters the last access time of a key(s). A key is ignored if it does not
    /// exist.
    ///
    /// - parameter key: The key to touch.
    /// - parameter keys: Additional keys to touch.
    /// - parameter callback: The callback function.
    /// - parameter res: The number of keys that were touched.
    /// - parameter err: The error, if one occurred.
    public func touchArrayOfKeys(key: String, keys: [String], callback: (_ res: Int?, _ err: NSError?) -> Void) {
        var command = ["TOUCH", key]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) { (res) in
            redisIntegerResponseHandler(res, callback: callback)
        }
    }
    
    /// Get the remaining time to live of a key that has an expiration period set.
    ///
    /// - Parameter key: The key.
    /// - Parameter callback: The callback function, the TimeInterval will contain:
    ///   - The remaining time to live of the key, specified in milliseconds
    ///   - -2 if the key does not exist
    ///   - -1 if the key exists but has no associated expiration period.
    ///   NSError will be non-nil if an error occurred.
    public func ttl(_ key: String, callback: (TimeInterval?, NSError?) -> Void) {
        issueCommand("PTTL", key) {(response: RedisResponse) in
            switch(response) {
            case .IntegerValue(let num):
                if  num >= 0 {
                    callback(TimeInterval(Double(num)/1000.0), nil)
                } else {
                    callback(TimeInterval(num), nil)
                }
            case .Error(let error):
                callback(nil, _: self.createError("Error: \(error)", code: 1))
            default:
                callback(nil, _: self.createUnexpectedResponseError(response))
            }
        }
    }
    
    /// Returns the string representation of the type of the value stored at 
    /// `key`. The different types that can be returned are: string, list, set,
    /// zset and hash.
    ///
    /// - parameter key: The key to get the type of.
    /// - parameter callback: The callback function.
    /// - parameter res: The type of key, or none when key does not exist.
    /// - parameter err: The error, if one occurred.
    public func type(key: String, callback: (_ res: String?, _ err: NSError?) -> Void) {
        issueCommand("TYPE", key) { (res) in
            redisSimpleStringResponseHandler(response: res, callback: callback)
        }
    }
}
