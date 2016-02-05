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

public class RedisMulti {
    let redis: Redis
    var queuedCommands = [[RedisString]]()
    
    init(redis: Redis) {
        self.redis = redis
    }
    
    // ************************
    //  Commands to be Queued *
    // ************************
    
    
    public func append(key: String, value: String) -> RedisMulti {
        queuedCommands.append([RedisString("APPEND"), RedisString(key), RedisString(value)])
        return self
    }
    
    public func bitcount(key: String) -> RedisMulti {
        queuedCommands.append([RedisString("BITCOUNT"), RedisString(key)])
        return self
    }
    
    public func bitcount(key: String, start: Int, end: Int) -> RedisMulti {
        queuedCommands.append([RedisString("BITCOUNT"), RedisString(key), RedisString(start), RedisString(end)])
        return self
    }
    
    public func bitop(destKey: String, and: String...) -> RedisMulti {
        var command = [RedisString("BITOP"), RedisString("AND"), RedisString(destKey)]
        for key in and {
            command.append(RedisString(key))
        }
        queuedCommands.append(command)
        return self
    }
    
    public func bitop(destKey: String, not: String) -> RedisMulti {
        queuedCommands.append([RedisString("BITOP"), RedisString("NOT"), RedisString(destKey), RedisString(not)])
        return self
    }
    
    public func bitop(destKey: String, or: String...) -> RedisMulti {
        var command = [RedisString("BITOP"), RedisString("OR"), RedisString(destKey)]
        for key in or {
            command.append(RedisString(key))
        }
        queuedCommands.append(command)
        return self
    }
    
    public func bitop(destKey: String, xor: String...) -> RedisMulti {
        var command = [RedisString("BITOP"), RedisString("XOR"), RedisString(destKey)]
        for key in xor {
            command.append(RedisString(key))
        }
        queuedCommands.append(command)
        return self
    }
    
    public func bitpos(key: String, bit:Bool) -> RedisMulti {
        queuedCommands.append([RedisString("BITPOS"), RedisString(key), RedisString(bit ? "1" : "0")])
        return self
    }
    
    public func bitpos(key: String, bit:Bool, start: Int) -> RedisMulti {
        queuedCommands.append([RedisString("BITPOS"), RedisString(key), RedisString(bit ? "1" : "0"), RedisString(start)])
        return self
    }
    
    public func bitpos(key: String, bit:Bool, start: Int, end: Int) -> RedisMulti {
        queuedCommands.append([RedisString("BITPOS"), RedisString(key), RedisString(bit ? "1" : "0"), RedisString(start), RedisString(end)])
        return self
    }
    
    public func decr(key: String, by: Int=1) -> RedisMulti {
        queuedCommands.append([RedisString("DECRBY"), RedisString(key), RedisString(by)])
        return self
    }
    
    public func del(keys: String...) -> RedisMulti {
        var command = [RedisString("DEL")]
        for key in keys {
            command.append(RedisString(key))
        }
        queuedCommands.append(command)
        return self
    }
    
    public func exists(keys: String...) -> RedisMulti {
        var command = [RedisString("EXISTS")]
        for key in keys {
            command.append(RedisString(key))
        }
        queuedCommands.append(command)
        return self
    }
    
    public func expire(key: String, inTime: NSTimeInterval) -> RedisMulti {
        queuedCommands.append([RedisString("PEXPIRE"), RedisString(key), RedisString(Int(inTime * 1000.0))])
        return self
    }
    
    public func expire(key: String, atDate: NSDate) -> RedisMulti {
        queuedCommands.append([RedisString("PEXPIREAT"), RedisString(key), RedisString(Int(atDate.timeIntervalSince1970 * 1000.0))])
        return self
    }
    
    public func get(key: String) -> RedisMulti {
        queuedCommands.append([RedisString("GET"), RedisString(key)])
        return self
    }
    
    public func getbit(key: String, offset: Int) -> RedisMulti {
        queuedCommands.append([RedisString("GETBIT"), RedisString(key), RedisString(offset)])
        return self
    }
    
    public func getrange(key: String, start: Int, end: Int) -> RedisMulti {
        queuedCommands.append([RedisString("GETRANGE"), RedisString(key), RedisString(start), RedisString(end)])
        return self
    }
    
    public func getSet(key: String, value: String) -> RedisMulti {
        queuedCommands.append([RedisString("GETSET"), RedisString(key), RedisString(value)])
        return self
    }
    
    public func getSet(key: String, value: RedisString) -> RedisMulti {
        queuedCommands.append([RedisString("GETSET"), RedisString(key), value])
        return self
    }
    
