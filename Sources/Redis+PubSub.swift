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
    /// - parameter err: Non-nil if an err occurred.
    public func publish(channel: String, message: String, callback: (_ result: Int?, _ err: NSError?) -> Void) {
        issueCommand("PUBLISH", channel, message) {(res: RedisResponse) in
            redisIntegerResponseHandler(res, callback: callback)
        }
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
    /// - parameter callback: The callback function.
    /// - parameter res: The following list: ("subscribe", channel just 
    ///                  subscribed to, number of active subscriptions). Only
    ///                  returns the first channel subscribed to.
    /// - parameter err: Always nil.
    public func subscribe(channels: String..., callback: (_ res: [Any?]?, _ err: NSError?) -> Void) {
        subscribeArrayOfChannels(channels: channels, callback: callback)
    }
    
    /// Subscribes the client to the specified channels.
    ///
    /// - parameter channels: A list of channels to subscribe to.
    /// - parameter callback: The callback function.
    /// - parameter res: The following list: ("subscribe", channel just
    ///                  subscribed to, number of active subscriptions). Only
    ///                  returns the first channel subscribed to.
    /// - parameter err: Always nil.
    public func subscribeArrayOfChannels(channels: [String], callback: (_ res: [Any?]?, _ err: NSError?) -> Void) {
        var command = ["SUBSCRIBE"]
        for channel in channels {
            command.append(channel)
        }
        issueCommandInArray(command) { res in
            redisAnyArrayResponseHandler(response: res, callback: callback)
        }
    }
    
    /// Subscribes the client to the given patterns.
    ///
    /// - parameter patterns: A list of glob-style patterns to subscribe to.
    /// - parameter callback: The callback function.
    /// - parameter res: The following list: ("psubscribe", channel just
    ///                  subscribed to, number of active subscriptions). Only
    ///                  returns the first channel subscribed to.
    /// - parameter err: Always nil.
    public func psubscribe(patterns: String..., callback: (_ res: [Any?]?, _ err: NSError?) -> Void) {
        psubscribeArrayOfPattens(patterns: patterns, callback: callback)
    }
    
    /// Subscribes the client to the given patterns.
    ///
    /// - parameter patterns: An array of glob-style patterns to subscribe to.
    /// - parameter callback: The callback function.
    /// - parameter res: The following list: ("psubscribe", channel just
    ///                  subscribed to, number of active subscriptions). Only
    ///                  returns the first channel subscribed to.
    /// - parameter err: Always nil.
    public func psubscribeArrayOfPattens(patterns: [String], callback: (_ res: [Any?]?, _ err: NSError?) -> Void) {
        var command = ["PSUBSCRIBE"]
        for pattern in patterns {
            command.append(pattern)
        }
        issueCommandInArray(command) { res in
            redisAnyArrayResponseHandler(response: res, callback: callback)
        }
    }
    
    /// Unsubscribes the client from the given channels, or from all of them if
    /// none is given. In this case, a message for every unsubscribed channel
    /// will be sent to the client.
    ///
    /// - parameter channels: A list of channels to unsubscribe to.
    /// - parameter callback: The callback function.
    /// - parameter res: The following list ("unsubscribe", channel just 
    ///                  unsubscribed from, number of remaining
    ///                  subscriptions). Only returns the first channel 
    ///                  unsubscribed to. NOTE: Will return a different value if
    ///                  there has been a message published in the channel 
    ///                  unsubscribed from.
    /// - parameter err: Always nil.
    public func unsubscribe(channels: String..., callback: (_ res: [Any?]?, _ err: NSError?) -> Void) {
        unsubscribeArrayOfChannels(channels: channels, callback: callback)
    }
    
    /// Unsubscribes the client from the given channels, or from all of them if
    /// none is given. In this case, a message for every unsubscribed channel
    /// will be sent to the client.
    ///
    /// - parameter channels: An array of channels to unsubscribe to.
    /// - parameter callback: The callback function.
    /// - parameter res: The following list ("unsubscribe", channel just
    ///                  unsubscribed from, number of remaining
    ///                  subscriptions). Only returns the first channel
    ///                  unsubscribed to. NOTE: Will return a different value if
    ///                  there has been a message published in the channel
    ///                  unsubscribed from.
    /// - parameter err: Always nil.
    public func unsubscribeArrayOfChannels(channels: [String], callback: (_ res: [Any?]?, _ err: NSError?) -> Void) {
        var command = ["UNSUBSCRIBE"]
        for channels in channels {
            command.append(channels)
        }
        issueCommandInArray(command) { res in
            redisAnyArrayResponseHandler(response: res, callback: callback)
        }
    }
    
    /// Unsubscribes the client from the given patterns, or from all of them if
    /// none is given. In this case, a message for every unsubscribed pattern
    /// will be sent to the client.
    ///
    /// - parameter patterns: A list of glob-style patterns to unsubscribe to.
    /// - parameter callback: The callback function.
    /// - parameter res: The following list ("unsubscribe", channel just 
    ///                  unsubscribed from, number of remaining subscriptions). 
    ///                  Only returns the first channel unsubscribed to. NOTE:
    ///                  Will return a different value if there has been a
    ///                  message published in the channel unsubscribed from.
    /// - parameter err: Always nil.
    public func punsubscribe(patterns: String..., callback: (_ res: [Any?]?, _ err: NSError?) -> Void) {
        punsubscribeArrayOfPatterns(patterns: patterns, callback: callback)
    }
    
    /// Unsubscribes the client from the given patterns, or from all of them if
    /// none is given. In this case, a message for every unsubscribed pattern
    /// will be sent to the client.
    ///
    /// - parameter patterns: An array of glob-style patterns to unsubscribe to.
    /// - parameter callback: The callback function.
    /// - parameter res: The following list ("unsubscribe", channel just
    ///                  unsubscribed from, number of remaining subscriptions).
    ///                  Only returns the first channel unsubscribed to. NOTE:
    ///                  Will return a different value if there has been a
    ///                  message published in the channel unsubscribed from.
    /// - parameter err: Always nil.
    public func punsubscribeArrayOfPatterns(patterns: [String], callback: (_ res: [Any?]?, _ err: NSError?) -> Void) {
        var command = ["PUNSUBSCRIBE"]
        for pattern in patterns {
            command.append(pattern)
        }
        issueCommandInArray(command) { res in
            redisAnyArrayResponseHandler(response: res, callback: callback)
        }
    }
    
    /// Lists the currently active channels.
    ///
    /// - parameter pattern: The pattern to match channels against glob-style.
    ///                      If unspecified, lists all channels.
    /// - parameter callback: The callback function:
    /// - parameter result: A list of active channels.
    /// - parameter err: Non-nil if an err occurred.
    public func pubsubChannels(pattern: String? = nil, callback: (_ result: [RedisString?]?, _ err: NSError?) -> Void) {
        var command = ["PUBSUB", "CHANNELS"]
        if let pattern = pattern {
            command.append(pattern)
        }
        issueCommandInArray(command) { (res) in
            redisStringArrayResponseHandler(res, callback: callback)
        }
    }
    
    /// Returns the number of subscribers for the specified channels.
    /// (not counting clients subscribed to patterns)
    ///
    /// - parameter channels: A list of zero or more channels to look up.
    /// - parameter callback: The callback function:
    /// - parameter result: A list of channels and number of subscribers for
    ///                     every channel. The format is channel, count, 
    ///                     channel, count, etc. If no channel given, this is
    ///                     empty.
    /// - parameter err: Non-nil if an err occurred.
    public func pubsubNumsub(channels: String..., callback: (_ result: [Any?]?, _ err: NSError?) -> Void) {
        pubsubNumsubArrayOfChannels(channels: channels, callback: callback)
    }
    
    /// Returns the number of subscribers for the specified channels.
    /// (not counting clients subscribed to patterns)
    ///
    /// - parameter channels: An array of zero or more channels to look up.
    /// - parameter callback: The callback function:
    /// - parameter result: A list of channels and number of subscribers for
    ///                     every channel. The format is channel, count, 
    ///                     channel, count, etc. If no channel given, this is
    ///                     empty.
    /// - parameter err: Non-nil if an err occurred.
    public func pubsubNumsubArrayOfChannels(channels: [String], callback: (_ result: [Any?]?, _ err: NSError?) -> Void) {
        var command = ["PUBSUB", "NUMSUB"]
        for channel in channels {
            command.append(channel)
        }
        issueCommandInArray(command) { (res) in
            redisAnyArrayResponseHandler(response: res, callback: callback)
        }
    }

    /// Returns the number of subscriptions to patterns.
    ///
    /// - parameter callback: The callback function:
    /// - parameter result: The number of patterns all the clients are 
    ///                     subscribed to.
    /// - parameter err: Non-nil if an err occurred.
    public func pubsubNumpat(callback: (_ result: Int?, _ err: NSError?) -> Void) {
        issueCommand("PUBSUB", "NUMPAT") { (res) in
            redisIntegerResponseHandler(res, callback: callback)
        }
    }
}
