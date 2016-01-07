//
//  SwiftRedisMulti.swift
//  Phoenix
//
//  Created by Samuel Kallner on 05/01/2016.
//  Copyright © 2016 Daniel Firsht. All rights reserved.
//

import Foundation

public class SwiftRedisMulti {
    let redis: SwiftRedis
    var queuedCommands = [[RedisString]]()
    
    init(redis: SwiftRedis) {
        self.redis = redis
    }
    
    // ************************
    //  Commands to be Queued *
    // ************************
    
    
    public func decr(key: String, by: Int=1) -> SwiftRedisMulti {
        queuedCommands.append([RedisString("DECRBY"), RedisString(key), RedisString(by)])
        return self
    }
    
    public func del(keys: String...) -> SwiftRedisMulti {
        var command = [RedisString("DEL")]
        for key in keys {
            command.append(RedisString(key))
        }
        queuedCommands.append(command)
        return self
    }
    
    public func get(key: String) -> SwiftRedisMulti {
        queuedCommands.append([RedisString("GET"), RedisString(key)])
        return self
    }
    
    public func getSet(key: String, value: String) -> SwiftRedisMulti {
        queuedCommands.append([RedisString("GETSET"), RedisString(key), RedisString(value)])
        return self
    }
    
    public func getSet(key: String, value: RedisString) -> SwiftRedisMulti {
        queuedCommands.append([RedisString("GETSET"), RedisString(key), value])
        return self
    }
    
    public func incr(key: String, by: Int=1) -> SwiftRedisMulti {
        queuedCommands.append([RedisString("INCRBY"), RedisString(key), RedisString(by)])
        return self
    }
    
    public func incr(key: String, byFloat: Float) -> SwiftRedisMulti {
        queuedCommands.append([RedisString("INCRBYFLOAT"), RedisString(key), RedisString(Double(byFloat))])
        return self
    }
    
    public func mget(keys: String...) -> SwiftRedisMulti {
        var command = [RedisString("MGET")]
        for key in keys {
            command.append(RedisString(key))
        }
        queuedCommands.append(command)
        return self
    }
    
    public func mset(keyValuePairs: (String, String)..., exists: Bool=true) -> SwiftRedisMulti {
        return msetArrayOfKeyValues(keyValuePairs, exists: exists)
    }
    
    public func msetArrayOfKeyValues(keyValuePairs: [(String, String)], exists: Bool=true) -> SwiftRedisMulti {
        var command = [RedisString(exists ? "MSET" : "MSETNX")]
        for (key, value) in keyValuePairs {
            command.append(RedisString(key))
            command.append(RedisString(value))
        }
        queuedCommands.append(command)
        return self
    }
    
    public func mset(keyValuePairs: (String, RedisString)..., exists: Bool=true) -> SwiftRedisMulti {
        return msetArrayOfKeyValues(keyValuePairs, exists: exists)
    }
    
    public func msetArrayOfKeyValues(keyValuePairs: [(String, RedisString)], exists: Bool=true) -> SwiftRedisMulti {
        var command = [RedisString(exists ? "MSET" : "MSETNX")]
        for (key, value) in keyValuePairs {
            command.append(RedisString(key))
            command.append(value)
        }
        queuedCommands.append(command)
        return self
    }
    
    public func select(db: Int) -> SwiftRedisMulti {
        queuedCommands.append([RedisString("SELECT"), RedisString(db)])
        return self
    }
    
    public func set(key: String, value: String, exists: Bool?=nil, expiresIn: NSTimeInterval?=nil) -> SwiftRedisMulti {
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
    
    public func set(key: String, value: RedisString, exists: Bool?=nil, expiresIn: NSTimeInterval?=nil) -> SwiftRedisMulti {
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
                                        idx++
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