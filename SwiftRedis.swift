//
//  SwiftRedis.swift
//  SwiftRedis
//
//  Created by Ira Rosen on 17/11/15.
//  Copyright © 2015 IBM. All rights reserved.
//

import sys

import hiredis

import Foundation

public enum RedisResponse {
    case StringValue(String)
    case Array([RedisResponse])
    case IntegerValue(Int64)
    case Status(String)
    case Error(String)
    case Nil
}

public enum RedisExpire {
    case Seconds(Int)
    case MilliSecs(Int)
}


public class SwiftRedis {
    
    private var context: redisContext?
    
    public var connected: Bool {
        return context != nil
    }
    
    public init () {
        context = nil
    }
    
    deinit {
        if context != nil {
            var contextPtr: UnsafeMutablePointer<redisContext>?
            withUnsafeMutablePointer(&context) { ptr in
                contextPtr = UnsafeMutablePointer<redisContext>(ptr)
            }
            redisFree(contextPtr!)
        }
        context = nil
    }
    
    public func connect (ipAddress: String, port: Int32, callback: (NSError?) -> Void) {
        let contextPtr = redisConnect(ipAddress, port)
        var error: NSError? = nil
        if contextPtr != nil {
            context = contextPtr.memory
            if context?.err != 0 {
                redisFree(contextPtr)
                error = createRedisError("Failed to connect to Redis server:")
                context = nil
            }
        }
        else {
            error = createError("Failed to connect to Redis server", code: 2)
        }
        callback(error)
    }
    
    public func auth(pswd: String, callback: (Bool, error: NSError?) -> Void) {
        issueCommand("AUTH", pswd) {(response: RedisResponse) in
            switch(response) {
            case .Status(let str):
                if  str == "OK"  {
                    callback(true, error: nil)
                }
                else {
                    callback(false, error: self.createError("Status result other than 'OK' received from Redis '\(str)'", code: 2))
                }
            case .Error(let error):
                callback(false, error: self.createError("Error: \(error)", code: 1))
            default:
                callback(false, error: self.createError("Unexpected result received from Redis \(response)", code: 2))
            }
        }
    }
    
    public func select(db: Int, callback: (Bool, error: NSError?) -> Void) {
        issueCommand("SELECT", String(db)) {(response: RedisResponse) in
            switch(response) {
            case .Status(let str):
                if  str == "OK"  {
                    callback(true, error: nil)
                }
                else {
                    callback(false, error: self.createError("Status result other than 'OK' received from Redis '\(str)'", code: 2))
                }
            case .Error(let error):
                callback(false, error: self.createError("Error: \(error)", code: 1))
            default:
                callback(false, error: self.createError("Unexpected result received from Redis \(response)", code: 2))
            }
        }
    }
    
    public func ping(pingStr: String?=nil, callback: (Bool, error: NSError?) -> Void) {
        var command = ["PING"]
        if  let pingStr = pingStr  {
            command.append(pingStr)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            switch(response) {
            case .Status(let str):
                if  str == "PONG"  {
                    callback(true, error: nil)
                }
                else {
                    callback(false, error: self.createError("Status result other than 'PONG' received from Redis (\(str))", code: 2))
                }
            case .StringValue(let str):
                if  pingStr != nil  &&  pingStr! == str {
                    callback(true, error: nil)
                }
                else {
                    callback(false, error: self.createError("String result other than '\(pingStr)' received from Redis (\(str))", code: 2))
                }
            case .Error(let error):
                callback(false, error: self.createError("Error: \(error)", code: 1))
            default:
                callback(false, error: self.createError("Unexpected result received from Redis \(response)", code: 2))
            }
        }
    }
    
