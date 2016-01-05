//
//  SwiftRedisMisc.swift
//  Phoenix
//
//  Created by Samuel Kallner on 05/01/2016.
//  Copyright © 2016 Daniel Firsht. All rights reserved.
//

import sys

import Foundation


public class RedisString {
    private let data: NSData
    
    public init(_ data: NSData) {
        self.data = data
    }
    
    public convenience init(_ value: String) {
        self.init(StringUtils.toUtf8String(value)!)
    }
    
    public convenience init(_ value: Int) {
        self.init(String(value))
    }
    
    public convenience init(_ value: Double) {
        self.init(String(value))
    }
    
    public var asData: NSData { return data }
    public var asString: String { return NSString(data: data, encoding: NSUTF8StringEncoding) as! String }
    public var asInteger: Int { return Int(self.asString)! }
    public var asDouble: Double { return Double(self.asString)! }
}

extension RedisString: Equatable {}

public func == (lhs: RedisString, rhs: RedisString) -> Bool {
    return lhs.data == rhs.data
}


public enum RedisResponse {
    case Array([RedisResponse])
    case Error(String)
    case IntegerValue(Int64)
    case Nil
    case Status(String)
    case StringValue(RedisString)
}

extension RedisResponse: Equatable {}

public func == (lhs: RedisResponse, rhs: RedisResponse) -> Bool {
    switch (lhs, rhs) {
    case (.Array(let lhv), .Array(let rhv)):
        return lhv == rhv
    case (.Error, .Error):
        return true
    case (.IntegerValue(let lhv), .IntegerValue(let rhv)):
        return lhv == rhv
    case (.Nil, .Nil):
        return true
    case (.Status(let lhv), .Status(let rhv)):
        return lhv == rhv
    case (.StringValue(let lhv), .StringValue(let rhv)):
        return lhv == rhv
    default:
        return false
    }
}