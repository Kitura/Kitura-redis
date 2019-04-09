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

import Socket
import Foundation

enum RedisRespStatus {
    case notConnected
    case connected
}

class RedisResp {
    ///
    /// Socket used to talk with the server
    private var socket: Socket?

    // Mark: Prebuilt constant UTF8 strings (these strings are all proper UTF-8 strings)
    private static let asterisk = RedisString("*").asData
    private static let colon = RedisString(":").asData
    private static let crLf = RedisString("\r\n").asData
    private static let dollar = RedisString("$").asData
    private static let minus = RedisString("-").asData
    private static let plus = RedisString("+").asData

    /// State of connection.
    /// Does not reflect state changes in the event of a disconnect.
    var status: RedisRespStatus {
        return socket?.isConnected == true ? .connected : .notConnected
    }

    init(host: String, port: Int32) {
        socket = try? Socket.create()
        try? socket?.connect(to: host, port: port)
    }

    func issueCommand(_ stringArgs: [String], callback: (RedisResponse) -> Void) {
        guard let socket = socket else { return }

        var buffer = Data()
        buffer.append(RedisResp.asterisk)
        add(stringArgs.count, to: &buffer)
        buffer.append(RedisResp.crLf)

        for arg in stringArgs {
            addAsBulkString(RedisString(arg).asData, to: &buffer)
        }

        do {
            try socket.write(from: buffer)

            readAndParseResponse(callback: callback)
        } catch let error as Socket.Error {
            callback(RedisResponse.Error("Error sending command to Redis server. Error=\(error.description)"))
        } catch {
            callback(RedisResponse.Error("Error sending command to Redis server. Unknown error"))
        }
    }

    func issueCommand(_ stringArgs: [RedisString], callback: (RedisResponse) -> Void) {
        guard let socket = socket else { return }

        var buffer = Data()
        buffer.append(RedisResp.asterisk)
        add(stringArgs.count, to: &buffer)
        buffer.append(RedisResp.crLf)

        for arg in stringArgs {
            addAsBulkString(arg.asData, to: &buffer)
        }

        do {
            try socket.write(from: buffer)

            readAndParseResponse(callback: callback)
        } catch let error as Socket.Error {
            callback(RedisResponse.Error("Error sending command to Redis server. Error=\(error.description)"))
        } catch {
            callback(RedisResponse.Error("Error sending command to Redis server. Unknown error."))
        }
    }

    // Mark: Parsing Functions

    private func readAndParseResponse(callback: (RedisResponse) -> Void) {
        var buffer = Data()
        var offset = 0
        var response: RedisResponse = RedisResponse.Nil

        do {
            (response, offset) = try parseByPrefix(&buffer, from: offset)
            callback(response)
        } catch let error as Socket.Error {
            callback(RedisResponse.Error("Error reading from the Redis server. Error=\(error.description)"))
        } catch let error as RedisRespError {
            callback(RedisResponse.Error("Error reading from the Redis server. Error=\(error.description())"))
        } catch {
            callback(RedisResponse.Error("Error reading from the Redis server. Unknown error"))
        }
    }

    private func parseByPrefix(_ buffer: inout Data, from: Int) throws -> (RedisResponse, Int) {
        var response: RedisResponse

        var (matched, offset) = try compare(&buffer, at: from, with: RedisResp.plus)
        if  matched {
            (response, offset) = try parseSimpleString(&buffer, offset: offset)
        } else {
            (matched, offset) = try compare(&buffer, at: from, with: RedisResp.colon)
            if  matched {
                (response, offset) = try parseInteger(&buffer, offset: offset)
            } else {
                (matched, offset) = try compare(&buffer, at: from, with: RedisResp.dollar)
                if  matched {
                    (response, offset) = try parseBulkString(&buffer, offset: offset)
                } else {
                    (matched, offset) = try compare(&buffer, at: from, with: RedisResp.asterisk)
                    if  matched {
                        (response, offset) = try parseArray(&buffer, offset: offset)
                    } else {
                        (matched, offset) = try compare(&buffer, at: from, with: RedisResp.minus)
                        if  matched {
                            (response, offset) = try parseError(&buffer, offset: offset)
                        } else {
                            response = RedisResponse.Error("Unknown response type")
                        }
                    }
                }
            }
        }
        return (response, offset)
    }

    private func parseArray(_ buffer: inout Data, offset: Int) throws -> (RedisResponse, Int) {
        var (arrayLength, newOffset) = try parseIntegerValue(&buffer, offset: offset)
        var responses = [RedisResponse]()
        var response: RedisResponse
        if  arrayLength >= 0 {
            for _ in 0 ..< Int(arrayLength) {
                (response, newOffset) = try parseByPrefix(&buffer, from: newOffset)
                responses.append(response)
            }
            return (RedisResponse.Array(responses), newOffset)
        } else {
            return (RedisResponse.Nil, newOffset)
        }
    }

