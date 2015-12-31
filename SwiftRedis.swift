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
    
    public func auth(pswd: String, callback: (NSError?) -> Void) {
        issueCommand("AUTH", pswd) {(response: RedisResponse) in
            let (_, error) = self.redisOkResponseHandler(response, nilOk: false)
            callback(error)
        }
    }
    
    public func select(db: Int, callback: (NSError?) -> Void) {
        issueCommand("SELECT", String(db)) {(response: RedisResponse) in
            let (_, error) = self.redisOkResponseHandler(response, nilOk: false)
            callback(error)
        }
    }
    
    public func ping(pingStr: String?=nil, callback: (NSError?) -> Void) {
        var command = ["PING"]
        if  let pingStr = pingStr  {
            command.append(pingStr)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            switch(response) {
            case .Status(let str):
                if  str == "PONG"  {
                    callback(nil)
                }
                else {
                    callback(self.createError("Status result other than 'PONG' received from Redis (\(str))", code: 2))
                }
            case .StringValue(let str):
                if  pingStr != nil  &&  pingStr! == str {
                    callback(nil)
                }
                else {
                    callback(self.createError("String result other than '\(pingStr)' received from Redis (\(str))", code: 2))
                }
            case .Error(let error):
                callback(self.createError("Error: \(error)", code: 1))
            default:
                callback(self.createUnexpectedResponseError(response))
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
    
    public func set(key: String, value: String, exists: Bool?=nil, expiresIn: NSTimeInterval?=nil, callback: (Bool, error: NSError?) -> Void) {
        var command = ["SET", key, value]
        if  let exists = exists  {
            command.append(exists ? "XX" : "NX")
        }
        if  let expiresIn = expiresIn  {
            command.append("PX")
            command.append(String(Int(expiresIn * 1000.0)))
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            let (ok, error) = self.redisOkResponseHandler(response)
            callback(ok, error: error)
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
    
    public func mget(keys: String..., callback: ([String?]?, error: NSError?) -> Void) {
        var command = ["MGET"]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            var error: NSError? = nil
            var strings = [String?]()
            
            switch(response) {
                case .Array(let responses):
                    for innerResponse in responses {
                        switch(innerResponse) {
                            case .StringValue(let str):
                                strings.append(str)
                            case .Nil:
                                strings.append(nil)
                            default:
                                error = self.createUnexpectedResponseError(response)
                        }
                    }
                case .Error(let err):
                    error = self.createError("Error: \(err)", code: 1)
                default:
                    error = self.createUnexpectedResponseError(response)
            }
            callback(error == nil ? strings : nil, error: error)
        }
    }
    
    public func mset(keyValuePairs: (String, String)..., callback: (NSError?) -> Void) {
        msetArrayOfKeyValues(keyValuePairs, callback: callback)
    }
    
    public func msetArrayOfKeyValues(keyValuePairs: [(String, String)], callback: (NSError?) -> Void) {
        var command = ["MSET"]
        for (key, value) in keyValuePairs {
            command.append(key)
            command.append(value)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            let (_, error) = self.redisOkResponseHandler(response, nilOk: false)
            callback(error)
        }
    }
    
    public func msetnx(keyValuePairs: (String, String)..., callback: (Bool, error: NSError?) -> Void) {
        msetnxArrayOfKeyValues(keyValuePairs, callback: callback)
    }
    
    public func msetnxArrayOfKeyValues(keyValuePairs: [(String, String)], callback: (Bool, error: NSError?) -> Void) {
        var command = ["MSETNX"]
        for (key, value) in keyValuePairs {
            command.append(key)
            command.append(value)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    public func exists(keys: String..., callback: (Int?, error: NSError?) -> Void) {
        var command = ["EXISTS"]
        for key in keys {
            command.append(key)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    public func move(key: String, toDB: Int, callback: (Bool, error: NSError?) -> Void) {
        issueCommand("MOVE", key, String(toDB)) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    public func rename(key: String, newKey: String, exists: Bool=true, callback: (Bool, error: NSError?) -> Void) {
        if  exists  {
            issueCommand("RENAME", key, newKey) {(response: RedisResponse) in
                let (renamed, error) = self.redisOkResponseHandler(response, nilOk: false)
                callback(renamed, error: error)
            }
        }
        else {
            issueCommand("RENAMENX", key, newKey) {(response: RedisResponse) in
                self.redisBoolResponseHandler(response, callback: callback)
            }
        }
    }
    
    public func expire(key: String, inTime: NSTimeInterval, callback: (Bool, error: NSError?) -> Void) {
        issueCommand("PEXPIRE", key, String(Int(inTime * 1000.0))) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    public func expire(key: String, atDate: NSDate, callback: (Bool, error: NSError?) -> Void) {
        issueCommand("PEXPIREAT", key, String(Int(atDate.timeIntervalSince1970 * 1000.0))) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    public func persist(key: String, callback: (Bool, error: NSError?) -> Void) {
        issueCommand("PERSIST", key) {(response: RedisResponse) in
            self.redisBoolResponseHandler(response, callback: callback)
        }
    }
    
    public func ttl(key: String, callback: (NSTimeInterval?, error: NSError?) -> Void) {
        issueCommand("PTTL", key) {(response: RedisResponse) in
            switch(response) {
                case .IntegerValue(let num):
                    if  num >= 0  {
                        callback(NSTimeInterval(Double(num)/1000.0), error: nil)
                    }
                    else {
                        callback(NSTimeInterval(num), error: nil)
                    }
                case .Error(let error):
                    callback(nil, error: self.createError("Error: \(error)", code: 1))
                default:
                    callback(nil, error: self.createUnexpectedResponseError(response))
            }
        }
    }
    
    
    // *********************
    //  Base API functions *
    // *********************
    
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
            
            response = redisReplyToRedisResponse(replyPtr.memory)
        }
        else {
            response = RedisResponse.Error("Not connected to Redis server")
        }
        callback(response)
    }
    
    // *******************
    //  Helper functions *
    // *******************
    
    private func redisReplyToRedisResponse(reply: redisReply) -> RedisResponse {
        var response: RedisResponse
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
                var arrayResponse = [RedisResponse]()
                for idx in 0..<reply.elements {
                    arrayResponse.append(redisReplyToRedisResponse(reply.element[idx].memory))
                }
                response = RedisResponse.Array(arrayResponse)
            case REDIS_REPLY_INTEGER:
                response = RedisResponse.IntegerValue(reply.integer)
            case REDIS_REPLY_NIL:
                response = RedisResponse.Nil
            default:
                response = RedisResponse.Error("Invalid reply from Redis server")
        }
        return response
    }
    
    private func redisBoolResponseHandler(response: RedisResponse, callback: (Bool, error: NSError?) -> Void) {
        switch(response) {
            case .IntegerValue(let num):
                if  num == 0  || num == 1 {
                    callback(num == 1, error: nil)
                }
                else {
                    callback(false, error: createUnexpectedResponseError(response))
                }
            case .Error(let error):
                callback(false, error: createError("Error: \(error)", code: 1))
            default:
                callback(false, error: createUnexpectedResponseError(response))
        }
    }
    
    private func redisIntegerResponseHandler(response: RedisResponse, callback: (Int?, error: NSError?) -> Void) {
        switch(response) {
        case .IntegerValue(let num):
            callback(Int(num), error: nil)
        case .Error(let error):
            callback(nil, error: createError("Error: \(error)", code: 1))
        default:
            callback(nil, error: createUnexpectedResponseError(response))
        }
    }
    
    private func redisOkResponseHandler(response: RedisResponse, nilOk: Bool=true) -> (Bool, NSError?) {
        switch(response) {
            case .Status(let str):
                if  str == "OK"  {
                    return (true, nil)
                }
                else {
                    return (false, createError("Status result other than 'OK' received from Redis", code: 2))
            }
            case .Nil:
                return (false, nilOk ? nil : createUnexpectedResponseError(response))
            case .Error(let error):
                return (false, createError("Error: \(error)", code: 1))
            default:
                return (false, createUnexpectedResponseError(response))
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
                callback(nil, error: createUnexpectedResponseError(response))
        }
    }
    
    private func createUnexpectedResponseError(response: RedisResponse) -> NSError {
        return createError("Unexpected result received from Redis \(response)", code: 2)
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
