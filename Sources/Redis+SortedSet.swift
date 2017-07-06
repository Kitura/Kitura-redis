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

/// Extend Redis by adding the Sorted Set operations
extension Redis {
    
    //
    //  MARK: Sorted set API functions
    //
    
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
    /// - Parameter tuples: A list of tuples containing a score and value to be added to the sorted set.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                      number of elements added to the sorted set.
    ///                      NSError will be non-nil if an error occurred.
    public func zadd(_ key: String, tuples: (Int, RedisString)..., callback: (Int?, NSError?) -> Void) {
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

    /// Add elements to a sorted set.
    ///
    /// - Parameter key: The key.
    /// - Parameter tuples: An array of tuples containing a score and value to be added to the sorted set.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                      number of elements added to the sorted set.
    ///                      NSError will be non-nil if an error occurred.
    public func zaddArrayOfScoreMembers(_ key: String, tuples: [(Int, RedisString)], callback: (Int?, NSError?) -> Void) {
        var command = [RedisString("ZADD")]
        command.append(RedisString(key))
        for tuple in tuples {
            command.append(RedisString(tuple.0))
            command.append(tuple.1)
        }
        issueCommandInArray(command) { (response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    /// Get the sorted set's cardinality (number of elements).
    ///
    /// - Parameter key: The key.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                      number of elements in the sorted set.
    ///                      NSError will be non-nil if an error occurred.
    public func zcard(_ key: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("ZCARD", key) { (response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    /// Count the members in a sorted set with scores within the given values.
    ///
    /// - Parameter key: The key.
    /// - Parameter min: The minimum score to count from the set.
    /// - Parameter max: The maximum score to count from the set.
    /// - Parameter callback: The callback function, the Int will contain the number of elements
    ///                       in the specified score range.
    ///                       NSError will be non-nil if an error occurred.
    public func zcount(_ key: String, min: String, max: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("ZCOUNT", key, min, max) { (response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    /// Count the members in a sorted set with scores within the given values.
    ///
    /// - Parameter key: The key.
    /// - Parameter min: The minimum score to count from the set.
    /// - Parameter max: The maximum score to count from the set.
    /// - Parameter callback: The callback function, the Int will contain the number of elements
    ///                       in the specified score range.
    ///                       NSError will be non-nil if an error occurred.
    public func zcount(_ key: RedisString, min: RedisString, max: RedisString, callback: (Int?, NSError?) -> Void) {
        issueCommand(RedisString("ZCOUNT"), key, min, max) { (response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    /// Increment the score of a member in a sorted set.
    ///
    /// - Parameter key: The key.
    /// - Parameter increment: The amount to increment the member by.
    /// - Parameter member: The member to increment.
    /// - Parameter callback: The callback function, the String will contain
    ///                       the new score of member.
    ///                       NSError will be non-nil if an error occurred.
    public func zincrby(_ key: String, increment: Int, member: String, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("ZINCRBY", key, String(increment), member) { (response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }

    /// Increment the score of a member in a sorted set.
    ///
    /// - Parameter key: The key.
    /// - Parameter increment: The amount to increment the member by.
    /// - Parameter member: The member to increment.
    /// - Parameter callback: The callback function, the String will contain
    ///                       the new score of member.
    ///                       NSError will be non-nil if an error occurred.
    public func zincrby(_ key: String, increment: Int, member: RedisString, callback: (RedisString?, NSError?) -> Void) {
        issueCommand(RedisString("ZINCRBY"), RedisString(key), RedisString(increment), member) { (response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }

    /// Intersect multiple sorted sets and store the resulting sorted set in a new key.
    ///
    /// - Parameter destination: The stored set where the results will be saved to.
    ///                          If destination exists, it will be overwritten.
    /// - Parameter numkeys: The number of keys to be sorted.
    /// - Parameter keys: The keys to be intersected.
    /// - Parameter weights: A multiplication factor for each input sorted set.
    /// - Parameter aggregate: Specify how the results of the union are aggregated.
    /// - Parameter callback: The callback function, the Int will contain the number of elements
    ///                       in the resulting sorted set at destination.
    ///                       NSError will be non-nil if an error occurred.
    public func zinterstore(_ destination: String, numkeys: Int, keys: String..., weights: [Int] = [], aggregate: String = "", callback: (Int?, NSError?) -> Void) {
        zinterstoreInArray(destination, numkeys: numkeys, keys: keys, weights: weights, aggregate: aggregate, callback: callback)
    }

    /// Intersect multiple sorted sets and store the resulting sorted set in a new key.
    ///
    /// - Parameter destination: The stored set where the results will be saved to.
    ///                          If destination exists, it will be overwritten.
    /// - Parameter numkeys: The number of keys to be sorted.
    /// - Parameter keys: The keys to be intersected.
    /// - Parameter weights: A multiplication factor for each input sorted set.
    /// - Parameter aggregate: Specify how the results of the union are aggregated.
    /// - Parameter callback: The callback function, the Int will contain the number of elements
    ///                       in the resulting sorted set at destination.
    ///                       NSError will be non-nil if an error occurred.
    public func zinterstoreInArray(_ destination: String, numkeys: Int, keys: [String], weights: [Int], aggregate: String, callback: (Int?, NSError?) -> Void) {
        let command = appendValues(operation: "ZINTERSTORE", destination, numkeys: numkeys, keys: keys, weights: weights, aggregate: aggregate)
        issueCommandInArray(command) { (response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    /// Intersect multiple sorted sets and store the resulting sorted set in a new key.
    ///
    /// - Parameter destination: The stored set where the results will be saved to.
    ///                          If destination exists, it will be overwritten.
    /// - Parameter numkeys: The number of keys to be sorted.
    /// - Parameter keys: The keys to be intersected.
    /// - Parameter weights: A multiplication factor for each input sorted set.
    /// - Parameter aggregate: Specify how the results of the union are aggregated.
    /// - Parameter callback: The callback function, the Int will contain the number of elements
    ///                       in the resulting sorted set at destination.
    ///                       NSError will be non-nil if an error occurred.
    public func zinterstore(_ destination: String, numkeys: Int, keys: RedisString..., weights: [Int] = [], aggregate: RedisString = RedisString(""), callback: (Int?, NSError?) -> Void) {
        zinterstoreInArray(destination, numkeys: numkeys, keys: keys, weights: weights, aggregate: aggregate, callback: callback)
    }

    /// Intersect multiple sorted sets and store the resulting sorted set in a new key.
    ///
    /// - Parameter destination: The stored set where the results will be saved to.
    ///                          If destination exists, it will be overwritten.
    /// - Parameter numkeys: The number of keys to be sorted.
    /// - Parameter keys: The keys to be intersected.
    /// - Parameter weights: A multiplication factor for each input sorted set.
    /// - Parameter aggregate: Specify how the results of the union are aggregated.
    /// - Parameter callback: The callback function, the Int will contain the number of elements
    ///                       in the resulting sorted set at destination.
    ///                       NSError will be non-nil if an error occurred.
    public func zinterstoreInArray(_ destination: String, numkeys: Int, keys: [RedisString], weights: [Int], aggregate: RedisString, callback: (Int?, NSError?) -> Void) {
        let command = appendValues(operation: "ZINTERSTORE", destination, numkeys: numkeys, keys: keys, weights: weights, aggregate: aggregate)
        issueCommandInArray(command) { (response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    /// Count the number of members in a sorted set between a given lexicographical range.
    ///
    /// - Parameter key: The key.
    /// - Parameter min: The minimum score to count from the set.
    /// - Parameter max: The maximum score to count from the set.
    /// - Parameter callback: The callback function, the Int will contain the number of elements
    ///                       in the specified score range.
    ///                       NSError will be non-nil if an error occurred.
    public func zlexcount(_ key: String, min: String, max: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("ZLEXCOUNT", key, min, max) { (response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    /// Get the specified range of elements in a sorted set.
    ///
    /// - Parameter key: The key.
    /// - Parameter start: The starting index of the elements of the sorted set to fetch.
    /// - Parameter stop:  The ending index of the elements of the sorted set to fetch.
    /// - Parameter callback: The callback function, the Array<RedisString> will contain the
    ///                       elements fetched from the sorted set.
    ///                       NSError will be non-nil if an error occurred.
    public func zrange(_ key: String, start: Int, stop: Int, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand("ZRANGE", key, String(start), String(stop)) { (response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }

    /// Return a range of members in a sorted set, by lexicographical range.
    ///
    /// - Parameter key: The key.
    /// - Parameter min: The minimum score to return from the set.
    /// - Parameter max: The maximum score to return from the set.
    /// - Parameter callback: The callback function, the Array will contain the list of elements
    ///                       in the specified score range.
    ///                       NSError will be non-nil if an error occurred.
    public func zrangebylex(_ key: String, min: String, max: String, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand("ZRANGEBYLEX", key, min, max) { (response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }

    /// Return a range of members in a sorted set, by score.
    ///
    /// - Parameter key: The key.
    /// - Parameter min: The minimum score to return from the set.
    /// - Parameter max: The maximum score to return from the set.
    /// - Parameter callback: The callback function, list of elements in the specified score range
    ///                       (optionally their scores)
    ///                       NSError will be non-nil if an error occurred.
    public func zrangebyscore(_ key: String, min: String, max: String, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand("ZRANGEBYSCORE", min, max) { (response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }

    /// Determine the index of a member in a sorted set.
    ///
    /// - Parameter key: The key.
    /// - Parameter member: The member to get the rank of.
    /// - Parameter callback: The callback function, the Int will conatain the rank of the member,
    ///                       If member or key does not exist returns nil.
    ///                       NSError will be non-nil if an error occurred.
    public func zrank(_ key: String, member: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("ZRANK", key, member) { (response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    /// Determine the index of a member in a sorted set.
    ///
    /// - Parameter key: The key.
    /// - Parameter member: The member to get the rank of.
    /// - Parameter callback: The callback function, the Int will conatain the rank of the member,
    ///                       If member or key does not exist returns nil.
    ///                       NSError will be non-nil if an error occurred.
    public func zrank(_ key: String, member: RedisString, callback: (Int?, NSError?) -> Void) {
        issueCommand(RedisString("ZRANK"), RedisString(key), member) { (response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    /// Removes the specified members from the sorted set stored at key. Non existing members are ignored.
    /// An error is returned when key exists and does not hold a sorted set.
    ///
    /// - Parameter key: The key.
    /// - Parameter members: The list of the member(s) to remove.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                       number of elements removed from the sorted set.
    ///                       NSError will be non-nil if an error occurred.
    public func zrem(_ key: String, members: String..., callback: (Int?, NSError?) -> Void) {
        zremArrayOfMembers(key, members: members, callback: callback)
    }

    /// Removes the specified members from the sorted set stored at key. Non existing members are ignored.
    /// An error is returned when key exists and does not hold a sorted set.
    ///
    /// - Parameter key: The key.
    /// - Parameter members: An array of the member(s) to remove.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                       number of elements removed from the sorted set.
    ///                       NSError will be non-nil if an error occurred.
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

    /// Remove all members in a sorted set between the given lexicographical range.
    ///
    /// - Parameter key: The key.
    /// - Parameter min: The minimum score to remove from the set.
    /// - Parameter max: The maximum score to remove from the set.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                       number of elements removed from the sorted set.
    ///                       NSError will be non-nil if an error occurred.
    public func zremrangebylex(_ key: String, min: String, max: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("ZREMRANGEBYLEX", key, min, max) { (response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    /// Remove all members in a sorted set within the given indexes.
    ///
    /// - Parameter key: The key.
    /// - Parameter start: The starting index to remove from the set.
    /// - Parameter stop: The ending index to remove from the set.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                       number of elements removed from the sorted set.
    ///                       NSError will be non-nil if an error occurred.
    public func zremrangebyrank(_ key: String, start: Int, stop: Int, callback: (Int?, NSError?) -> Void) {
        issueCommand("ZREMRANGEBYRANK", key, String(start), String(stop)) { (response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }


    /// Removes all elements in the sorted set stored at key with a score between a minimum and a maximum (inclusive).
    ///
    /// - Parameter key: The key.
    /// - Parameter min: The minimum score to remove from the set.
    /// - Parameter max: The maximum score to remove from the set.
    /// - Parameter callback: The callback function, the Int will contain the
    ///                       number of elements removed from the sorted set.
    ///                       NSError will be non-nil if an error occurred.
    public func zremrangebyscore(_ key: String, min: String, max: String, callback: (_ nElements: Int?, _ error: NSError?) -> Void) {
        issueCommand("ZREMRANGEBYSCORE", key, min, max) { (response) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    /// Return a range of members in a sorted set, by index, with scores ordered from high to low
    ///
    /// - Parameter key: The key.
    /// - Parameter start: The starting index to return from the set.
    /// - Parameter stop: The stoping index to return from the set.
    /// - Parameter withscores: Whether or not to return scores as well.
    /// - Parameter callback: The callback function, the Array will conatian the list of elements
    ///                       in the specified range (optionally with their scores).
    ///                       NSError will be non-nil if an error occurred.
    public func zrevrange(_ key: String, start: Int, stop: Int, withscores: Bool = false, callback: ([RedisString?]?, NSError?) -> Void) {
        if !withscores {
            issueCommand("ZREVRANGE", key, String(start), String(stop)) { (response: RedisResponse) in
                self.redisStringArrayResponseHandler(response, callback: callback)
            }
        } else {
            issueCommand("ZREVRANGE", key, String(start), String(stop), "WITHSCORES") { (response: RedisResponse) in
                self.redisStringArrayResponseHandler(response, callback: callback)
            }
        }
    }

    /// Return a range of members in a sorted set, by lexicographical range,
    /// ordered from higher to lower strings.
    ///
    /// - Parameter key: The key.
    /// - Parameter min: The minimum score to return from the set.
    /// - Parameter max: The maximum score to return from the set.
    /// - Parameter callback: The callback function, the Array will conatian the list of elements
    ///                       in the specified lexicographical range.
    ///                       NSError will be non-nil if an error occurred.
    public func zrevrangebylex(_ key: String, min: String, max: String, callback: ([RedisString?]?, NSError?) -> Void) {
        issueCommand("ZREVRANGEBYLEX", key, min, max) { (response: RedisResponse) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }


    /// Return a range of members in a sorted set, by score, with scores ordered from high to low.
    ///
    /// - Parameter key:        The key.
    /// - Parameter max:        The minimum score to return from the set.
    /// - Parameter min:        The maximum score to return from the set.
    /// - Parameter withscores: The bool whether to return the scores as well
    /// - Parameter callback: The callback function, the Array will conatian the list of elements
    ///                       in the specified score range (optionally with their scores)
    ///                       NSError will be non-nil if an error occurred.
    public func zrevrangebyscore(_ key: String, min: String, max: String, withscores: Bool = false, callback: ([RedisString?]?, NSError?) -> Void) {
        if !withscores {
            issueCommand("ZREVRANGEBYSCORE", key, max, min) { (response: RedisResponse) in
                self.redisStringArrayResponseHandler(response, callback: callback)
            }
        } else {
            issueCommand("ZREVRANGEBYSCORE", key, max, min, "WITHSCORES") { (response: RedisResponse) in
                self.redisStringArrayResponseHandler(response, callback: callback)
            }
        }
    }

    /// Determine the index of a member in a sorted set, with scores ordered from high to low.
    ///
    /// - Parameter key: The key.
    /// - Parameter member: The member to get the rank of.
    /// - Parameter callback: The callback function, the Int will contain the rank of the member
    ///                       when the set is in reverse order.
    ///                       If member does not exist in the sorted set or key does not exist
    ///                       returns nil.
    ///                       NSError will be non-nil if an error occurred.
    public func zrevrank(_ key: String, member: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("ZREVRANK", key, member) { (response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    /// Incrementally iterate sorted sets elements and associated scores.
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
    public func zscan(_ key: String, cursor: Int, match: String? = nil, count: Int? = nil,
                      callback: (RedisString?, [RedisString?]?, NSError?) -> Void) {
        let ZSCAN = "ZSCAN"
        let MATCH = "MATCH"
        let COUNT = "COUNT"

        if let match = match, let count = count {
            issueCommand(ZSCAN, key, String(cursor), MATCH, match, COUNT, String(count)) {(response: RedisResponse) in
                self.redisScanResponseHandler(response, callback: callback)
            }
        } else if let match = match {
            issueCommand(ZSCAN, key, String(cursor), MATCH, match) {(response: RedisResponse) in
                self.redisScanResponseHandler(response, callback: callback)
            }
        } else if let count = count {
            issueCommand(ZSCAN, key, String(cursor), COUNT, String(count)) {(response: RedisResponse) in
                self.redisScanResponseHandler(response, callback: callback)
            }
        } else {
            issueCommand(ZSCAN, key, String(cursor)) {(response: RedisResponse) in
                self.redisScanResponseHandler(response, callback: callback)
            }
        }
    }

    /// Incrementally iterate sorted sets elements and associated scores.
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
    public func zscan(_ key: RedisString, cursor: Int, match: RedisString? = nil, count: Int? = nil,
                      callback: (RedisString?, [RedisString?]?, NSError?) -> Void) {
        let ZSCAN = RedisString("ZSCAN")
        let MATCH = RedisString("MATCH")
        let COUNT = RedisString("COUNT")

        if let match = match, let count = count {
            issueCommand(ZSCAN, key, RedisString(cursor), MATCH, match, COUNT, RedisString(count)) {(response: RedisResponse) in
                self.redisScanResponseHandler(response, callback: callback)
            }
        } else if let match = match {
            issueCommand(ZSCAN, key, RedisString(cursor), MATCH, match) {(response: RedisResponse) in
                self.redisScanResponseHandler(response, callback: callback)
            }
        } else if let count = count {
            issueCommand(ZSCAN, key, RedisString(cursor), COUNT, RedisString(count)) {(response: RedisResponse) in
                self.redisScanResponseHandler(response, callback: callback)
            }
        } else {
            issueCommand(ZSCAN, key, RedisString(cursor)) {(response: RedisResponse) in
                self.redisScanResponseHandler(response, callback: callback)
            }
        }
    }

    /// Get the score associated with the given member in a sorted set.
    ///
    /// - Parameter key: The key.
    /// - Parameter member: The member to get the score from.
    /// - Parameter callback: The callback function, the RedisString will contain
    ///                       the score of member.
    ///                      NSError will be non-nil if an error occurred.
    public func zscore(_ key: String, member: String, callback: (RedisString?, NSError?) -> Void) {
        issueCommand("ZSCORE", key, member) { (response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }

    /// Get the score associated with the given member in a sorted set.
    ///
    /// - Parameter key: The key.
    /// - Parameter member: The member to get the score from.
    /// - Parameter callback: The callback function, the RedisString will contain
    ///                       the score of member.
    ///                      NSError will be non-nil if an error occurred.
    public func zscore(_ key: String, member: RedisString, callback: (RedisString?, NSError?) -> Void) {
        issueCommand(RedisString("ZSCORE"), RedisString(key), member) { (response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }

    /// Add multiple sorted sets and store the resulting sorted set in a new key
    ///
    /// - Parameter destination: The destination where the result will be stored.
    /// - Parameter numkeys: The number of keys to union.
    /// - Parameter keys: The keys.
    /// - Parameter weights: A multiplication factor for each input sorted set.
    /// - Parameter aggregate: Specify how the results of the union are aggregated.
    /// - Parameter callback: The callback function, the Int will contain the number of elements
    ///                       in the resulting sorted set at destination.
    ///                       NSError will be non-nil if an error occured.
    public func zunionstore(_ destination: String, numkeys: Int, keys: String..., weights: [Int] = [], aggregate: String = "", callback: (Int?, NSError?) -> Void) {
        zunionstoreWithArray(destination, numkeys: numkeys, keys: keys, weights: weights, aggregate: aggregate, callback: callback)
    }

    /// Add multiple sorted sets and store the resulting sorted set in a new key
    ///
    /// - Parameter destination: The destination where the result will be stored.
    /// - Parameter numkeys: The number of keys to union.
    /// - Parameter keys: The keys.
    /// - Parameter weights: A multiplication factor for each input sorted set.
    /// - Parameter aggregate: Specify how the results of the union are aggregated.
    /// - Parameter callback: The callback function, the Int will contain the number of elements
    ///                       in the resulting sorted set at destination.
    ///                       NSError will be non-nil if an error occured.
    public func zunionstoreWithArray(_ destination: String, numkeys: Int, keys: [String], weights: [Int], aggregate: String, callback: (Int?, NSError?) -> Void) {
        let command = appendValues(operation: "ZUNIONSTORE", destination, numkeys: numkeys, keys: keys, weights: weights, aggregate: aggregate)

        issueCommandInArray(command) { (response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    /// Add multiple sorted sets and store the resulting sorted set in a new key
    ///
    /// - Parameter destination: The destination where the result will be stored.
    /// - Parameter numkeys: The number of keys to union.
    /// - Parameter keys: The keys.
    /// - Parameter weights: A multiplication factor for each input sorted set.
    /// - Parameter aggregate: Specify how the results of the union are aggregated.
    /// - Parameter callback: The callback function, the Int will contain the number of elements
    ///                       in the resulting sorted set at destination.
    ///                       NSError will be non-nil if an error occured.
    public func zunionstore(_ destination: String, numkeys: Int, keys: RedisString..., weights: [Int] = [], aggregate: RedisString = RedisString(""), callback: (Int?, NSError?) -> Void) {
        zunionstoreWithArray(destination, numkeys: numkeys, keys: keys, weights: weights, aggregate: aggregate, callback: callback)
    }

    /// Add multiple sorted sets and store the resulting sorted set in a new key
    ///
    /// - Parameter destination: The destination where the result will be stored.
    /// - Parameter numkeys: The number of keys to union.
    /// - Parameter keys: The keys.
    /// - Parameter weights: A multiplication factor for each input sorted set.
    /// - Parameter aggregate: Specify how the results of the union are aggregated.
    /// - Parameter callback: The callback function, the Int will contain the number of elements
    ///                       in the resulting sorted set at destination.
    ///                       NSError will be non-nil if an error occured.
    public func zunionstoreWithArray(_ destination: String, numkeys: Int, keys: [RedisString], weights: [Int], aggregate: RedisString, callback: (Int?, NSError?) -> Void) {
        let command = appendValues(operation: "ZUNIONSTORE", destination, numkeys: numkeys, keys: keys, weights: weights, aggregate: aggregate)

        issueCommandInArray(command) { (response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }

    //Appends all the values into a String array ready to be used for issueCommandInArray()
    private func appendValues(operation: String, _ destination: String, numkeys: Int, keys: [String], weights: [Int], aggregate: String) -> [String] {
        var command = [operation]
        command.append(destination)
        command.append(String(numkeys))
        for key in keys {
            command.append(key)
        }
        if weights.count > 0 {
            command.append("WEIGHTS")
            for weight in weights {
                command.append(String(weight))
            }
        }
        if aggregate != "" {
            command.append("AGGREGATE")
            command.append(aggregate)
        }
        return command
    }

    //Appends all the values into a RedisString array ready to be used for issueCommandInArray()
    private func appendValues(operation: String, _ destination: String, numkeys: Int, keys: [RedisString], weights: [Int], aggregate: RedisString) -> [RedisString] {
        var command = [RedisString(operation)]
        command.append(RedisString(destination))
        command.append(RedisString(numkeys))
        for key in keys {
            command.append(key)
        }
        if weights.count > 0 {
            command.append(RedisString("WEIGHTS"))
            for weight in weights {
                command.append(RedisString(weight))
            }
        }
        if aggregate != RedisString("") {
            command.append(RedisString("AGGREGATE"))
            command.append(aggregate)
        }
        return command
    }
}