    public func echo(str: String, callback: (String?, error: NSError?) -> Void) {
        issueCommand("ECHO", str) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    public func get(key: String, callback: (String?, error: NSError?) -> Void) {
        issueCommand("GET", key) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    public func getSet(key: String, value: String, callback: (String?, error: NSError?) -> Void) {
        issueCommand("GETSET", key, value) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    public func set(key: String, value: String, exists: Bool?=nil, expires: RedisExpire?=nil, callback: (Bool, error: NSError?) -> Void) {
        var command = ["SET", key, value]
        if  let exists = exists  {
            command.append(exists ? "XX" : "NX")
        }
        if  let expires = expires  {
            switch(expires) {
                case .Seconds(let seconds):
                    command.append("EX")
                    command.append(String(seconds))
                case .MilliSecs(let millis):
                    command.append("PX")
                    command.append(String(millis))
            }
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            switch(response) {
                case .Status(let str):
                    if  str == "OK"  {
                        callback(true, error: nil)
                    }
                    else {
                        callback(false, error: self.createError("Status result other than 'OK' received from Redis", code: 2))
                    }
                case .Nil:
                    callback(false, error: nil)
                case .Error(let error):
                    callback(false, error: self.createError("Error: \(error)", code: 1))
                default:
                    callback(false, error: self.createError("Unexpected result received from Redis \(response)", code: 2))
            }
        }
    }
    
    public func del(keys: String..., callback: (Int?, error: NSError?) -> Void) {
        var command = ["DEL"]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    public func incr(key: String, by: Int=1, callback: (Int?, error: NSError?) -> Void) {
        issueCommand("INCRBY", key, String(by)) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    public func incr(key: String, byFloat: Float, callback: (String?, error: NSError?) -> Void) {
        issueCommand("INCRBYFLOAT", key, String(byFloat)) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    public func decr(key: String, by: Int=1, callback: (Int?, error: NSError?) -> Void) {
        issueCommand("DECRBY", key, String(by)) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    public func issueCommand(stringArgs: String..., callback: (RedisResponse) -> Void) {
        issueCommandInArray(stringArgs, callback: callback)
    }
    
    // TODO: binary safe
    public func issueCommandInArray(stringArgs: [String], callback: (RedisResponse) -> Void) {
        var response: RedisResponse

        if context != nil {
            var contextPtr: UnsafeMutablePointer<redisContext>?
            withUnsafeMutablePointer(&context) { ptr in
                contextPtr = UnsafeMutablePointer<redisContext>(ptr)
            }
            
            var arrArgs = [NSData]()
            var arrOfPtrsToArgs: [UnsafePointer<Int8>] = []
            for arg in stringArgs {
                let cString = StringUtils.toNullTerminatedUtf8String(arg)!
                arrArgs.append(cString)
                arrOfPtrsToArgs.append(UnsafePointer<Int8>(cString.bytes))
            }
            
            let replyPtr = UnsafeMutablePointer<redisReply>(redisCommandArgv (contextPtr!, Int32(stringArgs.count), UnsafeMutablePointer<UnsafePointer<Int8>>(arrOfPtrsToArgs), nil))


            if replyPtr == nil {
                response = RedisResponse.Error(createRedisErrorMessage("Failed to execute Redis command:"))
                callback(response)
                // TODO               redisFree(contextPtr!)
            }
            
            let reply: redisReply = replyPtr.memory
            
            switch reply.type {
            case REDIS_REPLY_STRING:
                let data = NSData(bytesNoCopy: reply.str, length: Int(reply.len))
                response = RedisResponse.StringValue(StringUtils.fromUtf8String(data)!)
            case REDIS_REPLY_STATUS:
                let data = NSData(bytesNoCopy: reply.str, length: Int(reply.len))
                response = RedisResponse.Status(StringUtils.fromUtf8String(data)!)
            case REDIS_REPLY_ERROR:
                let data = NSData(bytesNoCopy: reply.str, length: Int(reply.len))
                response = RedisResponse.Error(StringUtils.fromUtf8String(data) ?? "")
            case REDIS_REPLY_ARRAY:
                response = RedisResponse.Array([])
                // TODO
            case REDIS_REPLY_INTEGER:
                response = RedisResponse.IntegerValue(reply.integer)
            case REDIS_REPLY_NIL:
                response = RedisResponse.Nil
            default:
                response = RedisResponse.Error("Invalid reply from Redis server")
            }
        }
        else {
            response = RedisResponse.Error("Not connected to Redis server")
        }
        callback(response)
    }
    
    private func redisIntegerResponseHandler(response: RedisResponse, callback: (Int?, error: NSError?) -> Void) {
        switch(response) {
            case .IntegerValue(let num):
                callback(Int(num), error: nil)
            case .Error(let error):
                callback(nil, error: createError("Error: \(error)", code: 1))
            default:
                callback(nil, error: createError("Non-Integer result received from Redis \(response)", code: 2))
        }
    }
    
    private func redisStringResponseHandler(response: RedisResponse, callback: (String?, error: NSError?) -> Void) {
        switch(response) {
            case .StringValue(let str):
                callback(str, error: nil)
            case .Nil:
                callback(nil, error: nil)
            case .Error(let error):
                callback(nil, error: createError("Error: \(error)", code: 1))
            default:
                callback(nil, error: createError("Non-string result received from Redis \(response)", code: 2))
        }
    }
    
    private func createError(errorMessage: String, code: Int) -> NSError {
        return NSError(domain: "RedisDomain", code: code, userInfo: [NSLocalizedDescriptionKey : errorMessage])
    }
    
    private func createRedisError(swiftRedisError: String) -> NSError {
        let errorMessage = createRedisErrorMessage(swiftRedisError)
        return createError(errorMessage, code: 1)
    }
    
    private func createRedisErrorMessage(swiftRedisError: String) -> String {
        if  context != nil  {
            var errPtr : UnsafePointer<Int8> = nil
            withUnsafePointer(&context!.errstr) { ptr in
                errPtr = UnsafePointer<Int8>(ptr)
            }
            return "\(swiftRedisError) \(String(UTF8String: errPtr)!)"
        }
        else {
            return swiftRedisError
        }
    }
    
}
