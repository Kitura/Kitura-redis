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
    
    /// Posts a message to the given channel.
    ///
    /// - parameter channel: The channel to post to.
    /// - parameter message: The message to post.
    /// - parameter callback: The callback function.
    /// - parameter result: The number of clients that received the message.
    /// - parameter error: Non-nil if an error occurred.
    public func publish(channel: String, message: String, callback: (_ result: Int?, _ error: NSError?) -> Void) {
        issueCommand("PUBLISH", channel, message) {(response: RedisResponse) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /*
     * NOTE
     *
     * Once a connection calls (P)SUBSCRIBE, it becomes a subscriber connection
     * and can only issue (P)SUBSCRIBE or (P)UNSUBSCRIBE commands.
     *
     * If a connection unsubscribes from all its connections,
     * it returns to being a regular connection and can issue any command as normal.
     *
     */
    
    /// Subscribes the client to the specified channels.
    ///
    /// - parameter channels: A list of channels to subscribe to.
    public func subscribe(channels: String...) {
        subscribeArrayOfChannels(channels: channels)
    }
    
    /// Subscribes the client to the specified channels.
    ///
    /// - parameter channels: An array of channels to subscribe to.
    public func subscribeArrayOfChannels(channels: [String]) {
        var command = ["SUBSCRIBE"]
        for channel in channels {
            command.append(channel)
        }
        issueCommandInArray(command) { _ in }
    }
    
    /// Subscribes the client to the given patterns.
    ///
    /// - parameter patterns: A list of glob-style patterns to subscribe to.
    public func psubscribe(patterns: String...) {
        psubscribeArrayOfPattens(patterns: patterns)
    }
    
    /// Subscribes the client to the given patterns.
    ///
    /// - parameter patterns: An array of glob-style patterns to subscribe to.
    public func psubscribeArrayOfPattens(patterns: [String]) {
        var command = ["PSUBSCRIBE"]
        for pattern in patterns {
            command.append(pattern)
        }
        issueCommandInArray(command) { _ in }
    }
    
    /// Unsubscribes the client from the given patterns,
    /// or from all of them if none is given.
    /// In this case, a message for every unsubscribed pattern will be sent to the client.
    ///
    /// - parameter patterns: A list of glob-style patterns to unsubscribe to.
    public func unsubscribe(channels: String...) {
        unsubscribeArrayOfChannels(channels: channels)
    }
    
    /// Unsubscribes the client from the given patterns,
    /// or from all of them if none is given.
    /// In this case, a message for every unsubscribed pattern will be sent to the client.
    ///
    /// - parameter channels: An array of glob-style patterns to unsubscribe to.
    public func unsubscribeArrayOfChannels(channels: [String]) {
        var command = ["UNSUBSCRIBE"]
        for channels in channels {
            command.append(channels)
        }
        issueCommandInArray(command) { _ in }
    }
    
    /// Unsubscribes the client from the given patterns,
    /// or from all of them if none is given.
    /// In this case, a message for every unsubscribed pattern will be sent to the client.
    ///
    /// - parameter patterns: A list of glob-style patterns to unsubscribe to.
    public func punsubscribe(patterns: String...) {
        punsubscribeArrayOfPatterns(patterns: patterns)
    }
    
    /// Unsubscribes the client from the given patterns,
    /// or from all of them if none is given.
    /// In this case, a message for every unsubscribed pattern will be sent to the client.
    ///
    /// - parameter patterns: An array of glob-style patterns to unsubscribe to.
    public func punsubscribeArrayOfPatterns(patterns: [String]) {
        var command = ["PUNSUBSCRIBE"]
        for pattern in patterns {
            command.append(pattern)
        }
        issueCommandInArray(command) { _ in }
    }
    
    /// Lists the currently active channels.
    ///
    /// - parameter pattern: The pattern to match channels against glob-style.
    ///                      If unspecified, lists all channels.
    /// - parameter callback: The callback function:
    /// - parameter result: A list of active channels.
    /// - parameter error: Non-nil if an error occurred.
    public func pubsubChannels(pattern: String? = nil, callback: (_ result: [RedisString?]?, _ error: NSError?) -> Void) {
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
    /// - parameter channels: A list of zero or more channels to look up.
    /// - parameter callback: The callback function:
    /// - parameter result: A list of channels and number of subscribers for every channel.
    ///                     The format is channel, count, channel, count, etc. If no channel given, this is empty.
    /// - parameter error: Non-nil if an error occurred.
    public func pubsubNumsub(channels: String..., callback: (_ result: [RedisString?]?, _ error: NSError?) -> Void) {
        pubsubNumsubArrayOfChannels(channels: channels, callback: callback)
    }
    
    /// Returns the number of subscribers for the specified channels.
    /// (not counting clients subscribed to patterns)
    ///
    /// - parameter channels: An array of zero or more channels to look up.
    /// - parameter callback: The callback function:
    /// - parameter result: A list of channels and number of subscribers for every channel.
    ///                     The format is channel, count, channel, count, etc. If no channel given, this is empty.
    /// - parameter error: Non-nil if an error occurred.
    public func pubsubNumsubArrayOfChannels(channels: [String], callback: (_ result: [RedisString?]?, _ error: NSError?) -> Void) {
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
    /// - parameter callback: The callback function:
    /// - parameter result: The number of patterns all the clients are subscribed to.
    /// - parameter error: Non-nil if an error occurred.
    public func pubsubNumpat(callback: (_ result: Int?, _ error: NSError?) -> Void) {
        issueCommand("PUBSUB", "NUMPAT") { (response) in
            self.redisIntegerResponseHandler(response, callback: callback)
        }
    }
}
