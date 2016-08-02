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


public class RedisString: CustomStringConvertible {
    private let data: Data

    public init(_ data: Data) {
        self.data = data
    }
    
    public convenience init(_ value: String) {
        // String.data(encoding:) will return nil on Linux on an empty string
        // eventually this needs to be changed in swift-corelibs-foundation
        // the "?? Data()" ensures that an empty Data is added if the "arg" is empty
        let data = value.data(using: String.Encoding.utf8) ?? Data()
        self.init(data)
    }

    public convenience init(_ value: Int) {
        self.init(String(value))
    }

    public convenience init(_ value: Double) {
        self.init(String(value))
    }

    public var asData: Data { return data }
    public var asString: String {
        return String(data: data, encoding: String.Encoding.utf8)!
    }
    public var asInteger: Int { return Int(self.asString)! }
    public var asDouble: Double { return Double(self.asString)! }

    public var description: String {
        let text = String(data: data, encoding: String.Encoding.utf8)
        return text ?? "A non-UTF-8 string"
    }
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
    
    public var asArray: [RedisResponse]? {
        let result: [RedisResponse]?
        switch(self) {
        case .Array(let responses):
            result = responses
        default:
            result = nil
        }
        return result
    }
    
    public var asError: String? {
        let result: String?
        switch(self) {
        case .Error(let str):
            result = str
        default:
            result = nil
        }
        return result
    }
    
    public var asInteger: Int64? {
        let result: Int64?
        switch(self) {
            case .IntegerValue(let num):
                result = num
            default:
                result = nil
        }
        return result
    }
    
    public var asStatus: String? {
        let result: String?
        switch(self) {
        case .Status(let str):
            result = str
        default:
            result = nil
        }
        return result
    }
    
    public var asString: RedisString? {
        let result: RedisString?
        switch(self) {
        case .StringValue(let str):
            result = str
        default:
            result = nil
        }
        return result
    }
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