    public func hdel(key: String, fields: String...) -> RedisMulti {
        var command = [RedisString("HDEL"), RedisString(key)]
        for field in fields {
            command.append(RedisString(field))
        }
        queuedCommands.append(command)
        return self
    }
    
    public func hexists(key: String, field: String) -> RedisMulti {
        queuedCommands.append([RedisString("HEXISTS"), RedisString(key), RedisString(field)])
        return self
    }
    
    public func hget(key: String, field: String) -> RedisMulti {
        queuedCommands.append([RedisString("HGET"), RedisString(key), RedisString(field)])
        return self
    }
    
    public func hgetall(key: String) -> RedisMulti {
        queuedCommands.append([RedisString("HGETALL"), RedisString(key)])
        return self
    }
    
    public func hincr(key: String, field: String, by: Int) -> RedisMulti {
        queuedCommands.append([RedisString("HINCRBY"), RedisString(key), RedisString(field), RedisString(by)])
        return self
    }
    
    public func hincr(key: String, field: String, byFloat: Float) -> RedisMulti {
        queuedCommands.append([RedisString("HINCRBYFLOAT"), RedisString(key), RedisString(field), RedisString(Double(byFloat))])
        return self
    }
    
    public func hkeys(key: String) -> RedisMulti {
        queuedCommands.append([RedisString("HKEYS"), RedisString(key)])
        return self
    }
    
    public func hlen(key: String) -> RedisMulti {
        queuedCommands.append([RedisString("HLEN"), RedisString(key)])
        return self
    }
    
    public func hmget(key: String, fields: String...) -> RedisMulti {
        var command = [RedisString("HMGET"), RedisString(key)]
        for field in fields {
            command.append(RedisString(field))
        }
        queuedCommands.append(command)
        return self
    }
    
    public func hmset(key: String, fieldValuePairs: (String, String)...) -> RedisMulti {
        return hmsetArrayOfKeyValues(key, fieldValuePairs: fieldValuePairs)
    }
    
    public func hmsetArrayOfKeyValues(key: String, fieldValuePairs: [(String, String)]) -> RedisMulti {
        var command = [RedisString("HMSET"), RedisString(key)]
        for (field, value) in fieldValuePairs {
            command.append(RedisString(field))
            command.append(RedisString(value))
        }
        queuedCommands.append(command)
        return self
    }
    
    public func hmset(key: String, fieldValuePairs: (String, RedisString)...) -> RedisMulti {
        return hmsetArrayOfKeyValues(key, fieldValuePairs: fieldValuePairs)
    }
    
    public func hmsetArrayOfKeyValues(key: String, fieldValuePairs: [(String, RedisString)]) -> RedisMulti {
        var command = [RedisString("HMSET"), RedisString(key)]
        for (field, value) in fieldValuePairs {
            command.append(RedisString(field))
            command.append(value)
        }
        queuedCommands.append(command)
        return self
    }
    
    public func hset(key: String, field: String, value: String, exists: Bool=true) -> RedisMulti {
        queuedCommands.append([RedisString(exists ? "HSET" : "HSETNX"), RedisString(key), RedisString(field), RedisString(value)])
        return self
    }
    
    public func hset(key: String, field: String, value: RedisString, exists: Bool=true) -> RedisMulti {
        queuedCommands.append([RedisString(exists ? "HSET" : "HSETNX"), RedisString(key), RedisString(field), value])
        return self
    }
    
    public func hstrlen(key: String, field: String) -> RedisMulti {
        queuedCommands.append([RedisString("HSTRLEN"), RedisString(key), RedisString(field)])
        return self
    }
    
    public func hvals(key: String) -> RedisMulti {
        queuedCommands.append([RedisString("HVALS"), RedisString(key)])
        return self
    }
    
    public func incr(key: String, by: Int=1) -> RedisMulti {
        queuedCommands.append([RedisString("INCRBY"), RedisString(key), RedisString(by)])
        return self
    }
    
    public func incr(key: String, byFloat: Float) -> RedisMulti {
        queuedCommands.append([RedisString("INCRBYFLOAT"), RedisString(key), RedisString(Double(byFloat))])
        return self
    }
    
    public func mget(keys: String...) -> RedisMulti {
        var command = [RedisString("MGET")]
        for key in keys {
            command.append(RedisString(key))
        }
        queuedCommands.append(command)
        return self
    }
    
    public func move(key: String, toDB: Int) -> RedisMulti {
        queuedCommands.append([RedisString("MOVE"), RedisString(key), RedisString(toDB)])
        return self
    }
    
    public func mset(keyValuePairs: (String, String)..., exists: Bool=true) -> RedisMulti {
        return msetArrayOfKeyValues(keyValuePairs, exists: exists)
    }
    
