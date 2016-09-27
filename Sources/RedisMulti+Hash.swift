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

/// Extend RedisMulti by adding the Hash operations
extension RedisMulti {

    @discardableResult
    public func hdel(_ key: String, fields: String...) -> RedisMulti {
        var command = [RedisString("HDEL"), RedisString(key)]
        for field in fields {
            command.append(RedisString(field))
        }
        queuedCommands.append(command)
        return self
    }
    
    @discardableResult
    public func hexists(_ key: String, field: String) -> RedisMulti {
        queuedCommands.append([RedisString("HEXISTS"), RedisString(key), RedisString(field)])
        return self
    }
    
    @discardableResult
    public func hget(_ key: String, field: String) -> RedisMulti {
        queuedCommands.append([RedisString("HGET"), RedisString(key), RedisString(field)])
        return self
    }
    
    @discardableResult
    public func hgetall(_ key: String) -> RedisMulti {
        queuedCommands.append([RedisString("HGETALL"), RedisString(key)])
        return self
    }
    
    @discardableResult
    public func hincr(_ key: String, field: String, by: Int) -> RedisMulti {
        queuedCommands.append([RedisString("HINCRBY"), RedisString(key), RedisString(field), RedisString(by)])
        return self
    }
    
    @discardableResult
    public func hincr(_ key: String, field: String, byFloat: Float) -> RedisMulti {
        queuedCommands.append([RedisString("HINCRBYFLOAT"), RedisString(key), RedisString(field), RedisString(Double(byFloat))])
        return self
    }
    
    @discardableResult
    public func hkeys(_ key: String) -> RedisMulti {
        queuedCommands.append([RedisString("HKEYS"), RedisString(key)])
        return self
    }
    
    @discardableResult
    public func hlen(_ key: String) -> RedisMulti {
        queuedCommands.append([RedisString("HLEN"), RedisString(key)])
        return self
    }
    
    @discardableResult
    public func hmget(_ key: String, fields: String...) -> RedisMulti {
        var command = [RedisString("HMGET"), RedisString(key)]
        for field in fields {
            command.append(RedisString(field))
        }
        queuedCommands.append(command)
        return self
    }
    
    @discardableResult
    public func hmset(_ key: String, fieldValuePairs: (String, String)...) -> RedisMulti {
        return hmsetArrayOfKeyValues(key, fieldValuePairs: fieldValuePairs)
    }
    
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
    
    @discardableResult
    public func hmset(_ key: String, fieldValuePairs: (String, RedisString)...) -> RedisMulti {
        return hmsetArrayOfKeyValues(key, fieldValuePairs: fieldValuePairs)
    }
    
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
    
    @discardableResult
    public func hset(_ key: String, field: String, value: String, exists: Bool=true) -> RedisMulti {
        queuedCommands.append([RedisString(exists ? "HSET" : "HSETNX"), RedisString(key), RedisString(field), RedisString(value)])
        return self
    }
    
    @discardableResult
    public func hset(_ key: String, field: String, value: RedisString, exists: Bool=true) -> RedisMulti {
        queuedCommands.append([RedisString(exists ? "HSET" : "HSETNX"), RedisString(key), RedisString(field), value])
        return self
    }
    
    @discardableResult
    public func hstrlen(_ key: String, field: String) -> RedisMulti {
        queuedCommands.append([RedisString("HSTRLEN"), RedisString(key), RedisString(field)])
        return self
    }
    
    @discardableResult
    public func hvals(_ key: String) -> RedisMulti {
        queuedCommands.append([RedisString("HVALS"), RedisString(key)])
        return self
    }
}
