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

/// Extend Redis by adding the Set operations
extension Redis {

    //
    //  MARK: Set API functions
    //
    
    /// Add one or more members to a set
    ///
    /// - Parameter key: The key.
    /// - Parameter members: The values to be added to the set.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                      number of elements that were added to the set.
    ///                      NSError will be non-nil if an error occurred.
    public func sadd(_ key: String, members: String..., callback: (Int?, NSError?) -> Void) {
        saddArrayOfMembers(key, members: members, callback: callback)
    }

    /// Add one or more members to a set
    ///
    /// - Parameter key: The key.
    /// - Parameter members: An array of values to be added to the set.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                      number of elements that were added to the set.
    ///                      NSError will be non-nil if an error occurred.
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
    /// - Parameter key: The key.
    /// - Parameter members: The `RedisString` values to be added to the set.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                      number of elements that were added to the set.
    ///                      NSError will be non-nil if an error occurred.
    public func sadd(_ key: RedisString, members: RedisString..., callback: (Int?, NSError?) -> Void) {
        saddArrayOfMembers(key, members: members, callback: callback)
    }

    /// Add one or more members to a set
    ///
    /// - Parameter key: The key.
    /// - Parameter members: An array of `RedisString` values to be added to the set.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                      number of elements that were added to the set.
    ///                      NSError will be non-nil if an error occurred.
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
    ///
    /// - Parameter key: The key.
    /// - Parameter callback: The callback function, the Int will contain the cardinality
    ///                      (number of elements) of the set, or 0 if key does not exist.
    ///                      NSError will be non-nil if an error occurred.
    public func scard(_ key: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("SCARD", key) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    /// Get the number of members in a set
    ///
    /// - Parameter key: The key.
    /// - Parameter callback: The callback function, the Int will contain the cardinality
    ///                      (number of elements) of the set, or 0 if key does not exist.
    ///                      NSError will be non-nil if an error occurred.
    public func scard(_ key: RedisString, callback: (Int?, NSError?) -> Void) {
        issueCommand(RedisString("SCARD"), key) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    /// Subtract multiple sets
    ///
    /// - Parameter keys: The list of keys to get the difference from.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain the
    ///                      members of the resulting set.
    ///                      NSError will be non-nil if an error occurred.
    public func sdiff(keys: String..., callback: ([RedisString?]?, NSError?) -> Void) {
        sdiffArrayOfKeys(keys: keys, callback: callback)
    }

    /// Subtract multiple sets
    ///
    /// - Parameter keys: An array of the keys to get the difference from.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain the
    ///                      members of the resulting set.
    ///                      NSError will be non-nil if an error occurred.
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
    /// - Parameter keys: The list of the keys to get the difference from.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain the
    ///                      members of the resulting set.
    ///                      NSError will be non-nil if an error occurred.
    public func sdiff(keys: RedisString..., callback: ([RedisString?]?, NSError?) -> Void) {
        sdiffArrayOfKeys(keys: keys, callback: callback)
    }

    /// Subtract multiple sets
    ///
    /// - Parameter keys: An array of the keys to get the difference from.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain the
    ///                      members of the resulting set.
    ///                      NSError will be non-nil if an error occurred.
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
    /// - Parameter destination: The destination of the result, if the
    ///                         destination already exists, it is overwritten
    /// - Parameter keys: The list of the keys to get the difference from.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                      number of elements in the resulting set.
    ///                      NSError will be non-nil if an error occurred.
    public func sdiffstore(destination: String, keys: String...,
        callback: (Int?, NSError?) -> Void) {
        self.sdiffstoreArrayOfKeys(destination: destination, keys: keys, callback: callback)
    }

    /// Subtract multiple sets and store the resulting set in a key
    ///
    /// - Parameter destination: The destination of the result.
    /// - Parameter keys: An array of the keys to get the difference from.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                      number of elements in the resulting set.
    ///                      NSError will be non-nil if an error occurred.
    public func sdiffstoreArrayOfKeys(destination: String, keys: [String],
                                      callback: (Int?, NSError?) -> Void) {
        var command = ["SDIFFSTORE", destination]
        for key in keys {
            command.append(key)
        }
        self.issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    /// Subtract multiple sets and store the resulting set in a key
    ///
    /// - Parameter destination: The destination of the result, if the
    ///                         destination already exists, it is overwritten
    /// - Parameter keys: The list of the keys to get the difference from.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                      number of elements in the resulting set.
    ///                      NSError will be non-nil if an error occurred.
    public func sdiffstore(destination: RedisString, keys: RedisString...,
        callback: (Int?, NSError?) -> Void) {
        self.sdiffstoreArrayOfKeys(destination: destination, keys: keys, callback: callback)
    }

    /// Subtract multiple sets and store the resulting set in a key
    ///
    /// - Parameter destination: Tthe destination of the result.
    /// - Parameter keys: An array of keys to get the difference from.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                      number of elements in the resulting set.
    ///                      NSError will be non-nil if an error occurred.
    public func sdiffstoreArrayOfKeys(destination: RedisString, keys: [RedisString],
                                      callback: (Int?, NSError?) -> Void) {

        var command = [RedisString("SDIFFSTORE"), destination]
        for key in keys {
            command.append(key)
        }
        self.issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    /// Get all the members in a set
    ///
    /// - Parameter key: The key.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain
    ///                      the elements in the set.
    ///                      NSError will be non-nil if an error occurred.
    public func smembers(_ key: String, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand(RedisString("SMEMBERS"), RedisString(key)) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }

    /// Get all the members in a set
    ///
    /// - Parameter key: The key.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain
    ///                      the elements in the set.
    ///                      NSError will be non-nil if an error occurred.
    public func smembers(_ key: RedisString, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand(RedisString("SMEMBERS"), key) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    /// Intersect multiple sets
    ///
    /// - Parameter keys: The list of the keys to intersect from.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain
    ///                      the elements of the resulting set.
    ///                      NSError will be non-nil if an error occurred.
    public func sinter(_ keys: String..., callback: ([RedisString?]?, NSError?) -> Void) {
        self.sinterArrayOfKeys(keys, callback: callback)
    }

    /// Intersect multiple sets
    ///
    /// - Parameter keys: An array of the keys to intersect from.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain
    ///                      the elements of the resulting set.
    ///                      NSError will be non-nil if an error occurred.
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
    /// - Parameter keys: The list of the keys to intersect from.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain
    ///                      the elements of the resulting set.
    ///                      NSError will be non-nil if an error occurred.
    public func sinter(_ keys: RedisString..., callback: ([RedisString?]?, NSError?) -> Void) {
        self.sinterArrayOfKeys(keys, callback: callback)
    }

    /// Intersect multiple sets
    ///
    /// - Parameter keys: An array of the keys to intersect from.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain
    ///                      the elements of the resulting set.
    ///                      NSError will be non-nil if an error occurred.
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
    /// - Parameter destination: The destination of the result.
    /// - Parameter keys: The list of the keys to intersect from.
    /// - Parameter callback: The callback function, the Int will contain
    ///                      the number of elements in the resulting set.
    ///                      NSError will be non-nil if an error occurred.
    public func sinterstore(_ destination: String, keys: String..., callback: (Int?, NSError?) -> Void) {
        self.sinterstoreArrayOfKeys(destination, keys: keys, callback: callback)
    }

    /// Intersect multiple sets and store the resulting set in a key
    ///
    /// - Parameter destination: The destination of the result.
    /// - Parameter keys: An array of the keys to intersect from.
    /// - Parameter callback: The callback function, the Int will contain
    ///                      the number of elements in the resulting set.
    ///                      NSError will be non-nil if an error occurred.
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
    /// - Parameter destination: The destination of the result.
    /// - Parameter keys: The list of the keys to intersect from.
    /// - Parameter callback: The callback function, the Int will contain
    ///                      the number of elements in the resulting set.
    ///                      NSError will be non-nil if an error occurred.
    public func sinterstore(_ destination: RedisString, keys: RedisString..., callback: (Int?, NSError?) -> Void) {
        self.sinterstoreArrayOfKeys(destination, keys: keys, callback: callback)
    }

    /// Intersect multiple sets and store the resulting set in a key
    ///
    /// - Parameter destination: The destination of the result.
    /// - Parameter keys: An array of the keys to intersect from.
    /// - Parameter callback: The callback function, the Int will contain
    ///                      the number of elements in the resulting set.
    ///                      NSError will be non-nil if an error occurred.
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
    /// - Parameter key: The key.
    /// - Parameter member: The String parameter for the member.
    /// - Parameter callback: The callback function, the Bool will contain
    ///                      true if the member is an element of the set.
    ///                      NSError will be non-nil if an error occurred.
    public func sismember(_ key: String, member: String, callback: (Bool?, NSError?) -> Void) {
        issueCommand("SISMEMBER", key, member) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }

    /// Determine if a given value is a member of a set
    ///
    /// - Parameter key: The key.
    /// - Parameter member: The `RedisString` parameter for the member.
    /// - Parameter callback: The callback function, the Bool will contain
    ///                      true if the member is an element of the set.
    ///                      NSError will be non-nil if an error occurred.
    public func sismember(_ key: RedisString, member: RedisString, callback: (Bool?, NSError?) -> Void) {
        issueCommand(RedisString("SISMEMBER"), key, member) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }

    /// Move a member from one set to another
    ///
    /// - Parameter source: The Source set from where to move the member from.
    /// - Parameter destination: The Destination set from where to move the member to.
    /// - Parameter member: The String parameter for the member to be moved.
    /// - Parameter callback: The callback function, the Bool will contain
    ///                      true if the member was moved.
    ///                      NSError will be non-nil if an error occurred.
    public func smove(source: String, destination: String, member: String, callback: (Bool?, NSError?) -> Void) {
        issueCommand("SMOVE", source, destination, member) {
            (response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }

    /// Move a member from one set to another
    ///
    /// - Parameter source: The Source set from where to move the member from.
    /// - Parameter destination: The Destination set from where to move the member to.
    /// - Parameter member: The RedisString parameter for the member to be moved.
    /// - Parameter callback: The callback function, the Bool will contain
    ///                      true if the member was moved.
    ///                      NSError will be non-nil if an error occurred.
    public func smove(source: RedisString, destination: RedisString, member: RedisString, callback: (Bool?, NSError?) -> Void) {
        issueCommand(RedisString("SMOVE"), source, destination, member) {
            (response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }

    /// Remove and return a random member from a set
    ///
    /// - Parameter key: The key.
    /// - Parameter callback: The callback function, the `RedisString` will contain
    ///                      the removed member of the set.
    ///                      NSError will be non-nil if an error occurred.
    public func spop(_ key: String, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("SPOP", key) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }

    /// Remove and return one or multiple random members from a set
    ///
    /// - Parameter key: The key.
    /// - Parameter count: The number of members to pop.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain
    ///                      the removed members of the set.
    ///                      NSError will be non-nil if an error occurred.
    public func spop(_ key: String, count: Int, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand("SPOP", key, String(count)) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }

    /// Remove and return a random member from a set
    ///
    /// - Parameter key: The key.
    /// - Parameter callback: The callback function, the `RedisString` will contain
    ///                      the removed member of the set.
    ///                      NSError will be non-nil if an error occurred.
    public func spop(_ key: RedisString, callback: (RedisString?, NSError?) -> Void) {
        issueCommand(RedisString("SPOP"), key) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }

    /// Remove and return one or multiple random members from a set
    ///
    /// - Parameter key: The key.
    /// - Parameter count: The number of members to pop.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain
    ///                      the removed members of the set.
    ///                      NSError will be non-nil if an error occurred.
    public func spop(_ key: RedisString, count: Int, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand(RedisString("SPOP"), key, RedisString(count)) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }

    /// Get a random member from a set
    ///
    /// - Parameter key: The key.
    /// - Parameter callback: The callback function, the `RedisString` will contain
    ///                      the member of the set.
    ///                      NSError will be non-nil if an error occurred.
    public func srandmember(_ key: String, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("SRANDMEMBER", key) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }

    /// Get one or multiple random members from a set
    ///
    /// - Parameter key: The key.
    /// - Parameter count: The number of members to return.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain
    ///                      the members of the set.
    ///                      NSError will be non-nil if an error occurred.
    public func srandmember(_ key: String, count: Int, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand("SRANDMEMBER", key, String(count)) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }

    /// Get a random member from a set
    ///
    /// - Parameter key: The key.
    /// - Parameter callback: The callback function, the `RedisString` will contain
    ///                      the member of the set.
    ///                      NSError will be non-nil if an error occurred.
    public func srandmember(_ key: RedisString, callback: (RedisString?, NSError?) -> Void) {
        issueCommand(RedisString("SRANDMEMBER"), key) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }

    /// Get one or multiple random members from a set
    ///
    /// - Parameter key: The key.
    /// - Parameter count: The number of members to return.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain
    ///                      the members of the set.
    ///                      NSError will be non-nil if an error occurred.
    public func srandmember(_ key: RedisString, count: Int, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand(RedisString("SRANDMEMBER"), key, RedisString(count)) {(response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    /// Remove one or more members from a set
    ///
    /// - Parameter key: The key.
    /// - Parameter members: The list of the members to be removed.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                      number of members that were removed from the set.
    ///                      NSError will be non-nil if an error occurred.
    public func srem(_ key: String, members: String..., callback: (Int?, NSError?) -> Void) {
        self.sremArrayOfMembers(key, members: members, callback: callback)
    }

    /// Remove one or more members from a set
    ///
    /// - Parameter key: The key.
    /// - Parameter members: An Array of the members to be removed.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                      number of members that were removed from the set.
    ///                      NSError will be non-nil if an error occurred.
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
    /// - Parameter key: The key.
    /// - Parameter members: The list of the members to be removed.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                      number of members that were removed from the set.
    ///                      NSError will be non-nil if an error occurred.
    public func srem(_ key: RedisString, members: RedisString..., callback: (Int?, NSError?) -> Void) {
        self.sremArrayOfMembers(key, members: members, callback: callback)
    }

    /// Remove one or more members from a set
    ///
    /// - Parameter key: The key.
    /// - Parameter members: An array of the members to be removed.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                      number of members that were removed from the set.
    ///                      NSError will be non-nil if an error occurred.
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
    /// - Parameter keys: The list of the keys to union.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain
    ///                      the members of the resulting set.
    ///                      NSError will be non-nil if an error occurred.
    public func sunion(_ keys: String..., callback: ([RedisString?]?, NSError?) -> Void) {
        self.sunionArrayOfKeys(keys, callback: callback)
    }

    /// Add multiple sets
    ///
    /// - Parameter keys: An array of the keys to union.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain
    ///                      the members of the resulting set.
    ///                      NSError will be non-nil if an error occurred.
    public func sunionArrayOfKeys(_ keys: [String], callback: ([RedisString?]?, NSError?) -> Void) {
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
    /// - Parameter keys: The list of the keys to union.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain
    ///                      the members of the resulting set.
    ///                      NSError will be non-nil if an error occurred.
    public func sunion(_ keys: RedisString..., callback: ([RedisString?]?, NSError?) -> Void) {
        self.sunionArrayOfKeys(keys, callback: callback)
    }

    /// Add multiple sets
    ///
    /// - Parameter keys: The list of the keys to union.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain
    ///                      the members of the resulting set.
    ///                      NSError will be non-nil if an error occurred.
    public func sunionArrayOfKeys(_ keys: [RedisString], callback: ([RedisString?]?, NSError?) -> Void) {
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
    /// - Parameter destination: The destination of the resulting set, if the
    ///                         destination already exists, it is overwritten.
    /// - Parameter keys: The list of the keys to union.
    /// - Parameter callback: The callback function, the Int will contain
    ///                      the number of elements in the resulting set.
    ///                      NSError will be non-nil if an error occurred.
    public func sunionstore(_ destination: String, keys: String..., callback: (Int?, NSError?) -> Void) {
        self.sunionstoreArrayOfKeys(destination, keys: keys, callback: callback)
    }

    /// Add multiple sets
    ///
    /// - Parameter destination: The destination of the resulting set, if the
    ///                         destination already exists, it is overwritten.
    /// - Parameter keys: The list of the keys to union.
    /// - Parameter callback: The callback function, the Int will contain
    ///                      the number of elements in the resulting set.
    ///                      NSError will be non-nil if an error occurred.
    public func sunionstoreArrayOfKeys(_ destination: String, keys: [String], callback: (Int?, NSError?) -> Void) {
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
    /// - Parameter destination: The destination of the resulting set, if the
    ///                         destination already exists, it is overwritten.
    /// - Parameter keys: The list of the keys to union.
    /// - Parameter callback: The callback function, the Int will contain
    ///                      the number of elements in the resulting set.
    ///                      NSError will be non-nil if an error occurred.
    public func sunionstore(_ destination: RedisString, keys: RedisString..., callback: (Int?, NSError?) -> Void) {
        self.sunionstoreArrayOfKeys(destination, keys: keys, callback: callback)
    }

    /// Add multiple sets
    ///
    /// - Parameter destination: The destination of the resulting set, if the
    ///                         destination already exists, it is overwritten.
    /// - Parameter keys: The list of the keys to union.
    /// - Parameter callback: The callback function, the Int will contain
    ///                      the number of elements in the resulting set.
    ///                      NSError will be non-nil if an error occurred.
    public func sunionstoreArrayOfKeys(_ destination: RedisString, keys: [RedisString], callback: (Int?, NSError?) -> Void) {
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
    /// - Parameter key: The key.
    /// - Parameter cursor: iterator
    /// - Parameter match: glob-style pattern
    /// - parameter count: The amount of work that should be done at every call in order
    ///                   to retrieve elements from the collection.
    /// - Parameter callback: The callback function, the `RedisString` will contain
    ///                      the cursor to use to continue the scan, the Array<RedisString>
    ///                      will contain the found elements.
    ///                      NSError will be non-nil if an error occurred.
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
    /// - Parameter key: The key.
    /// - Parameter cursor: iterator
    /// - Parameter match: glob-style pattern
    /// - parameter count: The amount of work that should be done at every call in order
    ///                   to retrieve elements from the collection.
    /// - Parameter callback: The callback function, the `RedisString` will contain
    ///                      the cursor to use to continue the scan, the Array<RedisString>
    ///                      will contain the found elements.
    ///                      NSError will be non-nil if an error occurred.
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
