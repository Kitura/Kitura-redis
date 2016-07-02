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

import KituraSys
import Socket

import Foundation

internal enum RedisRespStatus {
    case notConnected, connected, error
}

internal class RedisResp {
    ///
    /// Socket used to talk with the server
    private var socket: Socket?

    // Mark: Prebuilt constant UTF8 strings (these strings are all proper UTF-8 strings)
    private static let asterisk = StringUtils.toUtf8String("*")!
    private static let colon = StringUtils.toUtf8String(":")!
    private static let crLf = StringUtils.toUtf8String("\r\n")!
    private static let dollar = StringUtils.toUtf8String("$")!
    private static let minus = StringUtils.toUtf8String("-")!
    private static let plus = StringUtils.toUtf8String("+")!

    ///
    /// State of connection
    ///
    internal private(set) var status = RedisRespStatus.notConnected

    internal init(host: String, port: Int32) {
        do {
            socket = try Socket.create()
            try socket!.connect(to: host, port: port)
            status = .connected
        }
        catch {
            status = .notConnected
        }
    }

    internal func issueCommand(_ stringArgs: [String], callback: (RedisResponse) -> Void) {
        guard let socket = socket else { return }

        let buffer = NSMutableData()
        buffer.append(RedisResp.asterisk)
        add(stringArgs.count, to: buffer)
        buffer.append(RedisResp.crLf)

        for arg in stringArgs {
            // NSString.data(encoding:) which is called by StringUtils.toUtf8String will return nil on Linux on an empty string
            // eventually this needs to be changed in swift-corelibs-foundation
            // the "?? NSData()" ensures that an empty NSData is added if the "arg" is empty
            addAsBulkString(StringUtils.toUtf8String(arg) ?? NSData(), to: buffer)
        }

        do {
            try socket.write(from: buffer)

            readAndParseResponse(callback: callback)
        }
        catch let error as Socket.Error {
            callback(RedisResponse.Error("Error sending command to Redis server. Error=\(error.description)"))
        }
        catch {
            callback(RedisResponse.Error("Error sending command to Redis server. Unknown error"))
        }
    }

    internal func issueCommand(_ stringArgs: [RedisString], callback: (RedisResponse) -> Void) {
        guard let socket = socket else { return }

        let buffer = NSMutableData()

        buffer.append(RedisResp.asterisk)
        add(stringArgs.count, to: buffer)
        buffer.append(RedisResp.crLf)

        for arg in stringArgs {
            addAsBulkString(arg.asData, to: buffer)
        }

        do {
            try socket.write(from: buffer)

            readAndParseResponse(callback: callback)
        }
        catch let error as Socket.Error {
            callback(RedisResponse.Error("Error sending command to Redis server. Error=\(error.description)"))
        }
        catch {
            callback(RedisResponse.Error("Error sending command to Redis server. Unknown error."))
        }
    }

    // Mark: Parsing Functions

    private func readAndParseResponse(callback: (RedisResponse) -> Void) {
        let buffer = NSMutableData()
        var offset = 0
        var response: RedisResponse = RedisResponse.Nil

        do {
            (response, offset) = try parseByPrefix(buffer, from: offset)
            callback(response)
        }
        catch let error as Socket.Error {
            callback(RedisResponse.Error("Error reading from the Redis server. Error=\(error.description)"))
        }
        catch let error as RedisRespError {
            callback(RedisResponse.Error("Error reading from the Redis server. Error=\(error.description)"))
        }
        catch {
            callback(RedisResponse.Error("Error reading from the Redis server. Unknown error"))
        }
    }

    private func parseByPrefix(_ buffer: NSMutableData, from: Int) throws -> (RedisResponse, Int) {
        var response: RedisResponse

        var (matched, offset) = try compare(buffer, at: from, with: RedisResp.plus)
        if  matched {
            (response, offset) = try parseSimpleString(buffer, offset: offset)
        }
        else {
            (matched, offset) = try compare(buffer, at: from, with: RedisResp.colon)
            if  matched {
                (response, offset) = try parseInteger(buffer, offset: offset)
            }
            else {
                (matched, offset) = try compare(buffer, at: from, with: RedisResp.dollar)
                if  matched {
                    (response, offset) = try parseBulkString(buffer, offset: offset)
                }
                else {
                    (matched, offset) = try compare(buffer, at: from, with: RedisResp.asterisk)
                    if  matched {
                        (response, offset) = try parseArray(buffer, offset: offset)
                    }
                    else {
                        (matched, offset) = try compare(buffer, at: from, with: RedisResp.minus)
                        if  matched {
                            (response, offset) = try parseError(buffer, offset: offset)
                        }
                        else {
                            response = RedisResponse.Error("Unknown response type")
                        }
                    }
                }
            }
        }
        return (response, offset)
    }

    private func parseArray(_ buffer: NSMutableData, offset: Int) throws -> (RedisResponse, Int) {
        var (arrayLength, newOffset) = try parseIntegerValue(buffer, offset: offset)
        var responses = [RedisResponse]()
        var response: RedisResponse
        if  arrayLength >= 0  {
            for _ in 0 ..< Int(arrayLength)  {
                (response, newOffset) = try parseByPrefix(buffer, from: newOffset)
                responses.append(response)
            }
            return (RedisResponse.Array(responses), newOffset)
        }
        else {
            return (RedisResponse.Nil, newOffset)
        }
    }

