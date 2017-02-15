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

/// Extend Redis by adding the Pub/Sub operations
extension Redis {
    
    //
    //  MARK: Pub/Sub API functions
    //
    
    /// Subscribes the client to the given patterns.
    ///
    /// - Parameter patterns: A list of glob-style patterns to subscribe to.
    public func psubscribe(patterns: String...) {
        psubscribeArrayOfPattens(patterns: patterns)
    }
    
    /// Subscribes the client to the given patterns.
    ///
    /// - Parameter patterns: An array of glob-style patterns to subscribe to.
    public func psubscribeArrayOfPattens(patterns: [String]) {
        var command = ["PSUBSCRIBE"]
        for pattern in patterns {
            command.append(pattern)
        }
        issueCommandInArray(command) { _ in }
    }
    
    /// Posts a message to the given channel.
    ///
    /// - Parameter channel: The channel to post to.
    /// - Parameter message: The message to post.
    /// - Parameter callback: The callback function:
    //                        --Int: The number of clients that received the message.
    ///                       --NSError: Non-nil if an error occurred.
    public func publish(channel: String, message: String, callback: (Int?, NSError?) -> Void) {
        issueCommand("PUBLISH", channel, message) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Lists the currently active channels.
    ///
    /// - Parameter pattern: The pattern to match channels against glob-style.
    ///                      If unspecified, lists all channels.
    /// - Parameter callback: The callback function:
    //                        --RedisString: A list of active channels.
    ///                       --NSError: Non-nil if an error occurred.
    public func pubsubChannels(pattern: String? = nil, callback: ([RedisString?]?, NSError?) -> Void) {
        var command = ["PUBSUB", "CHANNELS"]
        if let pattern = pattern {
            command.append(pattern)
        }
        issueCommandInArray(command) { (response) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    /// Returns the number of subscribers for the specified channels.
    /// (not counting clients subscribed to patterns)
    ///
    /// - Parameter channels: A list of zero or more channels to look up.
    /// - Parameter callback: The callback function:
    //                        --RedisString: A list of channels and number of subscribers for every channel.
    ///                                      The format is channel, count, channel, count, etc.
    ///                                      If no channel given, this is empty.
    ///                       --NSError: Non-nil if an error occurred.
    public func pubsubNumsub(channels: String..., callback: ([RedisString?]?, NSError?) -> Void) {
        pubsubNumsubArrayOfChannels(channels: channels, callback: callback)
    }
    
    /// Returns the number of subscribers for the specified channels.
    /// (not counting clients subscribed to patterns)
    ///
    /// - Parameter channels: An array of zero or more channels to look up.
    /// - Parameter callback: The callback function:
    //                        --RedisString: A list of channels and number of subscribers for every channel.
    ///                                      The format is channel, count, channel, count, etc.
    ///                                      If no channel given, this is empty.
    ///                       --NSError: Non-nil if an error occurred.
    public func pubsubNumsubArrayOfChannels(channels: [String], callback: ([RedisString?]?, NSError?) -> Void) {
        var command = ["PUBSUB", "NUMSUB"]
        for channel in channels {
            command.append(channel)
        }
        issueCommandInArray(command) { (response) in
            self.redisStringArrayResponseHandler(response, callback: callback)
        }
    }

    /// Returns the number of subscriptions to patterns.
    /// (that are performed using the PSUBSCRIBE command)
    ///
    /// - Parameter callback: The callback function:
    //                        --Int: The number of patterns all the clients are subscribed to.
    ///                       --NSError: Non-nil if an error occurred.
    public func pubsubNumpat(callback: (Int?, NSError?) -> Void) {
        issueCommand("PUBSUB", "NUMPAT") { (response) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Unsubscribes the client from the given patterns,
    /// or from all of them if none is given.
    /// In this case, a message for every unsubscribed pattern will be sent to the client.
    ///
    /// - Parameter patterns: A list of glob-style patterns to unsubscribe to.
    public func punsubscribe(patterns: String...) {
        punsubscribeArrayOfPatterns(patterns: patterns)
    }
    
    /// Unsubscribes the client from the given patterns,
    /// or from all of them if none is given.
    /// In this case, a message for every unsubscribed pattern will be sent to the client.
    ///
    /// - Parameter patterns: An array of glob-style patterns to unsubscribe to.
    public func punsubscribeArrayOfPatterns(patterns: [String]) {
        var command = ["PUNSUBSCRIBE"]
        for pattern in patterns {
            command.append(pattern)
        }
        issueCommandInArray(command) { _ in }
    }
    
    /// Subscribes the client to the specified channels.
    ///
    /// - Parameter patterns: A list of channels to subscribe to.
    public func subscribe(channels: String...) {
        subscribeArrayOfChannels(channels: channels)
    }

    /// Subscribes the client to the specified channels.
    ///
    /// - Parameter patterns: An array of channels to subscribe to.
    public func subscribeArrayOfChannels(channels: [String]) {
        var command = ["SUBSCRIBE"]
        for channel in channels {
            command.append(channel)
        }
        issueCommandInArray(command) { _ in }
    }
}
