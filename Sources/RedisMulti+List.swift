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

/// Extend RedisMulti by adding the List operations

/* NOTE
 *
 * Blocking commands in transactions return nil immediately when their list parameters are empty.
 *
 * See https://redis.io/commands/blpop
 */
extension RedisMulti {
    
    /// Add a BLPOP command to the "transaction"
    ///
    /// - Parameter keys: The keys of the lists to check for an element.
    /// - Parameter timeout: The amount of time to wait or zero to wait forever.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func blpop(_ keys: String..., timeout: TimeInterval) -> RedisMulti {
        return blpopArrayofKeys(keys, timeout: timeout)
    }
        
    /// Add a BLPOP command to the "transaction"
    ///
    /// - Parameter keys: The array of keys of the lists to check for an element.
    /// - Parameter timeout: The amount of time to wait or zero to wait forever.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func blpopArrayofKeys(_ keys: [String], timeout: TimeInterval) -> RedisMulti {
        var command = [RedisString("BLPOP")]
        for key in keys {
            command.append(RedisString(key))
        }
        command.append(RedisString(Int(timeout)))
        queuedCommands.append(command)
        return self
    }
    
    /// Add a BRPOP command to the "transaction"
    ///
    /// - Parameter keys: The keys of the lists to check for an element.
    /// - Parameter timeout: The amount of time to wait or zero to wait forever.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func brpop(_ keys: String..., timeout: TimeInterval) -> RedisMulti {
        return brpopArrayOfKeys(keys, timeout: timeout)
    }

    /// Add a BRPOP command to the "transaction"
    ///
    /// - Parameter keys: The array of keys of the lists to check for an element.
    /// - Parameter timeout: The amount of time to wait or zero to wait forever.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func brpopArrayOfKeys(_ keys: [String], timeout: TimeInterval) -> RedisMulti {
        var command = [RedisString("BRPOP")]
        for key in keys {
            command.append(RedisString(key))
        }
        command.append(RedisString(Int(timeout)))
        queuedCommands.append(command)
        return self
    }
    
    /// Add a BRPOPLPUSH command to the "transaction"
    ///
    /// - Parameter source: The list to pop an item from.
    /// - Parameter destination: The list to push the poped item onto.
    /// - Parameter timeout: The amount of time to wait or zero to wait forever.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func brpoplpush(_ source: String, destination: String, timeout: TimeInterval) -> RedisMulti {
        queuedCommands.append([RedisString("BRPOPLPUSH"), RedisString(source), RedisString(destination), RedisString(Int(timeout))])
        return self
    }
    
    /// Add a LINDEX command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter index: The index of the element to retrieve.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func lindex(_ key: String, index: Int) -> RedisMulti {
        queuedCommands.append([RedisString("LINDEX"), RedisString(key), RedisString(index)])
        return self
    }
    
    /// Add a LINSERT command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter before: If true, the value is inserted before the pivot.
    /// - Parameter pivot: The pivot around which the value will be inserted.
    /// - Parameter value: The value to be inserted.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func linsert(_ key: String, before: Bool, pivot: String, value: String) -> RedisMulti {
        queuedCommands.append([RedisString("LINSERT"), RedisString(key), RedisString(before ? "BEFORE" : "AFTER"), RedisString(pivot), RedisString(value)])
        return self
    }
    
    /// Add a LINSERT command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter before: If true, the value is inserted before the pivot.
    /// - Parameter pivot: The pivot, in the form of a `RedisString`, around which
    ///                   the value will be inserted.
    /// - Parameter value: The value, in the form of a `RedisString`, to be inserted.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func linsert(_ key: String, before: Bool, pivot: RedisString, value: RedisString) -> RedisMulti {
        queuedCommands.append([RedisString("LINSERT"), RedisString(key), RedisString(before ? "BEFORE" : "AFTER"), pivot, value])
        return self
    }
    
    /// Add a LLEN command to the "transaction"
    ///
    /// - Parameter key: The key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func llen(_ key: String) -> RedisMulti {
        queuedCommands.append([RedisString("LLEN"), RedisString(key)])
        return self
    }
    
    /// Add a LPOP command to the "transaction"
    ///
    /// - Parameter key: The key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func lpop(_ key: String) -> RedisMulti {
        queuedCommands.append([RedisString("LPOP"), RedisString(key)])
        return self
    }
    
    /// Add a LPUSH command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter values: The set of the values to be pushed on to the list.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func lpush(_ key: String, values: String...) -> RedisMulti {
        return lpushArrayOfValues(key, values: values)
    }
    
    /// Add a LPUSH command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter values: An array of values to be pushed on to the list.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func lpushArrayOfValues(_ key: String, values: [String]) -> RedisMulti {
        var command = [RedisString("LPUSH"), RedisString(key)]
        for value in values {
            command.append(RedisString(value))
        }
        queuedCommands.append(command)
        return self
    }
    
    /// Add a LPUSH command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter values: The array of the values, in the form of `RedisString`s,
    ///                    to be pushed on to the list.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func lpush(_ key: String, values: RedisString...) -> RedisMulti {
        return lpushArrayOfValues(key, values: values)
    }
    
    /// Add a LPUSH command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter values: The array of the values, in the form of `RedisString`s,
    ///                    to be pushed on to the list.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func lpushArrayOfValues(_ key: String, values: [RedisString]) -> RedisMulti {
        var command = [RedisString("LPUSH"), RedisString(key)]
        for value in values {
            command.append(value)
        }
        queuedCommands.append(command)
        return self
    }
    
    /// Add a LPUSHX command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter value: The value to be pushed on to the list.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func lpushx(_ key: String, value: String) -> RedisMulti {
        queuedCommands.append([RedisString("LPUSHX"), RedisString(key), RedisString(value)])
        return self
    }
    
    /// Add a LPUSHX command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter values: The value, in the form of `RedisString`, to be pushed on to the list.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func lpushx(_ key: String, value: RedisString) -> RedisMulti {
        queuedCommands.append([RedisString("LPUSHX"), RedisString(key), value])
        return self
    }

    /// Add a LRANGE command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter start: The index to start retrieving from.
    /// - Parameter end: The index to stop retrieving at.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func lrange(_ key: String, start: Int, end: Int) -> RedisMulti {
        queuedCommands.append([RedisString("LRANGE"), RedisString(key), RedisString(start), RedisString(end)])
        return self
    }
    
    /// Add a LREM command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter count: The number of elements to remove.
    /// - Parameter value: The value of the elements to remove.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func lrem(_ key: String, count: Int, value: String) -> RedisMulti {
        queuedCommands.append([RedisString("LREM"), RedisString(key), RedisString(count), RedisString(value)])
        return self
    }
    
    /// Add a LREM command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter count: The number of elements to remove.
    /// - Parameter value: The value of the elemnts to remove in the form of a `RedisString`.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func lrem(_ key: String, count: Int, value: RedisString) -> RedisMulti {
        queuedCommands.append([RedisString("LREM"), RedisString(key), RedisString(count), value])
        return self
    }
    
    /// Add a LSET command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter index: The index of the value in the list to be updated.
    /// - Parameter value: The new value for the element of the list.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func lset(_ key: String, index: Int, value: String) -> RedisMulti {
        queuedCommands.append([RedisString("LSET"), RedisString(key), RedisString(index), RedisString(value)])
        return self
    }
    
    /// Add a LSET command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter index: The index of the value in the list to be updated.
    /// - Parameter value: The new value for the element of the list  in the form of a `RedisString`.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func lset(_ key: String, index: Int, value: RedisString) -> RedisMulti {
        queuedCommands.append([RedisString("LSET"), RedisString(key), RedisString(index), value])
        return self
    }
    
    /// Add a LTRIM command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter start: The index of the first element of the list to keep.
    /// - Parameter end: The index of the last element of the list to keep.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func ltrim(_ key: String, start: Int, end: Int) -> RedisMulti {
        queuedCommands.append([RedisString("LTRIM"), RedisString(key), RedisString(start), RedisString(end)])
        return self
    }
    
    /// Add a RPOP command to the "transaction"
    ///
    /// - Parameter key: The key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func rpop(_ key: String) -> RedisMulti {
        queuedCommands.append([RedisString("RPOP"), RedisString(key)])
        return self
    }
    
    /// Add a RPOPLPUSH command to the "transaction"
    ///
    /// - Parameter source: The list to pop an item from.
    /// - Parameter destination: The list to push the poped item onto.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func rpoplpush(_ source: String, destination: String) -> RedisMulti {
        queuedCommands.append([RedisString("RPOPLPUSH"), RedisString(source), RedisString(destination)])
        return self
    }
    
    /// Add a RPUSH command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter values: The list of values to be pushed on to the list.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func rpush(_ key: String, values: String...) -> RedisMulti {
        return rpushArrayOfValues(key, values: values)
    }
    
    /// Add a RPUSH command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter values: An array of values to be pushed on to the list.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func rpushArrayOfValues(_ key: String, values: [String]) -> RedisMulti {
        var command = [RedisString("RPUSH"), RedisString(key)]
        for value in values {
            command.append(RedisString(value))
        }
        queuedCommands.append(command)
        return self
    }
    
    /// Add a RPUSH command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter values: The list of `RedisString` values to be pushed on to the list.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func rpush(_ key: String, values: RedisString...) -> RedisMulti {
        return rpushArrayOfValues(key, values: values)
    }
    
    /// Add a RPUSH command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter values: An array of `RedisString` values to be pushed on to the list
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func rpushArrayOfValues(_ key: String, values: [RedisString]) -> RedisMulti {
        var command = [RedisString("RPUSH"), RedisString(key)]
        for value in values {
            command.append(value)
        }
        queuedCommands.append(command)
        return self
    }
    
    /// Add a RPUSHX command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter values: The value to be pushed on to the list.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func rpushx(_ key: String, value: String) -> RedisMulti {
        queuedCommands.append([RedisString("RPUSHX"), RedisString(key), RedisString(value)])
        return self
    }
    
    /// Add a RPUSHX command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter values: The `RedisString` value to be pushed on to the list.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func rpushx(_ key: String, value: RedisString) -> RedisMulti {
        queuedCommands.append([RedisString("RPUSHX"), RedisString(key), value])
        return self
    }
}
