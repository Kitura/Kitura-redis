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

/// Extend RedisMulti by adding the Pub/Sub operations
extension RedisMulti {
    
    /// Posts a message to the given channel.
    ///
    /// - parameter channel: The channel to post to.
    /// - parameter message: The message to post.
    ///
    /// - returns: The `RedisMulti` object being added to.
    @discardableResult
    public func publish(channel: String, message: String) -> RedisMulti {
        queuedCommands.append(stringArrToRedisStringArr(["PUBLISH", channel, message]))
        return self
    }
    
    /*
     * NOTE
     *
     * Once a connection calls (P)SUBSCRIBE, it becomes a subscriber connection
     * and can only issue (P)SUBSCRIBE or (P)UNSUBSCRIBE commands.
     *
     * If a connection unsubscribes from all its connections, it returns to
     * being a regular connection and can issue any command as normal.
     *
     */
    
    /// Subscribes the client to the specified channels.
    ///
    /// - parameter channels: A list of channels to subscribe to.
    ///
    /// - returns: The `RedisMulti` object being added to.
    @discardableResult
    public func subscribe(channels: String...) -> RedisMulti {
        return subscribeArrayOfChannels(channels: channels)
    }
    
    /// Subscribes the client to the specified channels.
    ///
    /// - parameter channels: An array of channels to subscribe to.
    ///
    /// - returns: The `RedisMulti` object being added to.
    @discardableResult
    public func subscribeArrayOfChannels(channels: [String]) -> RedisMulti {
        var command = ["SUBSCRIBE"]
        for channel in channels {
            command.append(channel)
        }
        queuedCommands.append(stringArrToRedisStringArr(command))
        return self
    }
    
    /// Subscribes the client to the given patterns.
    ///
    /// - parameter patterns: A list of glob-style patterns to subscribe to.
    ///
    /// - returns: The `RedisMulti` object being added to.
    public func psubscribe(patterns: String...) -> RedisMulti {
        return psubscribeArrayOfPattens(patterns: patterns)
    }
    
    /// Subscribes the client to the given patterns.
    ///
    /// - parameter patterns: A list of glob-style patterns to subscribe to.
    ///
    /// - returns: The `RedisMulti` object being added to.
    public func psubscribeArrayOfPattens(patterns: [String]) -> RedisMulti {
        var command = ["PSUBSCRIBE"]
        for pattern in patterns {
            command.append(pattern)
        }
        queuedCommands.append(stringArrToRedisStringArr(command))
        return self
    }
    
    /// Unsubscribes the client from the given channels, or from all of them if
    /// none is given. In this case, a message for every unsubscribed channel
    /// will be sent to the client.
    ///
    /// - parameter channels: A list of channels to unsubscribe to.
    ///
    /// - returns: The `RedisMulti` object being added to.
    public func unsubscribe(channels: String...) -> RedisMulti {
        return unsubscribeArrayOfChannels(channels: channels)
    }
    
    /// Unsubscribes the client from the given channels, or from all of them if
    /// none is given. In this case, a message for every unsubscribed channel
    /// will be sent to the client.
    ///
    /// - parameter channels: An array of channels to unsubscribe to.
    ///
    /// - returns: The `RedisMulti` object being added to.
    public func unsubscribeArrayOfChannels(channels: [String]) -> RedisMulti {
        var command = ["UNSUBSCRIBE"]
        for channels in channels {
            command.append(channels)
        }
        queuedCommands.append(stringArrToRedisStringArr(command))
        return self
    }
    
    /// Unsubscribes the client from the given patterns, or from all of them if
    /// none is given. In this case, a message for every unsubscribed pattern
    /// will be sent to the client.
    ///
    /// - parameter patterns: A list of glob-style patterns to unsubscribe to.
    ///
    /// - returns: The `RedisMulti` object being added to.
    public func punsubscribe(patterns: String...) -> RedisMulti {
        return punsubscribeArrayOfPatterns(patterns: patterns)
    }
    
    /// Unsubscribes the client from the given patterns, or from all of them if
    /// none is given. In this case, a message for every unsubscribed pattern 
    /// will be sent to the client.
    ///
    /// - parameter patterns: An array of glob-style patterns to unsubscribe to.
    ///
    /// - returns: The `RedisMulti` object being added to.
    public func punsubscribeArrayOfPatterns(patterns: [String]) -> RedisMulti {
        var command = ["PUNSUBSCRIBE"]
        for pattern in patterns {
            command.append(pattern)
        }
        queuedCommands.append(stringArrToRedisStringArr(command))
        return self
    }
}
