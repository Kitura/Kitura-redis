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

/// Extend RedisMulti by adding the List operations
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
    
    /// Add a BLPOP command to the "transaction"
    ///
    /// - Parameter keys: The `RedisString` keys of the lists to check for an element.
    /// - Parameter timeout: The amount of time to wait or zero to wait forever.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func blpop(_ keys: RedisString..., timeout: TimeInterval) -> RedisMulti {
        return blpopArrayofKeys(keys, timeout: timeout)
    }
    
    /// Add a BLPOP command to the "transaction"
    ///
    /// - Parameter keys: The `RedisString` array of keys of the lists to check for an element.
    /// - Parameter timeout: The amount of time to wait or zero to wait forever.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func blpopArrayofKeys(_ keys: [RedisString], timeout: TimeInterval) -> RedisMulti {
        var command = [RedisString("BLPOP")]
        for key in keys {
            command.append(key)
        }
        command.append(RedisString(Int(timeout)))
        queuedCommands.append(command)
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
}