    private func parseBulkString(_ buffer: NSMutableData, offset: Int) throws -> (RedisResponse, Int) {
        let (strLen64, newOffset) = try parseIntegerValue(buffer, offset: offset)
        if  strLen64 >= 0  {
            let strLen = Int(strLen64)
            while  newOffset+strLen+RedisResp.crLf.length > buffer.length  {
                let length = try socket?.read(into: buffer)
                if  length == 0  {
                    throw RedisRespError(code: .EOF)
                }
            }
            let data = NSData(bytes: buffer.bytes+newOffset, length: strLen)
            return (RedisResponse.StringValue(RedisString(data)), newOffset+strLen+RedisResp.crLf.length)
        }
        else {
            return (RedisResponse.Nil, newOffset)
        }
    }

    private func parseError(_ buffer: NSMutableData, offset: Int) throws -> (RedisResponse, Int) {
        let eos = try find(buffer, from: offset, data: RedisResp.crLf)
        let data = NSData(bytes: buffer.bytes+offset, length: eos-offset)
        let optStr = String(data: data, encoding: NSUTF8StringEncoding)
        guard  let str = optStr  else {
            throw RedisRespError(code: .notUTF8)
        }
        return (RedisResponse.Error(str), eos+RedisResp.crLf.length)
    }

    private func parseInteger(_ buffer: NSMutableData, offset: Int) throws -> (RedisResponse, Int) {
        let (int, newOffset) = try parseIntegerValue(buffer, offset: offset)
        return (RedisResponse.IntegerValue(int), newOffset)
    }

    private func parseSimpleString(_ buffer: NSMutableData, offset: Int) throws -> (RedisResponse, Int) {
        let eos = try find(buffer, from: offset, data: RedisResp.crLf)
        let data = NSData(bytes: buffer.bytes+offset, length: eos-offset)
        let optStr = String(data: data, encoding: NSUTF8StringEncoding)
        guard  let str = optStr  else {
            throw RedisRespError(code: .notUTF8)
        }
        return (RedisResponse.Status(str), eos+RedisResp.crLf.length)
    }

    // Mark: Parser helper functions

    private func compare(_ buffer: NSMutableData, at offset: Int, with: NSData) throws -> (Bool, Int) {
        while  offset+with.length >= buffer.length  {
            let length = try socket?.read(into: buffer)
            if  length == 0  {
                throw RedisRespError(code: .EOF)
            }
        }

        if  memcmp(UnsafePointer<Int8>(buffer.bytes)+offset, UnsafePointer<Int8>(with.bytes), with.length)  == 0  {
            return (true, offset+with.length)
        }
        else {
            return (false, offset)
        }
    }

    private func find(_ buffer: NSMutableData, from: Int, data: NSData) throws -> Int {
        var notFound = true
        var offset = from

        while notFound {
            while  notFound  &&  offset+data.length <= buffer.length  {
                notFound = memcmp(UnsafePointer<Int8>(buffer.bytes)+offset, UnsafePointer<Int8>(data.bytes), data.length)  != 0
                offset += 1
            }
            if  notFound  {
                let length = try socket?.read(into: buffer)
                if  length == 0  {
                    throw RedisRespError(code: .EOF)
                }
            }
        }
        return offset-1
    }

    private func parseIntegerValue(_ buffer: NSMutableData, offset: Int) throws -> (Int64, Int) {
        let eos = try find(buffer, from: offset, data: RedisResp.crLf)
        let data = NSData(bytes: buffer.bytes+offset, length: eos-offset)
        let optStr = String(data: data, encoding: NSUTF8StringEncoding)
        guard  let str = optStr  else {
            throw RedisRespError(code: .notUTF8)
        }
        let optInt = Int64(str)
        guard  let int = optInt  else {
            throw RedisRespError(code: .notInteger)
        }
        return (int, eos+RedisResp.crLf.length)
    }

    // Mark: helper functions

    private func addAsBulkString(_ cString: NSData, to buffer: NSMutableData) {
        buffer.append(RedisResp.dollar)
        add(cString.length, to: buffer)
        buffer.append(RedisResp.crLf)

        buffer.append(cString)
        buffer.append(RedisResp.crLf)
    }

    private func add(_ number: Int, to buffer: NSMutableData) {
        add(String(number), to: buffer)
    }

    private func add(_ text: String, to buffer: NSMutableData) {
        buffer.append(StringUtils.toUtf8String(text)!)
    }
}

private enum RedisRespErrorCode {
    case EOF, notInteger, notUTF8
}

private struct RedisRespError: ErrorProtocol {
    private let code: RedisRespErrorCode

    func description() -> String {
        switch(code) {
            case .EOF:
                return "Unexpected EOF while parsing the response from the server"
            case .notInteger:
                return "An integer value contained non-digit characters"
            case .notUTF8:
                return "A simple string or error message wasn't UTF-8 encoded"
        }
    }
}
