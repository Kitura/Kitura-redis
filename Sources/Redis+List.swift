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

/// Extend Redis by adding the List operations
extension Redis {

    /// Retrieve an item from one of many lists, potentially blocking until one of the lists has an element
    ///
    /// - Parameter keys: the keys of the lists to check for an element
    /// - Parameter timeout: Amount of time to wait or zero to wait for ever
    public func blpop(_ keys: String..., timeout: TimeInterval, callback: ([RedisString?]?, NSError?) -> Void) {
        
        var command = ["BLPOP"]
        for key in keys {
            command.append(key)
        }
        command.append(String(Int(timeout)))
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    /// Retrieve an item from the end of one of many lists, potentially blocking until one of the lists has an element
    ///
    /// - Parameter keys: the keys of the lists to check for an element
    /// - Parameter timeout: Amount of time to wait or zero to wait for ever
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
    
    /// Remove and return the last value of a list and push it onto another list, blocking until there is an item to pop
    ///
    /// - Parameter source: The list to pop an item from
    /// - Parameter destination: The list to push the poped item ontoParameter source: The list to pop an item from
    /// - Parameter destination: The list to push the poped item onto
    public func brpoplpush(_ source: String, destination: String, timeout: TimeInterval, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("BRPOPLPUSH", source, destination, String(Int(timeout))) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Retrieve an element from a list by index
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter index: The index of the element to retrieve
    public func lindex(_ key: String, index: Int, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("LINDEX", key, String(index)) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Insert a value into a list before or after a pivot
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter before: Whether the value is inserted before or after the pivot
    /// - Parameter pivot: The pivot around which the value will be inserted
    /// - Parameter value: The value to be inserted
    public func linsert(_ key: String, before: Bool, pivot: String, value: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("LINSERT", key, (before ? "BEFORE" : "AFTER"), pivot, value) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Insert a value into a list before or after a pivot
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter before: Whether the value is inserted before or after the pivot
    /// - Parameter pivot: The pivot around which the value will be inserted
    /// - Parameter value: The value to be inserted
    public func linsert(_ key: String, before: Bool, pivot: RedisString, value: RedisString, callback: (Int?, NSError?) -> Void) {
        issueCommand(RedisString("LINSERT"), RedisString(key), RedisString(before ? "BEFORE" : "AFTER"), pivot, value) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Get the length of a list
    ///
    /// - Parameter key: the String parameter for the key
    public func llen(_ key: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("LLEN", key) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Pop a value from a list
    ///
    /// - Parameter key: the String parameter for the key
    public func lpop(_ key: String, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("LPOP", key) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Push a set of values on to a list
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: A variadic parameter of the values to be pushed on to the list
    public func lpush(_ key: String, values: String..., callback: (Int?, NSError?) -> Void) {
        lpushArrayOfValues(key, values: values, callback: callback)
    }
    
    /// Push a set of values on to a list
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: An array parameter of the values to be pushed on to the list
    public func lpushArrayOfValues(_ key: String, values: [String], callback: (Int?, NSError?) -> Void) {
        var command = ["LPUSH", key]
        for value in values {
            command.append(value)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Push a set of values on to a list
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: A variadic parameter of the values to be pushed on to the list
    public func lpush(_ key: String, values: RedisString..., callback: (Int?, NSError?) -> Void) {
        lpushArrayOfValues(key, values: values, callback: callback)
    }
    
    /// Push a set of values on to a list
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: An array parameter of the values to be pushed on to the list
    public func lpushArrayOfValues(_ key: String, values: [RedisString], callback: (Int?, NSError?) -> Void) {
        var command = [RedisString("LPUSH"), RedisString(key)]
        for value in values {
            command.append(value)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Push a value on to a list, only if the list exists
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: An array parameter of the values to be pushed on to the list
    public func lpushx(_ key: String, value: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("LPUSHX", key, value) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Push a value on to a list, only if the list exists
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: An array parameter of the values to be pushed on to the list
    public func lpushx(_ key: String, value: RedisString, callback: (Int?, NSError?) -> Void) {
        issueCommand(RedisString("LPUSHX"), RedisString(key), value) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Retrieve a group of elements from a list as specified by a range
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter start: The index to start retrieving from
    /// - Parameter end: The index to stop at
    public func lrange(_ key: String, start: Int, end: Int, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand("LRANGE", key, String(start), String(end)) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    /// Remove a number of elements that match the supplied value from the list
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter count: the number of elements to remove
    /// - Parameter value: the value of the eleemnts to remove
    public func lrem(_ key: String, count: Int, value: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("LREM", key, String(count), value) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Remove a number of elements that match the supplied value from the list
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter count: the number of elements to remove
    /// - Parameter value: the value of the eleemnts to remove
    public func lrem(_ key: String, count: Int, value: RedisString, callback: (Int?, NSError?) -> Void) {
        issueCommand(RedisString("LREM"), RedisString(key), RedisString(count), value) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Set a value in a list to a new value
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter index: the index of the value in the list to be updated
    /// - Parameter value: The new value for the element of the list
    public func lset(_ key: String, index: Int, value: String, callback: (Bool, NSError?) -> Void) {
        issueCommand("LSET", key, String(index), value) {(response: RedisResponse) in
            let (ok, error) = self.redisOkResponseHandler(response)
            callback(ok, _: error)
        }
    }
    
    /// Set a value in a list to a new value
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter index: the index of the value in the list to be updated
    /// - Parameter value: The new value for the element of the list
    public func lset(_ key: String, index: Int, value: RedisString, callback: (Bool, NSError?) -> Void) {
        issueCommand(RedisString("LSET"), RedisString(key), RedisString(index), value) {(response: RedisResponse) in
            let (ok, error) = self.redisOkResponseHandler(response)
            callback(ok, _: error)
        }
    }
    
    /// Trim a list to a new size
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter start: the starting of the list to keep
    /// - Parameter end: the ending point of the list to keep
    public func ltrim(_ key: String, start: Int, end: Int, callback: (Bool, NSError?) -> Void) {
        issueCommand("LTRIM", key, String(start), String(end)) {(response: RedisResponse) in
            let (ok, error) = self.redisOkResponseHandler(response)
            callback(ok, _: error)
        }
    }
    
    /// Remove and return the last value of a list
    ///
    /// - Parameter key: the String parameter for the key
    public func rpop(_ key: String, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("RPOP", key) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Remove and return the last value of a list and push it onto another list
    ///
    /// - Parameter source: The list to pop an item from
    /// - Parameter destination: The list to push the poped item onto
    public func rpoplpush(_ source: String, destination: String, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("RPOPLPUSH", source, destination) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Append a set of values to a list
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: A variadic parameter of the values to be pushed on to the list
    public func rpush(_ key: String, values: String..., callback: (Int?, NSError?) -> Void) {
        rpushArrayOfValues(key, values: values, callback: callback)
    }
    
    /// Append a set of values to a list
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: An array parameter of the values to be pushed on to the list
    public func rpushArrayOfValues(_ key: String, values: [String], callback: (Int?, NSError?) -> Void) {
        var command = ["RPUSH", key]
        for value in values {
            command.append(value)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Append a set of values to a list
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: A variadic parameter of the values to be pushed on to the list
    public func rpush(_ key: String, values: RedisString..., callback: (Int?, NSError?) -> Void) {
        rpushArrayOfValues(key, values: values, callback: callback)
    }
    
    /// Append a set of values to a list
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: An array parameter of the values to be pushed on to the list
    public func rpushArrayOfValues(_ key: String, values: [RedisString], callback: (Int?, NSError?) -> Void) {
        var command = [RedisString("RPUSH"), RedisString(key)]
        for value in values {
            command.append(value)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Append a value to a list, only if the list exists
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: An array parameter of the values to be pushed on to the list
    public func rpushx(_ key: String, value: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("RPUSHX", key, value) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Append a value to a list, only if the list exists
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter values: An array parameter of the values to be pushed on to the list
    public func rpushx(_ key: String, value: RedisString, callback: (Int?, NSError?) -> Void) {
        issueCommand(RedisString("RPUSHX"), RedisString(key), value) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
}
