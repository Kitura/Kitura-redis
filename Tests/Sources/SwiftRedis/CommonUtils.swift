//
//  CommonUtils.swift
//  Phoenix
//
//  Created by Samuel Kallner on 25/12/2015.
//  Copyright © 2015 Daniel Firsht. All rights reserved.
//

#if os(Linux)
    import Glibc
#elseif os(OSX)
    import Darwin
#endif

import Foundation

import SwiftRedis


let redis = Redis()

func connectRedis (callback: (NSError?) -> Void) {
    if !redis.connected  {
        var host = "localhost"
        let hostCStr = getenv("SWIFT_REDIS_HOST") 
        if  hostCStr != nil {
            if  let hostStr = NSString(UTF8String: hostCStr) {
                host = hostStr.bridge()
            }
        }
        redis.connect(host, port: 6379, callback: callback)
    }
    else {
        callback(nil)
    }
}

// Dummy class for test framework
class CommonUtils { }
