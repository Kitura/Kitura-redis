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

/// Extend RedisMulti by adding the Hash operations
extension RedisMulti {

    /// Add a HDEL command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter fields: The list of fields to remove.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func hdel(_ key: String, fields: String...) -> RedisMulti {
        var command = [RedisString("HDEL"), RedisString(key)]
        for field in fields {
            command.append(RedisString(field))
        }
        queuedCommands.append(command)
        return self
    }

    /// Add a HEXISTS command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter field: The field.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func hexists(_ key: String, field: String) -> RedisMulti {
        queuedCommands.append([RedisString("HEXISTS"), RedisString(key), RedisString(field)])
        return self
    }

    /// Add a HGET command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter field: The field.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func hget(_ key: String, field: String) -> RedisMulti {
        queuedCommands.append([RedisString("HGET"), RedisString(key), RedisString(field)])
        return self
    }

    /// Add a HGETALL command to the "transaction"
    ///
    /// - Parameter key: The key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func hgetall(_ key: String) -> RedisMulti {
        queuedCommands.append([RedisString("HGETALL"), RedisString(key)])
        return self
    }

    /// Add a HINCRBY command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter field: The field.
    /// - Parameter by: The value to increment by.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func hincr(_ key: String, field: String, by: Int) -> RedisMulti {
        queuedCommands.append([RedisString("HINCRBY"), RedisString(key), RedisString(field), RedisString(by)])
        return self
    }

    /// Add a HINCRBYFLOAT command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter field: The field.
    /// - Parameter byFloat: The floating point value to increment by.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func hincr(_ key: String, field: String, byFloat: Float) -> RedisMulti {
        queuedCommands.append([RedisString("HINCRBYFLOAT"), RedisString(key), RedisString(field), RedisString(Double(byFloat))])
        return self
    }

    /// Add a HKEYS command to the "transaction"
    ///
    /// - Parameter key: The key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func hkeys(_ key: String) -> RedisMulti {
        queuedCommands.append([RedisString("HKEYS"), RedisString(key)])
        return self
    }

    /// Add a HLEN command to the "transaction"
    ///
    /// - Parameter key: The key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func hlen(_ key: String) -> RedisMulti {
        queuedCommands.append([RedisString("HLEN"), RedisString(key)])
        return self
    }

    /// Add a HMGET command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter fields: The list of field names.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func hmget(_ key: String, fields: String...) -> RedisMulti {
        var command = [RedisString("HMGET"), RedisString(key)]
        for field in fields {
            command.append(RedisString(field))
        }
        queuedCommands.append(command)
        return self
    }

    /// Add a HMSET command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter fieldValuePairs: The list of field name value tuples to set.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func hmset(_ key: String, fieldValuePairs: (String, String)...) -> RedisMulti {
        return hmsetArrayOfKeyValues(key, fieldValuePairs: fieldValuePairs)
    }

    /// Add a HMSET command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter fieldValuePairs: The array of field name value tuples to set.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func hmsetArrayOfKeyValues(_ key: String, fieldValuePairs: [(String, String)]) -> RedisMulti {
        var command = [RedisString("HMSET"), RedisString(key)]
        for (field, value) in fieldValuePairs {
            command.append(RedisString(field))
            command.append(RedisString(value))
        }
        queuedCommands.append(command)
        return self
    }

    /// Add a HMSET command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter fieldValuePairs: The list of field name value tuples to set. With values as `RedisString`s.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func hmset(_ key: String, fieldValuePairs: (String, RedisString)...) -> RedisMulti {
        return hmsetArrayOfKeyValues(key, fieldValuePairs: fieldValuePairs)
    }

    /// Add a HMSET command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter fieldValuePairs: The array of field name value tuples to set. With values as `RedisString`s.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func hmsetArrayOfKeyValues(_ key: String, fieldValuePairs: [(String, RedisString)]) -> RedisMulti {
        var command = [RedisString("HMSET"), RedisString(key)]
        for (field, value) in fieldValuePairs {
            command.append(RedisString(field))
            command.append(value)
        }
        queuedCommands.append(command)
        return self
    }

    /// Add a HSCAN command to the "transaction"
    ///
    /// - Parameter key: The key of the hash.
    /// - parameter cursor: Where to begin iterating.
    /// - parameter match: Glob-style pattern to match elements against.
    /// - parameter count: Amount of elements to try to iterate.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func hscan(key: String, cursor: Int, match: String?=nil, count: Int?=nil) -> RedisMulti {
        var command = ["HSCAN", key, String(cursor)]
        if let match = match, let count = count {
            command.append("MATCH")
            command.append(match)
            command.append("COUNT")
            command.append(String(count))
        } else if let match = match {
            command.append("MATCH")
            command.append(match)
        } else if let count = count {
            command.append("COUNT")
            command.append(String(count))
        }
        queuedCommands.append(stringArrToRedisStringArr(command))
        return self
    }
    
    /// Add a HSET or a HSETNX command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter field: The name of the field name to set.
    /// - Parameter value: The value to set the field to.
    /// - Parameter exists: If true, will set the value only if the field exists.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func hset(_ key: String, field: String, value: String, exists: Bool=true) -> RedisMulti {
        queuedCommands.append([RedisString(exists ? "HSET" : "HSETNX"), RedisString(key), RedisString(field), RedisString(value)])
        return self
    }

    /// Add a HSET or a HSETNX command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter field: The name of the field name to set.
    /// - Parameter value: The value in the form of a `RedisString` to set the field to.
    /// - Parameter exists: If true, will set the value only if the field exists.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func hset(_ key: String, field: String, value: RedisString, exists: Bool=true) -> RedisMulti {
        queuedCommands.append([RedisString(exists ? "HSET" : "HSETNX"), RedisString(key), RedisString(field), value])
        return self
    }

    /// Add a HSTRLEN command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter field: The name of the field.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func hstrlen(_ key: String, field: String) -> RedisMulti {
        queuedCommands.append([RedisString("HSTRLEN"), RedisString(key), RedisString(field)])
        return self
    }

    /// Add a HVALS command to the "transaction"
    ///
    /// - Parameter key: The key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func hvals(_ key: String) -> RedisMulti {
        queuedCommands.append([RedisString("HVALS"), RedisString(key)])
        return self
    }
}