    private func parseBulkString(_ buffer: inout Data, offset: Int) throws -> (RedisResponse, Int) {
        let (strLen64, newOffset) = try parseIntegerValue(&buffer, offset: offset)
        if  strLen64 >= 0 {
            let strLen = Int(strLen64)
            let totalLength = newOffset+strLen+RedisResp.crLf.count
            while  totalLength > buffer.count {
                let length = try socket?.read(into: &buffer)
                if  length == 0 {
                    throw RedisRespError(code: .EOF)
                }
            }
            let data = buffer.subdata(in: newOffset..<newOffset+strLen)
            let redisString = RedisString(data)
            return (RedisResponse.StringValue(redisString), totalLength)
        } else {
            return (RedisResponse.Nil, newOffset)
        }
    }

    private func parseError(_ buffer:  inout Data, offset: Int) throws -> (RedisResponse, Int) {
        let eos = try find(&buffer, from: offset, data: RedisResp.crLf)
        let data = buffer.subdata(in: offset..<eos)
        let optStr = String(data: data as Data, encoding: String.Encoding.utf8)
        let length = eos+RedisResp.crLf.count
        guard  let str = optStr  else {
            throw RedisRespError(code: .notUTF8)
        }
        return (RedisResponse.Error(str), length)
    }

    private func parseInteger(_ buffer: inout Data, offset: Int) throws -> (RedisResponse, Int) {
        let (int, newOffset) = try parseIntegerValue(&buffer, offset: offset)
        return (RedisResponse.IntegerValue(int), newOffset)
    }

    private func parseSimpleString(_ buffer: inout Data, offset: Int) throws -> (RedisResponse, Int) {
        let eos = try find(&buffer, from: offset, data: RedisResp.crLf)
        let data = buffer.subdata(in: offset..<eos)
        let optStr = String(data: data, encoding: String.Encoding.utf8)
        let length = eos+RedisResp.crLf.count
        guard  let str = optStr  else {
            throw RedisRespError(code: .notUTF8)
        }
        return (RedisResponse.Status(str), length)
    }

    // Mark: Parser helper functions

    private func compare(_ buffer: inout Data, at offset: Int, with: Data) throws -> (Bool, Int) {
        while  offset+with.count >= buffer.count {
            let length = try socket?.read(into: &buffer)
            if  length == 0 {
                throw RedisRespError(code: .EOF)
            }
        }

        let range = buffer.range(of: with, options: [], in: offset..<offset+with.count)
        if range != nil {
            return (true, offset+with.count)
        } else {
            return (false, offset)
        }
    }

    private func find(_ buffer: inout Data, from: Int, data: Data) throws -> Int {
        var offset = from
        var notFound = true

        while notFound {
            let range = buffer.range(of: data, options: [], in: offset..<buffer.count)
            if range != nil {
                offset = (range?.lowerBound)!
                notFound = false
            } else {
                let length = try socket?.read(into: &buffer)
                if  length == 0 {
                    throw RedisRespError(code: .EOF)
                }
            }
        }
        return offset
    }

    private func parseIntegerValue(_ buffer: inout Data, offset: Int) throws -> (Int64, Int) {
        let eos = try find(&buffer, from: offset, data: RedisResp.crLf)
        let data = buffer.subdata(in: offset..<eos)
        let optStr = String(data: data as Data, encoding: String.Encoding.utf8)
        let length = eos+RedisResp.crLf.count
        guard  let str = optStr  else {
            throw RedisRespError(code: .notUTF8)
        }
        let optInt = Int64(str)
        guard  let int = optInt  else {
            throw RedisRespError(code: .notInteger)
        }
        return (int, length)
    }

    // Mark: helper functions

    private func addAsBulkString(_ cString: Data, to buffer: inout Data) {
        buffer.append(RedisResp.dollar)
        add(cString.count, to: &buffer)
        buffer.append(RedisResp.crLf)

        buffer.append(cString)
        buffer.append(RedisResp.crLf)
    }

    private func add(_ number: Int, to buffer: inout Data) {
        add(String(number), to: &buffer)
    }

    private func add(_ text: String, to buffer: inout Data) {
        buffer.append(RedisString(text).asData)
    }

}

private enum RedisRespErrorCode {
    case EOF
    case notInteger
    case notUTF8
}

private struct RedisRespError: Error {
    let code: RedisRespErrorCode

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
