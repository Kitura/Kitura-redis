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

/// Extend Redis by adding the Sorted Set operations
extension Redis {
    
    /// Add elements to a sorted set.
    ///
    /// - Parameter key: The key.
    /// - Parameter tuples: A list of tuples containing a score and value to be added to the sorted set.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                      number of elements added to the sorted set.
    ///                      NSError will be non-nil if an error occurred.
    public func zadd(_ key: String, tuples: (Int, String)..., callback: (Int?, NSError?) -> Void) {
        zaddArrayOfScoreMembers(key, tuples: tuples, callback: callback)
    }
    
    /// Add elements to a sorted set.
    ///
    /// - Parameter key: The key.
    /// - Parameter tuples: An array of tuples containing a score and value to be added to the sorted set.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                      number of elements added to the sorted set.
    ///                      NSError will be non-nil if an error occurred.
    public func zaddArrayOfScoreMembers(_ key: String, tuples: [(Int, String)], callback: (Int?, NSError?) -> Void) {
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
    
    /// Get the sorted set's cardinality (number of elements).
    ///
    /// - Parameter key: The key.
    /// - Parameter callback: a function returning the sorted set cardinality of the sorted set.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                      number of elements in the sorted set.
    ///                      NSError will be non-nil if an error occurred.
    public func zcard(_ key: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("ZCARD", key) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Get the specified range of elements in a sorted set
    ///
    /// - Parameter key: The key.
    /// - Parameter start: The starting index of the elements of the sorted set to fetch.
    /// - Parameter stop:  The ending index of the elements of the sorted set to fetch.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain the
    ///                      elements fetched from the sorted set.
    ///                      NSError will be non-nil if an error occurred.
    public func zrange(_ key: String, start: Int, stop: Int, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand("ZRANGE", key, String(start), String(stop)) { (response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    /// Removes the specified members from the sorted set stored at key. Non existing members are ignored.
    /// An error is returned when key exists and does not hold a sorted set.
    ///
    /// - Parameter key: The key.
    /// - Parameter members: The list of the member(s) to remove.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                      number of elements removed from the sorted set.
    ///                      NSError will be non-nil if an error occurred.
    public func zrem(_ key: String, members: String..., callback: (Int?, NSError?) -> Void) {
        zremArrayOfMembers(key, members: members, callback: callback)
    }
    
    /// Removes the specified members from the sorted set stored at key. Non existing members are ignored.
    /// An error is returned when key exists and does not hold a sorted set.
    ///
    /// - Parameter key: The key.
    /// - Parameter members: An array of the member(s) to remove.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                      number of elements removed from the sorted set.
    ///                      NSError will be non-nil if an error occurred.
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
    
    /// Removes all elements in the sorted set stored at key with a score between a minimum and a maximum (inclusive).
    ///
    /// - Parameter key: The key.
    /// - Parameter min: The minimum score to remove from the set.
    /// - Parameter max: The maximum score to remove from the set.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                      number of elements removed from the sorted set.
    ///                      NSError will be non-nil if an error occurred.
    public func zremrangebyscore(_ key: String, min: String, max: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("ZREMRANGEBYSCORE",key, min, max) { (response) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
}
