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

/// A struct that contains a subset of the information returned by the Redis INFO command
/// in a parsed and more consumable fashion.
public struct RedisInfo {

    /// A reference to the server information parsed from the response of the Redis INFO command.
    public let server: RedisInfoServer

    /// A reference to the client information parsed from the response of the Redis INFO command.
    public let client: RedisInfoClient

    /// Initialize a `RedisInfo` instance from the response of a Redis INFO command.
    ///
    /// - Parameter redisReply: A `RedisString` containing the response of the
    ///                        Redis INFO command to parse.
    public init(_ redisReply: RedisString) {

        let convertedStr = redisReply.asString
        let newline = "\r\n"
        let strArray = convertedStr.components(separatedBy: newline)
        var parsedInfo: [String: String] = [:]

        for val in strArray {
            let pos = val.range(of: ":")
            if let pos = pos {
                let key = String(val[..<pos.lowerBound])
                let value = val[pos.upperBound...]
                parsedInfo[key] = String(value)
            }
        }

        server = RedisInfoServer(parsedInfo)
        client = RedisInfoClient(parsedInfo)
    }

    /// A struct that contains a subset of the client information returned by the
    /// Redis INFO command in a parsed and more consumable fashion.
    public struct RedisInfoClient {

        /// The number clients connected to the server
        public let connected_clients: Int

        /// The number of clients connected to the server that are blocked
        public let blocked_clients: Int

        fileprivate init(_ redisInfo: [String: String]) {
            self.connected_clients = Int(redisInfo["connected_clients"]!)!
            self.blocked_clients = Int(redisInfo["blocked_clients"]!)!
        }
    }

    /// A struct that contains a subset of the server information returned by the
    /// Redis INFO command in a parsed and more consumable fashion.
    public struct RedisInfoServer {

        /// The version of Redis server
        public let redis_version: String

        /// The mode of the Redis server
        public let redis_mode: String

        /// The O/S the Redis server is running on.
        public let os: String

        /// The number of bits in the architecture (32 or 64) of the hardware
        /// the Redis server is running on.
        public let arch_bits: Int

        /// The process id of the Redis server.
        public let process_id: Int

        /// The port the Redis server is listening on.
        public let tcp_port: Int

        /// The amount of time, in seconds, the Redis server has been up.
        public let uptime_in_seconds: Int

        /// The amount of time, in days, the Redis server has been up.
        public let uptime_in_days: Int

        fileprivate init(_ redisInfo: [String: String]) {
            self.redis_version = redisInfo["redis_version"]!
            self.redis_mode = redisInfo["redis_mode"]!
            self.os = redisInfo["os"]!
            self.arch_bits = Int(redisInfo["arch_bits"]!)!
            self.process_id = Int(redisInfo["process_id"]!)!
            self.tcp_port = Int(redisInfo["tcp_port"]!)!
            self.uptime_in_seconds  = Int(redisInfo["uptime_in_seconds"]!)!
            self.uptime_in_days  = Int(redisInfo["uptime_in_days"]!)!
        }

        /// Check if the Redis server is compatable with a certain Major.Minor version of Redis
        ///
        /// - Parameter major: The major portion of the Redis server version to compare against.
        /// - Parameter minor: The minor portion of the Redis server version to compare against.
        ///
        /// - Returns: true if the Redis server is compatable with the
        ///           specified major and minor Redis version number.
        public func checkVersionCompatible(major: Int, minor: Int=0) -> Bool {
            let v = redis_version.components(separatedBy: ".").map { Int($0)! }
            return (v[0] > major) || (v[0] == major && v[1] >= minor)
        }

        /// Check if the Redis server is compatable with a certain Major.Minor.Micro version of Redis
        ///
        /// - Parameter major: The major portion of the Redis server version to compare against.
        /// - Parameter minor: The minor portion of the Redis server version to compare against.
        /// - Parameter micro: The micro portion of the Redis server version to compare against.
        ///
        /// - Returns: true if the Redis server is compatable with the
        ///           specified major, minor, and micro Redis version number.
        public func checkVersionCompatible(major: Int, minor: Int=0, micro: Int=0) -> Bool {
            let v = redis_version.components(separatedBy: ".").map { Int($0)! }
            return
                (v[0] > major) ||
                (v[0] == major && v[1] > minor) ||
                (v[0] == major && v[1] == minor && v[2] >= micro)
        }
    }
}
