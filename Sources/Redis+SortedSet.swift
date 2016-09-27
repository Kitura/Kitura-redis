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
    
    /// Return the number of elements added to the sorted sets, not including elements already existing for which the score was
    /// updated.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter tuples: a tuple variadic parameter containing a score(s) and member(s)
    /// - Parameter callback: a function returning the number of elements added to the sorted sets
    public func zadd(_ key: String, tuples: (Int,String)..., callback: (Int?, NSError?) -> Void) {
        zaddArrayOfScoreMembers(key, tuples: tuples, callback: callback)
    }
    
    /// Return the number of elements added to the sorted sets, not including elements already existing for which the score was
    /// updated.
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
    
    /// Returns the sorted set cardinality (number of elements) of the sorted set stored at key.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter callback: a function returning the sorted set cardinality of the sorted set
    public func zcard(_ key: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("ZCARD", key) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Returns the specified range of elements in the sorted set stored at key
    ///
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter start: the start of index of the set
    /// - Parameter stop:  the end of the index of the set
    /// - Parameter callback: a function returning the array of specified range of elements in the sorted set
    public func zrange(_ key: String, start: Int, stop: Int, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand("ZRANGE", key, String(start), String(stop)) { (response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    /// Removes the specified members from the sorted set stored at key. Non existing members are ignored.
    /// An error is returned when key exists and does not hold a sorted set.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter members: a  variadic parameter containing the member(s)
    /// - Parameter callback: a function returning the number of members removed from the sorted set
    public func zrem(_ key: String, members: String..., callback: (Int?, NSError?) -> Void) {
        zremArrayOfMembers(key, members: members, callback: callback)
    }
    
    /// Removes the specified members from the sorted set stored at key. Non existing members are ignored.
    /// An error is returned when key exists and does not hold a sorted set.
    ///
    /// - Parameter key: the String parameter for the key
    /// - Parameter members: a  variadic parameter containing the member(s)
    /// - Parameter callback: a function returning the number of members removed from the sorted set
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
    
    /// Removes all elements in the sorted set stored at key with a score between min and max (inclusive).
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
}
