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

// MARK: Redis

/// The `Redis` class represents a handle for issueing commands to a Redis server.
/// It provides a set of type safe functions for issueing those commands.
public class Redis {
    
    /// Redis Serialization Protocol handle
    private var respHandle: RedisResp?
    
    /// Whether the client is connected or not.
    /// Does not reflect state changes in the event of a disconnect.
    public var connected: Bool {
        return respHandle?.status == .connected
    }
    
    /// Initializes a `Redis` instance
    public init () {}
    
    /// Connects to a redis server
    ///
    /// - Parameter host: the server IP address.
    /// - Parameter port: port number.
    /// - Parameter callback: callback function for on completion, NSError will be nil if successful.
    public func connect(host: String, port: Int32, callback: (NSError?) -> Void) {
        respHandle = RedisResp(host: host, port: port)

        if respHandle?.status == .notConnected {
            callback(createError("Failed to connect to Redis server", code: 2))
        } else {
            callback(nil)
        }
    }
    
    /// Authenticate against the server
    ///
    /// - Parameter pswd: String for the password.
    /// - Parameter callback: callback function that is called after authenticating,
    ///                      NSError will be nil if successful.
    public func auth(_ pswd: String, callback: (NSError?) -> Void) {
        
        issueCommand("AUTH", pswd) {(response: RedisResponse) in
            let (_, error) = self.redisOkResponseHandler(response, nilOk: false)
            callback(error)
        }
    }
    
    /// Select the database to use
    ///
    /// - Parameter db: numeric index for the database.
    /// - Parameter callback: callback function for after the database is selected,
    ///                      NSError will be nil if successful.
    public func select(_ db: Int, callback: (NSError?) -> Void) {
        
        issueCommand("SELECT", String(db)) {(response: RedisResponse) in
            let (_, error) = self.redisOkResponseHandler(response, nilOk: false)
            callback(error)
        }
    }
    
    /// Ping the server to test if a connection is still alive
    ///
    /// - Parameter pingStr: String for the ping message.
    /// - Parameter callback: callback function for after the pong is received,
    ///                      NSError will be nil if successful.
    public func ping(_ pingStr: String?=nil, callback: (NSError?) -> Void) {
        
        var command = ["PING"]
        if  let pingStr = pingStr {
            command.append(pingStr)
        }
        issueCommandInArray(command) {(response: RedisResponse) in
            switch(response) {
            case .Status(let str):
                if  str == "PONG" {
                    callback(nil)
                } else {
                    callback(self.createError("Status result other than 'PONG' received from Redis (\(str))", code: 2))
                }
            case .StringValue(let str):
                if  pingStr != nil  &&  pingStr! == str.asString {
                    callback(nil)
                } else {
                    callback(self.createError("String result other than '\(String(describing: pingStr))' received from Redis (\(str))", code: 2))
                }
            case .Error(let error):
                callback(self.createError("Error: \(error)", code: 1))
            default:
                callback(self.createUnexpectedResponseError(response))
            }
        }
    }
    
