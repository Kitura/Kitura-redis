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

/// The `RedisMulti` class is a handle for issueing "transactions" against a Redis
/// server. Instances of the `RedisMulti` class are created using the `Redis.multi`
/// function. These transactions are built using the various command related functions
/// of the `RedisMulti` class. Once a "transaction" is built, it is sent to the Redis
/// server and run using the `RedisMulti.exec` function.
public class RedisMulti {
    let redis: Redis
    var queuedCommands = [[RedisString]]()

    init(redis: Redis) {
        self.redis = redis
    }

    // ****************************************************************
    //  The commands to be queued are all in extensions of RedisMulti *
    // ****************************************************************


    /// Send the transaction to the server and run it.
    ///
    /// - Parameter callback: a function returning the response in the form of a `RedisResponse`
    public func exec(_ callback: @escaping (RedisResponse) -> Void) {
        redis.issueCommand("MULTI") {(multiResponse: RedisResponse) in
            switch(multiResponse) {
                case .Status(let status):
                    if  status == "OK" {
                        var idx = -1
                        var handler: ((RedisResponse) -> Void)? = nil

                        let actualHandler = {(response: RedisResponse) in
                            switch(response) {
                                case .Status(let status):
                                    if  status == "QUEUED" {
                                        idx += 1
                                        if  idx < self.queuedCommands.count {
                                            // Queue another command to Redis
                                            self.redis.issueCommandInArray(self.queuedCommands[idx], callback: handler!)
                                        } else {
                                            self.redis.issueCommand("EXEC", callback: callback)
                                        }
                                    } else {
                                        self.execQueueingFailed(response, callback: callback)
                                    }
                                default:
                                    self.execQueueingFailed(response, callback: callback)
                            }
                        }
                        handler = actualHandler

                        actualHandler(RedisResponse.Status("QUEUED"))
                    } else {
                        callback(multiResponse)
                    }
                default:
                    callback(multiResponse)
            }
        }
    }

    private func execQueueingFailed(_ response: RedisResponse, callback: (RedisResponse) -> Void) {
        redis.issueCommand("DISCARD") {(_: RedisResponse) in
            callback(response)
        }
    }
    
    func stringArrToRedisStringArr(_ stringArr: [String]) -> [RedisString] {
        var res = [RedisString]()
        for s in stringArr {
            res.append(RedisString(s))
        }
        return res
    }
}
