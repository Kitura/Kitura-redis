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

/// Extend RedisMulti by adding the Basic operations
extension RedisMulti {

    /// Add an APPEND command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter value: The value to append.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func append(_ key: String, value: String) -> RedisMulti {
        queuedCommands.append([RedisString("APPEND"), RedisString(key), RedisString(value)])
        return self
    }

    /// Add a BITCOUNT command to the "transaction"
    ///
    /// - Parameter key: The key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func bitcount(_ key: String) -> RedisMulti {
        queuedCommands.append([RedisString("BITCOUNT"), RedisString(key)])
        return self
    }

    /// Add a BITCOUNT command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter start: The starting index in the string to count from.
    /// - Parameter end: The ending index in the string to count to.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func bitcount(_ key: String, start: Int, end: Int) -> RedisMulti {
        queuedCommands.append([RedisString("BITCOUNT"), RedisString(key), RedisString(start), RedisString(end)])
        return self
    }

    /// Add a BITOP AND command to the "transaction"
    ///
    /// - Parameter destKey: The destination key.
    /// - Parameter and: The list of keys whose values will be AND'ed.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func bitop(_ destKey: String, and: String...) -> RedisMulti {
        var command = [RedisString("BITOP"), RedisString("AND"), RedisString(destKey)]
        for key in and {
            command.append(RedisString(key))
        }
        queuedCommands.append(command)
        return self
    }

    /// Add a BITOP NOT command to the "transaction"
    ///
    /// - Parameter destKey: The destination key.
    /// - Parameter not: The key of the value to be NOT'ed.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func bitop(_ destKey: String, not: String) -> RedisMulti {
        queuedCommands.append([RedisString("BITOP"), RedisString("NOT"), RedisString(destKey), RedisString(not)])
        return self
    }

    /// Add a BITOP OR command to the "transaction"
    ///
    /// - Parameter destKey: The destination key.
    /// - Parameter or: The list of keys whose values will be OR'ed.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func bitop(_ destKey: String, or: String...) -> RedisMulti {
        var command = [RedisString("BITOP"), RedisString("OR"), RedisString(destKey)]
        for key in or {
            command.append(RedisString(key))
        }
        queuedCommands.append(command)
        return self
    }

    /// Add a BITOP XOR command to the "transaction"
    ///
    /// - Parameter destKey: The destination key.
    /// - Parameter xor: The list of keys whose values will be XOR'ed.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func bitop(_ destKey: String, xor: String...) -> RedisMulti {
        var command = [RedisString("BITOP"), RedisString("XOR"), RedisString(destKey)]
        for key in xor {
            command.append(RedisString(key))
        }
        queuedCommands.append(command)
        return self
    }

    /// Add a BITPOS command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter bit: The value to compare against.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func bitpos(_ key: String, bit: Bool) -> RedisMulti {
        queuedCommands.append([RedisString("BITPOS"), RedisString(key), RedisString(bit ? "1" : "0")])
        return self
    }

    /// Add a BITPOS command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter bit: The value to compare against.
    /// - Parameter start: The starting index in the string to search from.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func bitpos(_ key: String, bit: Bool, start: Int) -> RedisMulti {
        queuedCommands.append([RedisString("BITPOS"), RedisString(key), RedisString(bit ? "1" : "0"), RedisString(start)])
        return self
    }

    /// Add a BITPOS command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter bit: The value to compare against.
    /// - Parameter start: The starting index in the string to search from.
    /// - Parameter end: The ending index in the string to search until.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func bitpos(_ key: String, bit: Bool, start: Int, end: Int) -> RedisMulti {
        queuedCommands.append([RedisString("BITPOS"), RedisString(key), RedisString(bit ? "1" : "0"), RedisString(start), RedisString(end)])
        return self
    }

    /// Add a DECRBY command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter by: An integer number that will be subtracted from the value at the key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func decr(_ key: String, by: Int=1) -> RedisMulti {
        queuedCommands.append([RedisString("DECRBY"), RedisString(key), RedisString(by)])
        return self
    }

    /// Add a DEL command to the "transaction"
    ///
    /// - Parameter keys: A list of keys.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func del(_ keys: String...) -> RedisMulti {
        var command = [RedisString("DEL")]
        for key in keys {
            command.append(RedisString(key))
        }
        queuedCommands.append(command)
        return self
    }

    /// Add an EXISTS command to the "transaction"
    ///
    /// - Parameter keys: A list of keys.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func exists(_ keys: String...) -> RedisMulti {
        var command = [RedisString("EXISTS")]
        for key in keys {
            command.append(RedisString(key))
        }
        queuedCommands.append(command)
        return self
    }

    /// Add a PEXPIRE command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter inTime: The expiration period as a number of milliseconds.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func expire(_ key: String, inTime: TimeInterval) -> RedisMulti {
        queuedCommands.append([RedisString("PEXPIRE"), RedisString(key), RedisString(Int(inTime * 1000.0))])
        return self
    }

    /// Add a PEXPIREAT command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter atDate: The key's expiration specified as a timestamp.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func expire(_ key: String, atDate: NSDate) -> RedisMulti {
        queuedCommands.append([RedisString("PEXPIREAT"), RedisString(key), RedisString(Int(atDate.timeIntervalSince1970 * 1000.0))])
        return self
    }

    /// Add a GET command to the "transaction"
    ///
    /// - Parameter key: The key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func get(_ key: String) -> RedisMulti {
        queuedCommands.append([RedisString("GET"), RedisString(key)])
        return self
    }

    /// Add a GETBIT command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter offset: The offset in the string value.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func getbit(_ key: String, offset: Int) -> RedisMulti {
        queuedCommands.append([RedisString("GETBIT"), RedisString(key), RedisString(offset)])
        return self
    }

    /// Add a GETRANGE command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter start: Integer index for the starting position of the substring.
    /// - Parameter end: Integer index for the ending position of the substring.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func getrange(_ key: String, start: Int, end: Int) -> RedisMulti {
        queuedCommands.append([RedisString("GETRANGE"), RedisString(key), RedisString(start), RedisString(end)])
        return self
    }

    /// Add a GETSET command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter value: The String value to set.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func getSet(_ key: String, value: String) -> RedisMulti {
        queuedCommands.append([RedisString("GETSET"), RedisString(key), RedisString(value)])
        return self
    }

    /// Add a GETSET command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter value: The `RedisString` value to set.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func getSet(_ key: String, value: RedisString) -> RedisMulti {
        queuedCommands.append([RedisString("GETSET"), RedisString(key), value])
        return self
    }

    /// Add an INCRBY command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter by: number that will be added to the value at the key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func incr(_ key: String, by: Int=1) -> RedisMulti {
        queuedCommands.append([RedisString("INCRBY"), RedisString(key), RedisString(by)])
        return self
    }

    /// Add an INCRBYFLOAT command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter byFloat: A floating point number that will be added to the value at the key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func incr(_ key: String, byFloat: Float) -> RedisMulti {
        queuedCommands.append([RedisString("INCRBYFLOAT"), RedisString(key), RedisString(Double(byFloat))])
        return self
    }

    /// Add a MGET command to the "transaction"
    ///
    /// - Parameter keys: The list of keys.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func mget(_ keys: String...) -> RedisMulti {
        var command = [RedisString("MGET")]
        for key in keys {
            command.append(RedisString(key))
        }
        queuedCommands.append(command)
        return self
    }

    /// Add a MOVE command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter toDB: The number of the database to move the key to.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func move(_ key: String, toDB: Int) -> RedisMulti {
        queuedCommands.append([RedisString("MOVE"), RedisString(key), RedisString(toDB)])
        return self
    }

    /// Add a MSET or a MSETNX command to the "transaction"
    ///
    /// - Parameter keyValuePairs: A list of tuples containing a key and a value.
    /// - Parameter exists: If true, will set the value only if the key already exists.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func mset(_ keyValuePairs: (String, String)..., exists: Bool=true) -> RedisMulti {
        return msetArrayOfKeyValues(keyValuePairs, exists: exists)
    }

    /// Add a MSET or a MSETNX command to the "transaction"
    ///
    /// - Parameter keyValuePairs: An array of tuples containing a key and a value.
    /// - Parameter exists: If true, will set the value only if the key already exists.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func msetArrayOfKeyValues(_ keyValuePairs: [(String, String)], exists: Bool=true) -> RedisMulti {
        var command = [RedisString(exists ? "MSET" : "MSETNX")]
        for (key, value) in keyValuePairs {
            command.append(RedisString(key))
            command.append(RedisString(value))
        }
        queuedCommands.append(command)
        return self
    }

    /// Add a MSET or a MSETNX command to the "transaction"
    ///
    /// - Parameter keyValuePairs: A list of tuples containing a key and a value in the form of a `RedisString`.
    /// - Parameter exists: If true, will set the value only if the key already exists.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func mset(_ keyValuePairs: (String, RedisString)..., exists: Bool=true) -> RedisMulti {
        return msetArrayOfKeyValues(keyValuePairs, exists: exists)
    }

    /// Add a MSET or a MSETNX command to the "transaction"
    ///
    /// - Parameter keyValuePairs: An array of tuples containing a key and a value in the form of a `RedisString`.
    /// - Parameter exists: If true, will set the value only if the key already exists.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func msetArrayOfKeyValues(_ keyValuePairs: [(String, RedisString)], exists: Bool=true) -> RedisMulti {
        var command = [RedisString(exists ? "MSET" : "MSETNX")]
        for (key, value) in keyValuePairs {
            command.append(RedisString(key))
            command.append(value)
        }
        queuedCommands.append(command)
        return self
    }

    /// Add a PERSIST command to the "transaction"
    ///
    /// - Parameter key: The key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func persist(_ key: String) -> RedisMulti {
        queuedCommands.append([RedisString("PERSIST"), RedisString(key)])
        return self
    }

    /// Add a RENAME or a RENAMENX command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter newKey: The new name for the key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func rename(_ key: String, newKey: String, exists: Bool=true) -> RedisMulti {
        queuedCommands.append([RedisString(exists ? "RENAME" : "RENAMENX"), RedisString(key), RedisString(newKey)])
        return self
    }

    /// Add a SELECT command to the "transaction"
    ///
    /// - Parameter db: numeric index for the database.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func select(_ db: Int) -> RedisMulti {
        queuedCommands.append([RedisString("SELECT"), RedisString(db)])
        return self
    }

    /// Add a SET command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter value: The String value to set.
    /// - Parameter exists: If true will only set the key if it already exists.
    /// - Parameter expiresIn: If not nil, the expiration time, in milliseconds.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func set(_ key: String, value: String, exists: Bool?=nil, expiresIn: TimeInterval?=nil) -> RedisMulti {
        var command = [RedisString("SET"), RedisString(key), RedisString(value)]
        if  let exists = exists {
            command.append(RedisString(exists ? "XX" : "NX"))
        }
        if  let expiresIn = expiresIn {
            command.append(RedisString("PX"))
            command.append(RedisString(Int(expiresIn * 1000.0)))
        }
        queuedCommands.append(command)
        return self
    }

    /// Add a SET command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter value: The `RedisString` value to set.
    /// - Parameter exists: If true will only set the key if it already exists.
    /// - Parameter expiresIn: If not nil, the expiration time, in milliseconds.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func set(_ key: String, value: RedisString, exists: Bool?=nil, expiresIn: TimeInterval?=nil) -> RedisMulti {
        var command = [RedisString("SET"), RedisString(key), value]
        if  let exists = exists {
            command.append(RedisString(exists ? "XX" : "NX"))
        }
        if  let expiresIn = expiresIn {
            command.append(RedisString("PX"))
            command.append(RedisString(Int(expiresIn * 1000.0)))
        }
        queuedCommands.append(command)
        return self
    }

    /// Add a SETBIT command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter offset: The offset in the string value.
    /// - Parameter value: The bit value to set.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func setbit(_ key: String, offset: Int, value: Bool) -> RedisMulti {
        queuedCommands.append([RedisString("SETBIT"), RedisString(key), RedisString(offset), RedisString(value ? "1" : "0")])
        return self
    }

    /// Add a SETRANGE command to the "transaction"
    ///
    /// - Parameter key: The key.
    /// - Parameter offset: Integer index for the starting position within the key's value to overwrite.
    /// - Parameter value: The String value to overwrite the value of the key with.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func setrange(_ key: String, offset: Int, value: String) -> RedisMulti {
        queuedCommands.append([RedisString("SETRANGE"), RedisString(key), RedisString(offset), RedisString(value)])
        return self
    }

    /// Add a STRLEN command to the "transaction"
    ///
    /// - Parameter key: The key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func strlen(_ key: String) -> RedisMulti {
        queuedCommands.append([RedisString("STRLEN"), RedisString(key)])
        return self
    }

    /// Add a PTTL command to the "transaction"
    ///
    /// - Parameter key: The key.
    ///
    /// - Returns: The `RedisMulti` object being added to.
    @discardableResult
    public func ttl(_ key: String) -> RedisMulti {
        queuedCommands.append([RedisString("PTTL"), RedisString(key)])
        return self
    }
}