    /// Echos a message
    ///
    /// - Parameter str: String for the message.
    /// - Parameter callback: callback function with the String echoed back,
    ///                      NSError will be nil if successful.
    public func echo(_ str: String, callback: (RedisString?, NSError?) -> Void) {
        
        issueCommand("ECHO", str) {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Get information and statistics about the server
    ///
    /// - Parameter callback: callback function with the response as a collection of text
    ///                      lines. NSError will be nil if successful.
    public func info(callback: (RedisString?, NSError?) -> Void) {
        issueCommand("INFO") {(response: RedisResponse) in
            self.redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Get information and statistics about the server
    ///
    /// - Parameter callback: callback function with the response as a struct
    ///                      containing some client and server information,
    ///                      NSError will be nil if successful.
    public func info(callback: (RedisInfo?, NSError?) -> Void) {
        issueCommand("INFO") {(response: RedisResponse) in
            self.redisDictionaryResponseHandler(response, callback: callback)
        }
    }
    
    /// Delete all the keys of the currently selected DB. This command never fails.
    ///
    /// - Parameter callback: a function returning the response,
    ///                      NSError will be nil if successful.
    public func flushdb(callback: (Bool, NSError?) -> Void) {
        issueCommand("FLUSHDB") { (response: RedisResponse) in
            let (ok, error) = self.redisOkResponseHandler(response)
            callback(ok, _: error)
        }
    }
    
    
    //
    //  MARK: Transaction support
    //
    
    /// Create a `RedisMulti` object in order to perform a Redis transaction
    public func multi() -> RedisMulti {
        return RedisMulti(redis: self)
    }
    
    
    //
    //  MARK: Base API functions
    //
    
    /// Issue a Redis command
    ///
    /// - Parameter stringArgs: A list of Strings making up the Redis command to issue
    /// - Parameter callback: a function returning the response in the form of a `RedisResponse`
    public func issueCommand(_ stringArgs: String..., callback: (RedisResponse) -> Void) {
        issueCommandInArray(stringArgs, callback: callback)
    }
    
    /// Issue a Redis command
    ///
    /// - Parameter stringArgs: An array of Strings making up the Redis command to issue
    /// - Parameter callback: a function returning the response in the form of a `RedisResponse`
    public func issueCommandInArray(_ stringArgs: [String], callback: (RedisResponse) -> Void) {
        guard  let respHandle = respHandle, respHandle.status == .connected else {
            callback(RedisResponse.Error("Not connected to Redis server"))
            return
        }
        
        guard  stringArgs.count > 0  else {
            callback(RedisResponse.Error("Empty command"))
            return
        }
        
        respHandle.issueCommand(stringArgs, callback: callback)
    }
    
    /// Issue a Redis command
    ///
    /// - Parameter stringArgs: A list of `RedisString` objects making up the Redis command to issue
    /// - Parameter callback: a function returning the response in the form of a `RedisResponse`
    public func issueCommand(_ stringArgs: RedisString..., callback: (RedisResponse) -> Void) {
        issueCommandInArray(stringArgs, callback: callback)
    }
    
    /// Issue a Redis command
    ///
    /// - Parameter stringArgs: An array of `RedisString` objects making up the Redis command to issue
    /// - Parameter callback: a function returning the response in the form of a `RedisResponse`
    public func issueCommandInArray(_ stringArgs: [RedisString], callback: (RedisResponse) -> Void) {
        guard  let respHandle = respHandle, respHandle.status == .connected else {
            callback(RedisResponse.Error("Not connected to Redis server"))
            return
        }
        
        guard  stringArgs.count > 0  else {
            callback(RedisResponse.Error("Empty command"))
            return
        }
        
        respHandle.issueCommand(stringArgs, callback: callback)
    }
    
    //
    //  MARK: Helper functions
    //
    
    func redisBoolResponseHandler(_ response: RedisResponse, callback: (Bool, NSError?) -> Void) {
        switch(response) {
        case .IntegerValue(let num):
            if  num == 0  || num == 1 {
                callback(num == 1, nil)
            } else {
                callback(false, _: createUnexpectedResponseError(response))
            }
        case .Error(let error):
            callback(false, _: createError("Error: \(error)", code: 1))
        default:
            callback(false, _: createUnexpectedResponseError(response))
        }
    }
    
    func redisIntegerResponseHandler(_ response: RedisResponse, callback: (Int?, NSError?) -> Void) {
        switch(response) {
        case .IntegerValue(let num):
            callback(Int(num), nil)
        case .Nil:
            callback(nil, nil)
        case .Error(let error):
            callback(nil, _: createError("Error: \(error)", code: 1))
        default:
            callback(nil, _: createUnexpectedResponseError(response))
        }
    }
    
    func redisOkResponseHandler(_ response: RedisResponse, nilOk: Bool=true) -> (Bool, NSError?) {
        switch(response) {
        case .Status(let str):
            if  str == "OK" {
                return (true, nil)
            } else {
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
    
    func redisSimpleStringResponseHandler(response: RedisResponse, callback: (String?, NSError?) -> Void) {
        switch(response) {
        case .Status(let str):
            callback(str, nil)
        case .Nil:
            callback(nil, nil)
        case .Error(let error):
            callback(nil, _: createError("Error: \(error)", code: 1))
        default:
            callback(nil, _: createUnexpectedResponseError(response))
        }
    }
    
    func redisStringResponseHandler(_ response: RedisResponse, callback: (RedisString?, NSError?) -> Void) {
        switch(response) {
        case .StringValue(let str):
            callback(str, nil)
        case .Nil:
            callback(nil, nil)
        case .Error(let error):
            callback(nil, _: createError("Error: \(error)", code: 1))
        default:
            callback(nil, _: createUnexpectedResponseError(response))
        }
    }
    
    func redisArrayResponseHandler(response: RedisResponse, callback: ([RedisResponse?]?, NSError?) -> Void) {
        var error: NSError? = nil
        var result: [RedisResponse?]?
        
        switch(response) {
        case .Array(let responses):
            result = responses
        case .Nil:
            result = nil
        case .Error(let err):
            error = self.createError("Error: \(err)", code: 1)
        default:
            error = self.createUnexpectedResponseError(response)
        }
        callback(error == nil ? result : nil, _: error)
    }
    
    func getCoordinates(from responses: [RedisResponse?]?, callback: ([(Double, Double)?]?, NSError?) -> Void) {
        guard let responses = responses else {
            callback(nil, createError("Could not get coordinates from nil response.", code: 1))
            return
        }
        var result: [(Double, Double)?]? = []
        for response in responses {
            if let response = response {
                if response == RedisResponse.Nil {
                    result?.append(nil)
                    break
                }
                guard let responseArray = response.asArray, responseArray.count == 2, let first = responseArray[0].asString?.asDouble, let second = responseArray[1].asString?.asDouble else {
                    callback(nil, createUnexpectedResponseError(response))
                    return
                }
                result?.append((first, second))
            }
        }
        callback(result, nil)
    }
    
    func redisStringArrayResponseHandler(_ response: RedisResponse, callback: ([RedisString?]?, NSError?) -> Void) {
        var error: NSError? = nil
        var result: [RedisString?]?
        
        switch(response) {
        case .Array(let responses):
            var strings = [RedisString?]()
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
            result = strings
        case .Nil:
            result = nil
        case .Error(let err):
            error = self.createError("Error: \(err)", code: 1)
        default:
            error = self.createUnexpectedResponseError(response)
        }
        callback(error == nil ? result : nil, _: error)
    }
    
    func redisStringArrayOrIntegerResponseHandler(_ response: RedisResponse, callback: ([RedisString?]?, NSError?) -> Void) {
        var error: NSError? = nil
        var result: [RedisString?]?
        
        switch(response) {
        case .Array(let responses):
            var strings = [RedisString?]()
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
            result = strings
        case .IntegerValue(let i):
            result = [RedisString(String(i))]
        case .Nil:
            result = nil
        case .Error(let err):
            error = self.createError("Error: \(err)", code: 1)
        default:
            error = self.createUnexpectedResponseError(response)
        }
        callback(error == nil ? result : nil, _: error)
    }
    
    func redisScanResponseHandler(_ response: RedisResponse, callback: (RedisString?, [RedisString?]?, NSError?) -> Void) {
        var error: NSError? = nil
        var cursor: RedisString?
        var result: [RedisString?]?
        
        switch(response) {
        case .Array(let responses):
            var strings = [RedisString?]()
            for innerResponse in responses {
                switch(innerResponse) {
                case .StringValue(let str):
                    cursor = str
                case.Array(let innerArray):
                    for val in innerArray {
                        switch(val) {
                        case .StringValue(let str):
                            strings.append(str)
                        case .Nil:
                            strings.append(nil)
                        default:
                            error = self.createUnexpectedResponseError(response)
                        }
                    }
                default:
                    error = self.createUnexpectedResponseError(response)
                }
            }
            result = strings
        case .Nil:
            result = nil
        case .Error(let err):
            error = self.createError("Error: \(err)", code: 1)
        default:
            error = self.createUnexpectedResponseError(response)
        }
        
        if(error == nil) {
            callback(cursor, result, nil)
        } else {
            callback(nil, nil, error)
        }
    }
    
    func redisDictionaryResponseHandler(_ response: RedisResponse, callback: (RedisInfo?, NSError?) -> Void) {
        switch(response) {
        case .StringValue(let str):
            callback(RedisInfo(str), nil)
        case .Nil:
            callback(nil, nil)
        case .Error(let error):
            callback(nil, _: createError("Error: \(error)", code: 1))
        default:
            callback(nil, _: createUnexpectedResponseError(response))
        }
    }
    
    func createUnexpectedResponseError(_ response: RedisResponse) -> NSError {
        return createError("Unexpected result received from Redis \(response)", code: 2)
    }
    
    func createError(_ errorMessage: String, code: Int) -> NSError {
        #if os(Linux)
            let userInfo: [String: Any]
        #else
            let userInfo: [String: String]
        #endif
        userInfo = [NSLocalizedDescriptionKey: errorMessage]
        return NSError(domain: "RedisDomain", code: code, userInfo: userInfo)
    }
    
    func createRedisError(_ redisError: String) -> NSError {
        return createError(redisError, code: 1)
    }
}
