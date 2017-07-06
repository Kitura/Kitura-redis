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
extension RedisMulti {
    
    /// Add a SADD command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter members: The values to be added to the set.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sadd(_ key: String, members: String...) -> RedisMulti {
        return saddArrayOfMembers(key, members: members)
    }
    
    /// Add a SADD command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter members: An array of values to be added to the set.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func saddArrayOfMembers(_ key: String, members: [String]) -> RedisMulti {
        var command = [RedisString("SADD"), RedisString(key)]
        for member in members {
            command.append(RedisString(member))
        }
        queuedCommands.append(command)
        return self
    }

    /// Add a SADD command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter members: The `RedisString` values to be added to the set.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sadd(_ key: RedisString, members: RedisString...) -> RedisMulti {
        return saddArrayOfMembers(key, members: members)
    }
    
    /// Add a SADD command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter members: An array of `RedisString` values to be added to the set.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func saddArrayOfMembers(_ key: RedisString, members: [RedisString]) -> RedisMulti {
        var command = [RedisString("SADD"), key]
        for member in members {
            command.append(member)
        }
        queuedCommands.append(command)
        return self
    }
    
    /// Add a SCARD command to the "transaction"
    ///
    /// - Parameter key: The key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func scard(_ key: String) -> RedisMulti {
        queuedCommands.append([RedisString("SCARD"), RedisString(key)])
        return self
    }
    
    /// Add a SCARD command to the "transaction"
    ///
    /// - Parameter key: The key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func scard(_ key: RedisString) -> RedisMulti {
        queuedCommands.append([RedisString("SCARD"), key])
        return self
    }
    
    /// Add a SDIFF command to the "transaction"
    ///
    /// - Parameter keys: The list of keys to get the difference from.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sdiff(keys: String...) -> RedisMulti {
        return sdiffArrayOfKeys(keys: keys)
    }
    
    /// Add a SDIFF command to the "transaction"
    ///
    /// - Parameter keys: An array of the keys to get the difference from.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sdiffArrayOfKeys(keys: [String]) -> RedisMulti {
        var command = [RedisString("SDIFF")]
        for key in keys {
            command.append(RedisString(key))
        }
        queuedCommands.append(command)
        return self
    }
    
    /// Add a SDIFF command to the "transaction"
    ///
    /// - Parameter keys: The list of the keys to get the difference from.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sdiff(keys: RedisString...) -> RedisMulti {
        return sdiffArrayOfKeys(keys: keys)
    }
    
    /// Add a SDIFF command to the "transaction"
    ///
    /// - Parameter keys: An array of the keys to get the difference from.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sdiffArrayOfKeys(keys: [RedisString]) -> RedisMulti {
        var command = [RedisString("SDIFF")]
        for key in keys {
            command.append(key)
        }
        queuedCommands.append(command)
        return self
    }
    
    /// Add a SDIFF command to the "transaction"
    ///
    /// - Parameter destination: The destination of the result, if the
    ///                         destination already exists, it is overwritten
    /// - Parameter keys: The list of the keys to get the difference from.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sdiffstore(destination: String, keys: String...) -> RedisMulti {
        return sdiffstoreArrayOfKeys(destination: destination, keys: keys)
    }
    
    /// Add a SDIFFSTORE command to the "transaction"
    ///
    /// - Parameter destination: The destination of the result.
    /// - Parameter keys: An array of the keys to get the difference from.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sdiffstoreArrayOfKeys(destination: String, keys: [String]) -> RedisMulti {
        
        var command = [RedisString("SDIFFSTORE"), RedisString(destination)]
        for key in keys {
            command.append(RedisString(key))
        }
        self.queuedCommands.append(command)
        return self
    }
    
    /// Add a SDIFFSTORE command to the "transaction"
    ///
    /// - Parameter destination: The destination of the result, if the
    ///                         destination already exists, it is overwritten
    /// - Parameter keys: The list of the keys to get the difference from.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sdiffstore(destination: RedisString, keys: RedisString...) -> RedisMulti {
        return sdiffstoreArrayOfKeys(destination: destination, keys: keys)
        
    }
    
    /// Add a SDIFFSTORE command to the "transaction"
    ///
    /// - Parameter destination: Tthe destination of the result.
    /// - Parameter keys: An array of keys to get the difference from.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sdiffstoreArrayOfKeys(destination: RedisString, keys: [RedisString]) -> RedisMulti {
        
        var command = [RedisString("SDIFFSTORE"), destination]
        for key in keys {
            command.append(key)
        }
        self.queuedCommands.append(command)
        return self
    }
    
    /// Add a SMEMBERS command to the "transaction"
    ///
    /// - Parameter key: The key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func smembers(_ key: String) -> RedisMulti {
        queuedCommands.append([RedisString("SMEMBERS"), RedisString(key)])
        return self
    }
    
    /// Add a SMEMBERS command to the "transaction"
    ///
    /// - Parameter key: The key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func smembers(_ key: RedisString) -> RedisMulti {
        queuedCommands.append([RedisString("SMEMBERS"), key])
        return self
    }
    
    /// Add a SINTER command to the "transaction"
    ///
    /// - Parameter keys: The list of the keys to intersect from.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sinter(_ keys: String...) -> RedisMulti {
        return sinterArrayOfKeys(keys)
    }
    
    /// Add a SINTER command to the "transaction"
    ///
    /// - Parameter keys: An array of the keys to intersect from.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sinterArrayOfKeys(_ keys: [String]) -> RedisMulti {
        var command = [RedisString("SINTER")]
        for key in keys {
            command.append(RedisString(key))
        }
        queuedCommands.append(command)
        return self
    }
    
    /// Add a SINTER command to the "transaction"
    ///
    /// - Parameter keys: The list of the keys to intersect from.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    public func sinter(_ keys: RedisString...) -> RedisMulti {
        return sinterArrayOfKeys(keys)
    }
    
    /// Add a SINTER command to the "transaction"
    ///
    /// - Parameter keys: An array of the keys to intersect from.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sinterArrayOfKeys(_ keys: [RedisString]) -> RedisMulti {
        var command = [RedisString("SINTER")]
        for key in keys {
            command.append(key)
        }
        queuedCommands.append(command)
        return self
    }
    
    /// Add a SINTERSTORE command to the "transaction"
    ///
    /// - Parameter destination: The destination of the result.
    /// - Parameter keys: The list of the keys to intersect from.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sinterstore(_ destination: String, keys: String...) -> RedisMulti {
        return sinterstoreArrayOfKeys(destination, keys: keys)
    }
    
    /// Add a SINTERSTORE command to the "transaction"
    ///
    /// - Parameter destination: The destination of the result.
    /// - Parameter keys: An array of the keys to intersect from.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sinterstoreArrayOfKeys(_ destination: String, keys: [String]) -> RedisMulti {
        var command = [RedisString("SINTERSTORE"), RedisString(destination)]
        for key in keys {
            command.append(RedisString(key))
        }
        queuedCommands.append(command)
        return self
    }
    
    /// Add a SINTERSTORE command to the "transaction"
    ///
    /// - Parameter destination: The destination of the result.
    /// - Parameter keys: The list of the keys to intersect from.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sinterstore(_ destination: RedisString, keys: RedisString...) -> RedisMulti {
        return sinterstoreArrayOfKeys(destination, keys: keys)
    }
    
    /// Add a SINTERSTORE command to the "transaction"
    ///
    /// - Parameter destination: The destination of the result.
    /// - Parameter keys: An array of the keys to intersect from.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sinterstoreArrayOfKeys(_ destination: RedisString, keys: [RedisString]) -> RedisMulti {
        var command = [RedisString("SINTERSTORE"), destination]
        for key in keys {
            command.append(key)
        }
        queuedCommands.append(command)
        return self
    }
    
    /// Add a SISMEMBER command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter member: The String parameter for the member.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sismember(_ key: String, member: String) -> RedisMulti {
        queuedCommands.append([RedisString("SISMEMBER"), RedisString(key), RedisString(member)])
        return self
    }
    
    /// Add a SISMEMBER command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter member: The `RedisString` parameter for the member.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sismember(_ key: RedisString, member: RedisString) -> RedisMulti {
        queuedCommands.append([RedisString("SISMEMBER"), key, member])
        return self
    }
    
    /// Add a SMOVE command to the "transaction"
    ///
    /// - Parameter source: The Source set from where to move the member from.
    /// - Parameter destination: The Destination set from where to move the member to.
    /// - Parameter member: The String parameter for the member to be moved.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func smove(source: String, destination: String, member: String) -> RedisMulti {
        queuedCommands.append([RedisString("SMOVE"), RedisString(source), RedisString(destination), RedisString(member)])
        return self
    }
    
    /// Add a SMOVE command to the "transaction"
    ///
    /// - Parameter source: The Source set from where to move the member from.
    /// - Parameter destination: The Destination set from where to move the member to.
    /// - Parameter member: The RedisString parameter for the member to be moved.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func smove(source: RedisString, destination: RedisString, member: RedisString) -> RedisMulti {
        queuedCommands.append([RedisString("SMOVE"), source, destination, member])
        return self
    }
    
    /// Add a SPOP command to the "transaction"
    ///
    /// - Parameter key: The key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func spop(_ key: String) -> RedisMulti {
        queuedCommands.append([RedisString("SPOP"), RedisString(key)])
        return self
    }
    
    /// Add a SPOP command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter count: The number of members to pop.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func spop(_ key: String, count: Int) -> RedisMulti {
        queuedCommands.append([RedisString("SPOP"), RedisString(key), RedisString(count)])
        return self
    }
    
    /// Add a SPOP command to the "transaction"
    ///
    /// - Parameter key: The key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func spop(_ key: RedisString) -> RedisMulti {
        queuedCommands.append([RedisString("SPOP"), key])
        return self
    }
    
    /// Add a SPOP command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter count: The number of members to pop.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func spop(_ key: RedisString, count: Int) -> RedisMulti {
        queuedCommands.append([RedisString("SPOP"), key, RedisString(count)])
        return self
    }
    
    /// Add a SRANDMEMBER command to the "transaction"
    ///
    /// - Parameter key: The key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func srandmember(_ key: String) -> RedisMulti {
        queuedCommands.append([RedisString("SRANDMEMBER"), RedisString(key)])
        return self
    }
    
    /// Add a SRANDMEMBER command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter count: The number of members to return.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func srandmember(_ key: String, count: Int) -> RedisMulti {
        queuedCommands.append([RedisString("SRANDMEMBER"), RedisString(key), RedisString(count)])
        return self
    }
    
    /// Get a random member from a set
    ///
    /// - Parameter key: The key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func srandmember(_ key: RedisString) -> RedisMulti {
        queuedCommands.append([RedisString("SRANDMEMBER"), key])
        return self
    }
    
    /// Add a SRANDMEMBER command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter count: The number of members to return.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func srandmember(_ key: RedisString, count: Int) -> RedisMulti {
        queuedCommands.append([RedisString("SRANDMEMBER"), key, RedisString(count)])
        return self
    }
    
    /// Add a SREM command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter members: The list of the members to be removed.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func srem(_ key: String, members: String...) -> RedisMulti {
        return sremArrayOfMembers(key, members: members)
    }
    
    /// Add a SREM command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter members: An Array of the members to be removed.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sremArrayOfMembers(_ key: String, members: [String]) -> RedisMulti {
        var command = [RedisString("SREM"), RedisString(key)]
        for member in members {
            command.append(RedisString(member))
        }
        queuedCommands.append(command)
        return self
    }
    
    /// Add a SREM command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter members: The list of the members to be removed.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func srem(_ key: RedisString, members: RedisString...) -> RedisMulti {
        return sremArrayOfMembers(key, members: members)
    }
    
    /// Add a SREM command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter members: An array of the members to be removed.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sremArrayOfMembers(_ key: RedisString, members: [RedisString]) -> RedisMulti {
        var command = [RedisString("SREM"), key]
        for member in members {
            command.append(member)
        }
        queuedCommands.append(command)
        return self
    }
    
    /// Add a SUNION command to the "transaction"
    ///
    /// - Parameter keys: The list of the keys to union.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sunion(_ keys: String...) -> RedisMulti {
        return sunionArrayOfKeys(keys)
    }
    
    /// Add a SUNION command to the "transaction"
    ///
    /// - Parameter keys: An array of the keys to union.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sunionArrayOfKeys(_ keys: [String]) -> RedisMulti {
        var command = [RedisString("SUNION")]
        for key in keys {
            command.append(RedisString(key))
        }
        queuedCommands.append(command)
        return self
    }
    
    /// Add a SUNION command to the "transaction"
    ///
    /// - Parameter keys: The list of the keys to union.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sunion(_ keys: RedisString...) -> RedisMulti {
        return sunionArrayOfKeys(keys)
    }
    
    /// Add a SUNION command to the "transaction"
    ///
    /// - Parameter keys: The list of the keys to union.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sunionArrayOfKeys(_ keys: [RedisString]) -> RedisMulti {
        var command = [RedisString("SUNION")]
        for key in keys {
            command.append(key)
        }
        queuedCommands.append(command)
        return self
    }
    
    /// Add a SUNIONSTORE command to the "transaction"
    ///
    /// - Parameter keys: The list of the keys to union.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sunionstore(_ destination: String, keys: String...) -> RedisMulti {
        return sunionstoreArrayOfKeys(destination, keys: keys)
    }
    
    /// Add a SUNIONSTORE command to the "transaction"
    ///
    /// - Parameter keys: The list of the keys to union.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sunionstoreArrayOfKeys(_ destination: String, keys: [String]) -> RedisMulti {
        var command = [RedisString("SUNIONSTORE"), RedisString(destination)]
        for key in keys {
            command.append(RedisString(key))
        }
        queuedCommands.append(command)
        return self
    }
    
    /// Add a SUNIONSTORE command to the "transaction"
    ///
    /// - Parameter keys: The list of the keys to union.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sunionstore(_ destination: RedisString, keys: RedisString...) -> RedisMulti {
        return sunionstoreArrayOfKeys(destination, keys: keys)
    }
    
    /// Add a SUNIONSTORE command to the "transaction"
    ///
    /// - Parameter keys: The list of the keys to union.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sunionstoreArrayOfKeys(_ destination: RedisString, keys: [RedisString]) -> RedisMulti {
        var command = [RedisString("SUNIONSTORE"), destination]
        for key in keys {
            command.append(key)
        }
        queuedCommands.append(command)
        return self
    }
    
    /// Add a SSCAN command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter cursor: iterator
    /// - Parameter match: glob-style pattern
    /// - parameter count: The amount of work that should be done at every call in order
    ///                   to retrieve elements from the collection.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sscan(_ key: String, cursor: Int, match: String? = nil, count: Int? = nil)
        -> RedisMulti {
        if let match = match, let count = count {
            queuedCommands.append([RedisString("SSCAN"), RedisString(key), RedisString(cursor), RedisString("MATCH"), RedisString(match), RedisString("COUNT"), RedisString(count)])
        } else if let match = match {
            queuedCommands.append([RedisString("SSCAN"), RedisString(key), RedisString(cursor), RedisString("MATCH"), RedisString(match)])
        } else if let count = count {
            queuedCommands.append([RedisString("SSCAN"), RedisString(key), RedisString(cursor), RedisString("COUNT"), RedisString(count)])
        } else {
            queuedCommands.append([RedisString("SSCAN"), RedisString(key), RedisString(cursor)])
        }
            return self
    }
    
    /// Add a SSCAN command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter cursor: iterator
    /// - Parameter match: glob-style pattern
    /// - parameter count: The amount of work that should be done at every call in order
    ///                   to retrieve elements from the collection.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func sscan(_ key: RedisString, cursor: Int, match: RedisString? = nil, count: Int? = nil)
        -> RedisMulti {
        let SSCAN = RedisString("SSCAN")
        let MATCH = RedisString("MATCH")
        let COUNT = RedisString("COUNT")
        if let match = match, let count = count {
            queuedCommands.append([SSCAN, key, RedisString(cursor), MATCH, match, COUNT, RedisString(count)])
        } else if let match = match {
            queuedCommands.append([SSCAN, key, RedisString(cursor), MATCH, match])
        } else if let count = count {
            queuedCommands.append([SSCAN, key, RedisString(cursor), COUNT, RedisString(count)])
        } else {
            queuedCommands.append([SSCAN, key, RedisString(cursor)])
        }
            return self
    }
}
