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

/// Extend RedisMulti by adding the Sorted Set operations
extension RedisMulti {
    
    /// Add an ZADD command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter tuples: A list of tuples containing a score and value to be added to the sorted set.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zadd(_ key: String, tuples: (Int, String)...) -> RedisMulti {
        return zaddArrayOfScoreMembers(key, tuples: tuples)
    }
    
    /// Add an ZADD command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter tuples: A list of tuples containing a score and value to be added to the sorted set.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zaddArrayOfScoreMembers(_ key: String, tuples: [(Int, String)]) -> RedisMulti {
        var command = [RedisString("ZADD"), RedisString(key)]
        for tuple in tuples {
            command.append(RedisString(tuple.0))
            command.append(RedisString(tuple.1))
        }
        queuedCommands.append(command)
        return self
    }
    
    /// Add an ZADD command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter tuples: A list of tuples containing a score and value to be added to the sorted set.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zadd(_ key: String, tuples: (Int, RedisString)...) -> RedisMulti {
        return zaddArrayOfScoreMembers(key, tuples: tuples)
    }
    
    /// Add an ZADD command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter tuples: A list of tuples containing a score and value to be added to the sorted set.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zaddArrayOfScoreMembers(_ key: String, tuples: [(Int, RedisString)]) -> RedisMulti {
        var command = [RedisString("ZADD"), RedisString(key)]
        for tuple in tuples {
            command.append(RedisString(tuple.0))
            command.append(tuple.1)
        }
        queuedCommands.append(command)
        return self
    }
    
    /// Add an ZCARD command to the "transactions"
    ///
    /// - Parameter key: The key.
    @discardableResult
    public func zcard(_ key: String) -> RedisMulti {
        queuedCommands.append([RedisString("ZCARD"), RedisString(key)])
        return self
    }
    
    /// Add an ZCOUNT command to the "transactions"
    ///
    /// - Parameter key: The key.
    /// - Parameter min: The minimum score to count from the set.
    /// - Parameter max: The maximum score to count from the set.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zcount(_ key: String, min: String, max: String) -> RedisMulti {
        queuedCommands.append([RedisString("ZCOUNT"), RedisString(key), RedisString(min), RedisString(max)])
        return self
    }
    
    /// Add an ZINCRBY command to the "transactions"
    ///
    /// - Parameter key: The key.
    /// - Parameter increment: The amount to increment the member by.
    /// - Parameter member: The member to increment.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zincrby(_ key: String, increment: Int, member: String) -> RedisMulti {
        queuedCommands.append([RedisString("ZINCRBY"), RedisString(key), RedisString(increment), RedisString(member)])
        return self
    }
    
    /// Add an ZINCRBY command to the "transactions"
    ///
    /// - Parameter key: The key.
    /// - Parameter increment: The amount to increment the member by.
    /// - Parameter member: The member to increment.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zincrby(_ key: String, increment: Int, member: RedisString) -> RedisMulti {
        queuedCommands.append([RedisString("ZINCRBY"), RedisString(key), RedisString(increment), member])
        return self
    }
    
    /// Add an ZINTERSTORE command to the "transactions"
    ///
    /// - Parameter key: The key.
    /// - Parameter increment: The amount to increment the member by.
    /// - Parameter member: The member to increment.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zinterstore(_ destination: String, numkeys: Int, keys: String..., weights: [Int] = [], aggregate: String = "") -> RedisMulti {
        var command = [RedisString("ZINTERSTORE"), RedisString(destination), RedisString(numkeys)]
        for key in keys {
            command.append(RedisString(key))
        }
        if weights.count > 0 {
            command.append(RedisString("WEIGHTS"))
            for weight in weights {
                command.append(RedisString(weight))
            }
        }
        if aggregate != "" {
            command.append(RedisString("AGGREGATE"))
            command.append(RedisString(aggregate))
        }
        queuedCommands.append(command)
        return self
    }
    
    /// Add an ZLEXCOUNT command to the "transactions"
    ///
    /// - Parameter key: The key.
    /// - Parameter min: The minimum score to count from the set.
    /// - Parameter max: The maximum score to count from the set.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zlexcount(_ key: String, min: String, max: String) -> RedisMulti {
        queuedCommands.append([RedisString("ZLEXCOUNT"), RedisString(key), RedisString(min), RedisString(max)])
        return self
    }
    
    /// Add an ZRANGE command to the "transactions"
    /// - Parameter key: The key.
    /// - Parameter increment: The amount to increment the member by.
    /// - Parameter member: The member to increment.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zrange(_ key: String, start: Int, stop: Int) -> RedisMulti {
        queuedCommands.append([RedisString("ZRANGE"), RedisString(key), RedisString(start), RedisString(stop)])
        return self
    }
    
    /// Add an ZRANGEBYLEX command to the "transactions"
    ///
    /// - Parameter key: The key.
    /// - Parameter min: The minimum score to count from the set.
    /// - Parameter max: The maximum score to count from the set.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zrangebylex(_ key: String, min: String, max: String) -> RedisMulti {
        queuedCommands.append([RedisString("ZRANGEBYLEX"), RedisString(key), RedisString(min), RedisString(max)])
        return self
    }
    
    /// Add an ZRANGEBYSCORE command to the "transactions"
    ///
    /// - Parameter key: The key.
    /// - Parameter min: The minimum score to count from the set.
    /// - Parameter max: The maximum score to count from the set.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zrangebyscore(_ key: String, min: String, max: String) -> RedisMulti {
        queuedCommands.append([RedisString("ZRANGEBYSCORE"), RedisString(key), RedisString(min), RedisString(max)])
        return self
    }
    
    /// Add an ZRANK command to the "transactions"
    ///
    /// - Parameter key: The key.
    /// - Parameter member: The member to get the rank of.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zrank(_ key: String, member: String) -> RedisMulti {
        queuedCommands.append([RedisString("ZRANK"), RedisString(key), RedisString(member)])
        return self
    }
    
    /// Add an ZREM command to the "transactions"
    ///
    /// - Parameter key: The key.
    /// - Parameter members: The list of the member(s) to remove.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zrem(_ key: String, members: String...) -> RedisMulti {
        return zremArrayOfMembers(key, members: members)
    }
    
    /// Add an ZREM command to the "transactions"
    ///
    /// - Parameter key: The key.
    /// - Parameter members: The list of the member(s) to remove.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zremArrayOfMembers(_ key: String, members: [String]) -> RedisMulti {
        var command = [RedisString("ZREM"), RedisString(key)]
        for member in members {
            command.append(RedisString(member))
        }
        queuedCommands.append(command)
        return self
    }
    
    /// Add an ZREMRANGEBYLEX command to the "transactions"
    ///
    /// - Parameter key: The key.
    /// - Parameter min: The minimum score to remove from the set.
    /// - Parameter max: The maximum score to remove from the set.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zremrangebylex(_ key: String, min: String, max: String) -> RedisMulti {
        queuedCommands.append([RedisString("ZREMRANGEBYLEX"), RedisString(key), RedisString(min), RedisString(max)])
        return self
    }
    
    /// Add an ZREMRANGEBYRANK command to the "transactions"
    ///
    /// - Parameter key: The key.
    /// - Parameter start: The starting index to remove from the set.
    /// - Parameter stop: The ending index to remove from the set.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zremrangebyrank(_ key: String, start: Int, stop: Int) -> RedisMulti {
        queuedCommands.append([RedisString("ZREMRANGEBYRANK"), RedisString(key), RedisString(start), RedisString(stop)])
        return self
    }

    /// Add an ZREMRANGEBYSCORE command to the "transactions"
    ///
    /// - Parameter key: The key.
    /// - Parameter min: The minimum score to remove from the set.
    /// - Parameter max: The maximum score to remove from the set.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zremrangebyscore(_ key: String, min: String, max: String) -> RedisMulti {
        queuedCommands.append([RedisString("ZREMRANGEBYSCORE"), RedisString(key), RedisString(min), RedisString(max)])
        return self
    }
    
    /// Add an ZREVRANGE command to the "transactions"
    ///
    /// - Parameter key: The key.
    /// - Parameter start: The starting index to return from the set.
    /// - Parameter stop: The stoping index to return from the set.
    /// - Parameter withscores: Whether or not to return scores as well.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zrevrange(_ key: String, start: Int, stop: Int, withscores: Bool = false) -> RedisMulti {
        if !withscores {
            queuedCommands.append([RedisString("ZREVRANGE"), RedisString(key), RedisString(start), RedisString(stop)])
        } else {
            queuedCommands.append([RedisString("ZREVRANGE"), RedisString(key), RedisString(start), RedisString(stop), RedisString("WITHSCORES")])
        }
        return self
    }

    /// Add an ZREVRANGEBYLEX command to the "transactions"
    ///
    /// - Parameter key: The key.
    /// - Parameter min: The minimum score to remove from the set.
    /// - Parameter max: The maximum score to remove from the set.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zrevrangebylex(_ key: String, min: String, max: String) -> RedisMulti {
        queuedCommands.append([RedisString("ZREVRANGEBYLEX"), RedisString(key), RedisString(min), RedisString(max)])
        return self
    }
    
    /// Add an ZREVRANGEBYSCORE command to the "transactions"
    ///
    /// - Parameter key: The key.
    /// - Parameter min: The minimum score to remove from the set.
    /// - Parameter max: The maximum score to remove from the set.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zrevrangebyscore(_ key: String, min: String, max: String, withscore: Bool = false) -> RedisMulti {
        if !withscore {
            queuedCommands.append([RedisString("ZREVRANGEBYSCORE"), RedisString(key), RedisString(min), RedisString(max)])
        } else {
            queuedCommands.append([RedisString("ZREVRANGEBYSCORE"), RedisString(key), RedisString(min), RedisString(max), RedisString("WITHSCORES")])
        }
        return self
    }
    
    /// Add an ZREVRANK command to the "transactions"
    ///
    /// - Parameter key: The key.
    /// - Parameter member: The member to get the rank of.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zrevrank(_ key: String, member: String) -> RedisMulti {
        queuedCommands.append([RedisString("ZREVRANK"), RedisString(key), RedisString(member)])
        return self
    }
    
    /// Add an ZSCAN command to the "transactions"
    ///
    /// - Parameter key: The key.
    /// - Parameter cursor: iterator
    /// - Parameter match: glob-style pattern
    /// - parameter count: The amount of work that should be done at every call in order
    ///                   to retrieve elements from the collection.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zscan(_ key: String, cursor: Int, match: String? = nil, count: Int? = nil) -> RedisMulti {
        let ZSCAN = RedisString("ZSCAN")
        let MATCH = RedisString("MATCH")
        let COUNT = RedisString("COUNT")
        
        if let match = match, let count = count {
            queuedCommands.append([ZSCAN, RedisString(key), RedisString(cursor), MATCH, RedisString(match), COUNT, RedisString(count)])
        }
        if let match = match {
            queuedCommands.append([ZSCAN, RedisString(key), RedisString(cursor), MATCH, RedisString(match)])
        } else if let count = count {
            queuedCommands.append([ZSCAN, RedisString(key), RedisString(cursor), COUNT, RedisString(count)])
        } else {
            queuedCommands.append([ZSCAN, RedisString(key), RedisString(cursor)])
        }
        return self
    }
    
    /// Add an ZSCORE command to the "transactions"
    ///
    /// - Parameter key: The key.
    /// - Parameter member: The member to get the score from.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zscore(_ key: String, member: String) -> RedisMulti {
        queuedCommands.append([RedisString("ZSCORE"), RedisString(key), RedisString(member)])
        return self
    }
    
    /// Add an ZUNIONSTORE command to the "transactions"
    ///
    /// - Parameter destination: The destination where the result will be stored.
    /// - Parameter numkeys: The number of keys to union.
    /// - Parameter keys: The keys.
    /// - Parameter weights: A multiplication factor for each input sorted set.
    /// - Parameter aggregate: Specify how the results of the union are aggregated.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zunionstore(_ destination: String, numkeys: Int, keys: String..., weights: [Int] = [], aggregate: String = "") -> RedisMulti {
        return zunionstoreWithArray(destination, numkeys: numkeys, keys: keys, weights: weights, aggregate: aggregate)
    }
    
    /// Add an ZUNIONSTORE command to the "transactions"
    ///
    /// - Parameter destination: The destination where the result will be stored.
    /// - Parameter numkeys: The number of keys to union.
    /// - Parameter keys: The keys.
    /// - Parameter weights: A multiplication factor for each input sorted set.
    /// - Parameter aggregate: Specify how the results of the union are aggregated.
    /// - Parameter callback: The callback function, the Int will contain the number of elements
    ///                       in the resulting sorted set at destination.
    ///                       NSError will be non-nil if an error occured.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func zunionstoreWithArray(_ destination: String, numkeys: Int, keys: [String], weights: [Int], aggregate: String) -> RedisMulti {
        queuedCommands.append(appendValues(operation: "ZUNIONSTORE", destination, numkeys: numkeys, keys: keys, weights: weights, aggregate: aggregate))
        return self
    }
    
    //Appends all the values into a String array ready to be used for issueCommandInArray()
    private func appendValues(operation: String, _ destination: String, numkeys: Int, keys: [String], weights: [Int], aggregate: String) -> [RedisString] {
        var command = [RedisString(operation)]
        command.append(RedisString(destination))
        command.append(RedisString(numkeys))
        for key in keys {
            command.append(RedisString(key))
        }
        if weights.count > 0 {
            command.append(RedisString("WEIGHTS"))
            for weight in weights {
                command.append(RedisString(weight))
            }
        }
        if aggregate != "" {
            command.append(RedisString("AGGREGATE"))
            command.append(RedisString(aggregate))
        }
        return command
    }

}
