//
//  CommonUtils.swift
//  Phoenix
//
//  Created by Samuel Kallner on 25/12/2015.
//  Copyright © 2015 Daniel Firsht. All rights reserved.
//

import Foundation

import SwiftRedis


let redis = Redis()

func connectRedis (callback: (NSError?) -> Void) {
    if !redis.connected  {
        redis.connect("localhost", port: 6379, callback: callback)
    }
    else {
        callback(nil)
    }
}

// Dummy class for test framework
class CommonUtils { }
