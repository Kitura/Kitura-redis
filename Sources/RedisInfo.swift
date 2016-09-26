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

public struct RedisInfo {
    
    public let server: RedisInfoServer
    public let client: RedisInfoClient
    
    public init(_ redisReply: RedisString) {
        
        let convertedStr = redisReply.asString
        let newline = "\r\n"
        let strArray = convertedStr.components(separatedBy: newline)
        var parsedInfo: [String: String] = [:]
        
        for val in strArray {
            let pos = val.range(of: ":")
            if let pos = pos {
                parsedInfo[val.substring(to: pos.lowerBound)] = val.substring(from: pos.upperBound)
            }
        }
        
        server = RedisInfoServer(parsedInfo)
        client = RedisInfoClient(parsedInfo)
    }
    
    public struct RedisInfoClient {
        public let connected_clients: Int
        public let blocked_clients: Int
        
        fileprivate init(_ redisInfo: [String: String]) {
            self.connected_clients = Int(redisInfo["connected_clients"]!)!
            self.blocked_clients = Int(redisInfo["blocked_clients"]!)!
        }
    }
    
    public struct RedisInfoServer {
        
        public let redis_version: String
        public let redis_mode: String
        public let os: String
        public let arch_bits: Int
        public let process_id: Int
        public let tcp_port: Int
        public let uptime_in_seconds: Int
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
        
        public func checkVersionCompatible(major: Int, minor: Int=0) -> Bool{
            let v = self.redis_version.components(separatedBy: ".")
            return Int(v[0])! >= major && Int(v[1])! >= minor
        }
        
        public func checkVersionCompatible(major: Int, minor: Int=0, micro: Int) -> Bool{
            let v = self.redis_version.components(separatedBy: ".")
            return Int(v[0])! >= major && Int(v[1])! >= minor && Int(v[2])! >= micro
        }
    }
    
}