    public func msetArrayOfKeyValues(keyValuePairs: [(String, String)], exists: Bool=true) -> RedisMulti {
        var command = [RedisString(exists ? "MSET" : "MSETNX")]
        for (key, value) in keyValuePairs {
            command.append(RedisString(key))
            command.append(RedisString(value))
        }
        queuedCommands.append(command)
        return self
    }
    
    public func mset(keyValuePairs: (String, RedisString)..., exists: Bool=true) -> RedisMulti {
        return msetArrayOfKeyValues(keyValuePairs, exists: exists)
    }
    
    public func msetArrayOfKeyValues(keyValuePairs: [(String, RedisString)], exists: Bool=true) -> RedisMulti {
        var command = [RedisString(exists ? "MSET" : "MSETNX")]
        for (key, value) in keyValuePairs {
            command.append(RedisString(key))
            command.append(value)
        }
        queuedCommands.append(command)
        return self
    }
    
    public func persist(key: String) -> RedisMulti {
        queuedCommands.append([RedisString("PERSIST"), RedisString(key)])
        return self
    }
    
    public func rename(key: String, newKey: String, exists: Bool=true) -> RedisMulti {
        queuedCommands.append([RedisString(exists ? "RENAME" : "RENAMENX"), RedisString(key), RedisString(newKey)])
        return self
    }
    
    public func select(db: Int) -> RedisMulti {
        queuedCommands.append([RedisString("SELECT"), RedisString(db)])
        return self
    }
    
    public func set(key: String, value: String, exists: Bool?=nil, expiresIn: NSTimeInterval?=nil) -> RedisMulti {
        var command = [RedisString("SET"), RedisString(key), RedisString(value)]
        if  let exists = exists  {
            command.append(RedisString(exists ? "XX" : "NX"))
        }
        if  let expiresIn = expiresIn  {
            command.append(RedisString("PX"))
            command.append(RedisString(Int(expiresIn * 1000.0)))
        }
        queuedCommands.append(command)
        return self
    }
    
    public func set(key: String, value: RedisString, exists: Bool?=nil, expiresIn: NSTimeInterval?=nil) -> RedisMulti {
        var command = [RedisString("SET"), RedisString(key), value]
        if  let exists = exists  {
            command.append(RedisString(exists ? "XX" : "NX"))
        }
        if  let expiresIn = expiresIn  {
            command.append(RedisString("PX"))
            command.append(RedisString(Int(expiresIn * 1000.0)))
        }
        queuedCommands.append(command)
        return self
    }
    
    public func setbit(key: String, offset: Int, value: Bool) -> RedisMulti {
        queuedCommands.append([RedisString("SETBIT"), RedisString(key), RedisString(offset), RedisString(value ? "1" : "0")])
        return self
    }
    
    public func setrange(key: String, offset: Int, value: String) -> RedisMulti {
        queuedCommands.append([RedisString("SETRANGE"), RedisString(key), RedisString(offset), RedisString(value)])
        return self
    }
    
    public func strlen(key: String) -> RedisMulti {
        queuedCommands.append([RedisString("STRLEN"), RedisString(key)])
        return self
    }
    
    public func ttl(key: String) -> RedisMulti {
        queuedCommands.append([RedisString("PTTL"), RedisString(key)])
        return self
    }
    
    
    // **********************
    //  Run the transaction *
    // **********************
    
    public func exec(callback: (RedisResponse) -> Void) {
        redis.issueCommand("MULTI") {(multiResponse: RedisResponse) in
            switch(multiResponse) {
                case .Status(let status):
                    if  status == "OK"  {
                        var idx = -1
                        var handler: ((RedisResponse) -> Void)? = nil
                        
                        let actualHandler = {(response: RedisResponse) in
                            switch(response) {
                                case .Status(let status):
                                    if  status == "QUEUED"  {
                                        idx += 1
                                        if  idx < self.queuedCommands.count  {
                                            // Queue another command to Redis
                                            self.redis.issueCommandInArray(self.queuedCommands[idx], callback: handler!)
                                        }
                                        else {
                                            self.redis.issueCommand("EXEC", callback: callback)
                                        }
                                    }
                                    else {
                                        self.execQueueingFailed(response, callback: callback)
                                    }
                                default:
                                    self.execQueueingFailed(response, callback: callback)
                            }
                        }
                        handler = actualHandler
                        
                        actualHandler(RedisResponse.Status("QUEUED"))
                    }
                    else {
                        callback(multiResponse)
                    }
                default:
                    callback(multiResponse)
            }
        }
    }
    
    private func execQueueingFailed(response: RedisResponse, callback: (RedisResponse) -> Void) {
        redis.issueCommand("DISCARD") {(_: RedisResponse) in
            callback(response)
        }
    }
}
