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

/// Extend Redis by adding the Set operations
extension Redis {
    
    /// Add one or more members to a set
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter memebers: an variadic parameter of the values to be added to the set
    ///
    /// Returns: The number of elements that were added to the set, not including all the
    ///         elements already present into the set.
    public func sadd(_ key: String, members: String..., callback: (Int?, NSError?) -> Void) {
        saddArrayOfMembers(key, members: members, callback: callback)
    }
    
    /// Add one or more members to a set
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter memebers: an array parameter of the values to be added to the set
    ///
    /// Returns: The number of elements that were added to the set, not including
    ///         all the elements already present into the set.
    public func saddArrayOfMembers(_ key: String, members: [String], callback: (Int?, NSError?) -> Void) {
        var command = ["SADD", key]
        for member in members {
            command.append(member)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Add one or more members to a set
    ///
    /// - Parameter key: the RedisString parameter for the key
    /// - Parameter memebers: an variadic parameter of the values to be added to the set
    ///
    /// Returns: The number of elements that were added to the set, not including all the elements
    ///         already present into the set.
    public func sadd(_ key: RedisString, members: RedisString..., callback: (Int?, NSError?) -> Void) {
        saddArrayOfMembers(key, members: members, callback: callback)
    }
    
    /// Add one or more members to a set
    ///
    /// - Parameter key: the RedisString parameter for the key
    /// - Parameter memebers: an array parameter of the values to be added to the set
    ///
    /// Returns: The number of elements that were added to the set, not including all the elements
    ///         already present into the set.
    public func saddArrayOfMembers(_ key: RedisString, members: [RedisString], callback: (Int?, NSError?) -> Void) {
        var command = [RedisString("SADD"), key]
        for member in members {
            command.append(member)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Get the number of members in a set
    /// - Parameter key: the String paramter for the key
    ///
    /// Returns: The cardinality (number of elements) of the set, or 0 if key does not exist.
    public func scard(_ key: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("SCARD", key) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Get the number of members in a set
    /// - Parameter key: the RedisString paramter for the key
    ///
    /// Returns: The number of elements in the set, or 0 if key does not exist.
    public func scard(_ key: RedisString, callback: (Int?, NSError?) -> Void) {
        issueCommand(RedisString("SCARD"), key) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Subtract multiple sets
    ///
    /// - Parameter keys: an variadic parameter of the keys to get the difference from
    ///
    /// Returns: An array of the members of the resulting set.
    public func sdiff(keys: String..., callback: ([RedisString?]?, NSError?) -> Void) {
        sdiffArrayOfKeys(keys: keys, callback: callback)
    }
    
    /// Subtract multiple sets
    ///
    /// - Parameter keys: an array parameter of the keys to get the difference from
    ///
    /// Returns: Array reply: list with members of the resulting set.
    public func sdiffArrayOfKeys(keys: [String], callback: ([RedisString?]?, NSError?) -> Void) {
        var command = ["SDIFF"]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    /// Subtract multiple sets
    ///
    /// - Parameter keys: an variadic parameter of the keys to get the difference from
    ///
    /// Returns: Array reply: list with members of the resulting set.
    public func sdiff(keys: RedisString..., callback: ([RedisString?]?, NSError?) -> Void) {
        sdiffArrayOfKeys(keys: keys, callback: callback)
    }
    
    /// Subtract multiple sets
    ///
    /// - Parameter keys: an array parameter of the keys to get the difference from
    ///
    /// Returns: Array reply: list with members of the resulting set.
    public func sdiffArrayOfKeys(keys: [RedisString], callback: ([RedisString?]?, NSError?) -> Void) {
        var command = [RedisString("SDIFF")]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    /// Subtract multiple sets and store the resulting set in a key
    ///
    /// - Parameter destination: the destination of the result,
    ///                             if destination already exists, it is overwritten
    /// - Paramter keys: a variadic parameter of the keys to get the difference from
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
    public func sdiffstore(destination: String, keys: String...,
        callback: (Int?, NSError?) -> Void) {
        self.sdiffstoreArrayOfKeys(destination: destination, keys: keys, callback: callback)
    }
    
    /// Subtract multiple sets and store the resulting set in a key
    ///
    /// - Parameter destination: the destination of the result
    /// - Paramter keys: a array parameter of the keys to get the difference from
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
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
    
    /// Subtract multiple sets and store the resulting set in a key
    ///
    /// - Parameter destination: the destination of the result,
    ///                             if destination already exists, it is overwritten
    /// - Paramter keys: a variadic parameter of the keys to get the difference from
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
    public func sdiffstore(destination: RedisString, keys: RedisString...,
        callback: (Int?, NSError?) -> Void) {
        self.sdiffstoreArrayOfKeys(destination: destination, keys: keys, callback: callback)
    }
    
    /// Subtract multiple sets and store the resulting set in a key
    ///
    /// - Parameter destination: the destination of the result
    /// - Paramter keys: a array parameter of the keys to get the difference from
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
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
    
    /// Get all the members in a set
    ///
    /// - Parameter key: the String parameter for the key
    ///
    /// Returns: Array reply: all elements of the set.
    public func smembers(_ key: String, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand(RedisString("SMEMBERS"), RedisString(key)) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    /// Get all the members in a set
    ///
    /// - Parameter key: the RedisString parameter for the key
    ///
    /// Returns: Array reply: all elements of the set.
    public func smembers(_ key: RedisString, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand(RedisString("SMEMBERS"), key) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    /// Intersect multiple sets
    ///
    /// - Parameter keys: a variadic parameter of the keys to intersect from
    ///
    /// Returns: Array reply: list with members of the resulting set.
    public func sinter(_ keys: String..., callback: ([RedisString?]?, NSError?) -> Void) {
        self.sinterArrayOfKeys(keys, callback: callback)
    }
    
    /// Intersect multiple sets
    ///
    /// - Parameter keys: an array parameter of the keys to intersect from
    ///
    /// Returns: Array reply: list with members of the resulting set.
    public func sinterArrayOfKeys(_ keys: [String], callback: ([RedisString?]?, NSError?) -> Void) {
        var command = ["SINTER"]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    /// Intersect multiple sets
    ///
    /// - Parameter keys: a variadic parameter of the keys to intersect from
    ///
    /// Returns: Array reply: list with members of the resulting set.
    public func sinter(_ keys: RedisString..., callback: ([RedisString?]?, NSError?) -> Void) {
        self.sinterArrayOfKeys(keys, callback: callback)
    }
    
    /// Intersect multiple sets
    ///
    /// - Parameter keys: an array parameter of the keys to intersect from
    ///
    /// Returns: Array reply: list with members of the resulting set.
    public func sinterArrayOfKeys(_ keys: [RedisString], callback: ([RedisString?]?, NSError?) -> Void) {
        var command = [RedisString("SINTER")]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    /// Intersect multiple sets and store the resulting set in a key
    ///
    /// - Parameter destination: the destination of the result
    /// - Parameter keys: a variadic parameter of the keys to intersect from
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
    public func sinterstore(_ destination: String, keys: String..., callback: (Int?, NSError?) -> Void) {
        self.sinterstoreArrayOfKeys(destination, keys: keys, callback: callback)
    }
    
    /// Intersect multiple sets and store the resulting set in a key
    ///
    /// - Parameter destination: the destination of the result
    /// - Parameter keys: an array parameter of the keys to intersect from
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
    public func sinterstoreArrayOfKeys(_ destination: String, keys: [String], callback: (Int?, NSError?) -> Void) {
        var command = ["SINTERSTORE", destination]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Intersect multiple sets and store the resulting set in a key
    ///
    /// - Parameter destination: the destination of the result
    /// - Parameter keys: a variadic parameter of the keys to intersect from
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
    public func sinterstore(_ destination: RedisString, keys: RedisString..., callback: (Int?, NSError?) -> Void) {
        self.sinterstoreArrayOfKeys(destination, keys: keys, callback: callback)
    }
    
    /// Intersect multiple sets and store the resulting set in a key
    ///
    /// - Parameter destination: the destination of the result
    /// - Parameter keys: an array parameter of the keys to intersect from
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
    public func sinterstoreArrayOfKeys(_ destination: RedisString, keys: [RedisString], callback: (Int?, NSError?) -> Void) {
        var command = [RedisString("SINTERSTORE"), destination]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Determine if a given value is a member of a set
    ///
    /// - Parameter key: the String paramter for the key
    /// - Parameter member: the String paramter for the member
    ///
    /// Returns: Bool reply: True if element is a member of the set,
    ///                      False if the element isn't a member of the set, or if key doesn't exist.
    public func sismember(_ key: String, member: String, callback: (Bool?, NSError?) -> Void) {
        issueCommand("SISMEMBER", key, member) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    /// Determine if a given value is a member of a set
    ///
    /// - Parameter key: the RedisString paramter for the key
    /// - Parameter member: the RedisString paramter for the member
    ///
    /// Returns: Bool reply: True if element is a member of the set,
    ///                      False if the element isn't a member of the set, or if key doesn't exist.
    public func sismember(_ key: RedisString, member: RedisString, callback: (Bool?, NSError?) -> Void) {
        issueCommand(RedisString("SISMEMBER"), key, member) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    /// Move a member from one set to another
    ///
    /// - Parameter source: the Source set from where to move the member from
    /// - Parameter destination: the Destination set from where to move the member to
    /// - Parameter member: the String parameter for the member to be moved
    ///
    /// Returns: Bool reply: True if element is moved,
    ///                      False if the element isn't a member of source and
    ///                             no operation was performed.
    public func smove(source: String, destination: String, member: String, callback: (Bool?, NSError?) -> Void) {
        issueCommand("SMOVE", source, destination, member) {
            (response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    /// Move a member from one set to another
    ///
    /// - Parameter source: the Source set from where to move the member from
    /// - Parameter destination: the Destination set from where to move the member to
    /// - Parameter member: the RedisString parameter for the member to be moved
    ///
    /// Returns: Bool reply: True if element is moved,
    ///                      False if the element isn't a member of source and
    ///                             no operation was performed.
    public func smove(source: RedisString, destination: RedisString, member: RedisString, callback: (Bool?, NSError?) -> Void) {
        issueCommand(RedisString("SMOVE"), source, destination, member) {
            (response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    /// Remove and return one or multiple random members from a set
    ///
    /// - Parameter key: the String parameter for the key
    ///
    /// Returns: Bulk string reply: the removed element, or nil when key does not exist.
    public func spop(_ key: String, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("SPOP", key) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Remove and return one or multiple random members from a set
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter count: the number of members to pop
    ///
    /// Returns: Bulk string reply: the removed element, or nil when key does not exist.
    public func spop(_ key: String, count: Int, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand("SPOP", key, String(count)) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    /// Remove and return one or multiple random members from a set
    ///
    /// - Parameter key: the RedisString parameter for the key
    ///
    /// Returns: Bulk string reply: the removed element, or nil when key does not exist.
    public func spop(_ key: RedisString, callback: (RedisString?, NSError?) -> Void) {
        issueCommand(RedisString("SPOP"), key) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Remove and return one or multiple random members from a set
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter count: the number of members to pop
    ///
    /// Returns: Bulk string reply: the removed element, or nil when key does not exist.
    public func spop(_ key: RedisString, count: Int, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand(RedisString("SPOP"), key, RedisString(count)) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    /// Get one or multiple random members from a set
    ///
    /// - Parameter key: the String parameter for the key
    ///
    /// Returns: Bulk string reply: the randomly selected element, or nil when key does not exist.
    public func srandmember(_ key: String, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("SRANDMEMBER", key) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Get one or multiple random members from a set
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter count: the number of members to return
    ///
    /// Returns: Array reply: an array of elements, or an empty array when key does not exist.
    public func srandmember(_ key: String, count: Int, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand("SRANDMEMBER", key, String(count)) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    /// Get one or multiple random members from a set
    ///
    /// - Parameter key: the RedisString parameter for the key
    ///
    /// Returns: Bulk string reply: the randomly selected element, or nil when key does not exist.
    public func srandmember(_ key: RedisString, callback: (RedisString?, NSError?) -> Void) {
        issueCommand(RedisString("SRANDMEMBER"), key) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Get one or multiple random members from a set
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter count: the number of members to return
    ///
    /// Returns: Array reply: an array of elements, or an empty array when key does not exist.
    public func srandmember(_ key: RedisString, count: Int, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand(RedisString("SRANDMEMBER"), key, RedisString(count)) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    /// Remove one or more members from a set
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter members: the variadic parameter for the members to be removed
    ///
    /// Returns: Integer reply: the number of members that were removed from the set,
    ///                         not including non existing members.
    public func srem(_ key: String, members: String..., callback: (Int?, NSError?) -> Void) {
        self.sremArrayOfMembers(key, members: members, callback: callback)
    }
    
    /// Remove one or more members from a set
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter members: the Array parameter for the members to be removed
    ///
    /// Returns: Integer reply: the number of members that were removed from the set,
    ///                         not including non existing members.
    public func sremArrayOfMembers(_ key: String, members: [String], callback: (Int?, NSError?) -> Void) {
        var command = ["SREM", key]
        for member in members {
            command.append(member)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Remove one or more members from a set
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter members: the variadic parameter for the members to be removed
    ///
    /// Returns: Integer reply: the number of members that were removed from the set,
    ///                         not including non existing members.
    public func srem(_ key: RedisString, members: RedisString..., callback: (Int?, NSError?) -> Void) {
        self.sremArrayOfMembers(key, members: members, callback: callback)
    }
    
    /// Remove one or more members from a set
    ///
    /// - Parameter key: the RedisString parameter for the key
    /// - Parameter members: the array parameter for the members to be removed
    ///
    /// Returns: Integer reply: the number of members that were removed from the set,
    ///                         not including non existing members.
    public func sremArrayOfMembers(_ key: RedisString, members: [RedisString], callback: (Int?, NSError?) -> Void) {
        var command = [RedisString("SREM"), key]
        for member in members {
            command.append(member)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Add multiple sets
    ///
    /// - Parameter keys: a variadic parater for the keys to union
    ///
    /// Returns: Array reply: list with members of the resulting set.
    public func sunion(_ keys: String..., callback: ([RedisString?]?, NSError?) -> Void) {
        self.sunionArrofOfKeys(keys, callback: callback)
    }
    
    /// Add multiple sets
    ///
    /// - Parameter keys: a variadic parater for the keys to union
    ///
    /// Returns: Array reply: list with members of the resulting set.
    public func sunionArrofOfKeys(_ keys: [String], callback: ([RedisString?]?, NSError?) -> Void) {
        var command = ["SUNION"]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    /// Add multiple sets
    ///
    /// - Parameter keys: a variadic parater for the keys to union
    ///
    /// Returns: Array reply: list with members of the resulting set.
    public func sunion(_ keys: RedisString..., callback: ([RedisString?]?, NSError?) -> Void) {
        self.sunionArrofOfKeys(keys, callback: callback)
    }
    
    /// Add multiple sets
    ///
    /// - Parameter keys: a variadic parater for the keys to union
    ///
    /// Returns: Array reply: list with members of the resulting set.
    public func sunionArrofOfKeys(_ keys: [RedisString], callback: ([RedisString?]?, NSError?) -> Void) {
        var command = [RedisString("SUNION")]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    /// Add multiple sets
    ///
    /// - Parameter keys: a variadic parater for the keys to union
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
    public func sunionstore(_ destination: String, keys: String..., callback: (Int?, NSError?) -> Void) {
        self.sunionstoreArrofOfKeys(destination, keys: keys, callback: callback)
    }
    
    /// Add multiple sets
    ///
    /// - Parameter keys: a variadic parater for the keys to union
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
    public func sunionstoreArrofOfKeys(_ destination: String, keys: [String], callback: (Int?, NSError?) -> Void) {
        var command = ["SUNIONSTORE", destination]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Add multiple sets
    ///
    /// - Parameter keys: a variadic parater for the keys to union
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
    public func sunionstore(_ destination: RedisString, keys: RedisString..., callback: (Int?, NSError?) -> Void) {
        self.sunionstoreArrofOfKeys(destination, keys: keys, callback: callback)
    }
    
    /// Add multiple sets
    ///
    /// - Parameter keys: a variadic parater for the keys to union
    ///
    /// Returns: Integer reply: the number of elements in the resulting set.
    public func sunionstoreArrofOfKeys(_ destination: RedisString, keys: [RedisString], callback: (Int?, NSError?) -> Void) {
        var command = [RedisString("SUNIONSTORE"), destination]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
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
}
