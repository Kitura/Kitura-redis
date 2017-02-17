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

/// Extend Redis by adding the Geo operations
extension Redis {
    
    //
    //  MARK: Geo API functions
    //
    
    /// (latitude, longitude, name)
    public typealias GeospatialItem = (Double, Double, String)
    
    /// Adds the specified geospatial items (latitude, longitude, name) to the specified key.
    /// 
    /// - parameter key: The key of the geospatial index to add the geospacial items to.
    ///                  It will be created if it does not exist.
    /// - parameter geospatialItems: A geospatial item is (latitude: Double, longitude: Double, name: String).
    /// - parameter callback: The callback function.
    /// - parameter result: The number of elements added to the sorted set, not including elements already existing for 
    ///                     which the score was updated.
    /// - parameter error: Non-nil if error occurred.
    public func geoadd(key: String, geospatialItems: GeospatialItem..., callback: (_ result: Int?, _ error: NSError?) -> Void) {
        geoaddArrayOfGeospatialItems(key: key, geospatialItems: geospatialItems, callback: callback)
    }
    
    /// Adds the specified geospatial items (latitude, longitude, name) to the specified key.
    ///
    /// - parameter key: The key of the geospatial index to add the geospacial items to.
    ///                  It will be created if it does not exist.
    /// - parameter geospatialItems: A geospatial item is (latitude: Double, longitude: Double, name: String).
    /// - parameter callback: The callback function.
    /// - parameter result: The number of elements added to the sorted set, not including elements already existing for
    ///                     which the score was updated.
    /// - parameter error: Non-nil if error occurred.
    public func geoaddArrayOfGeospatialItems(key: String, geospatialItems: [GeospatialItem], callback: (_ result: Int?, _ error: NSError?) -> Void) {
        var command = ["GEOADD", key]
        for geospatialItem in geospatialItems {
            command.append(String(geospatialItem.0))
            command.append(String(geospatialItem.1))
            command.append(geospatialItem.2)
        }
        issueCommandInArray(command) { (response) in
            redisIntegerResponseHandler(response, callback: callback)
        }
    }
    
    /// Return valid Geohash strings representing the position of one or more elements in a sorted set value representing
    /// a geospatial index (where elements were added using GEOADD).
    ///
    /// - parameter key: The key of the geospatial index.
    /// - parameter members: List of members from which to get their Geohash strings.
    /// - parameter callback: The callback function.
    /// - parameter result: An array where each element is the Geohash corresponding to each member name passed as
    ///                     argument to the command.
    /// - parameter error: Non-nil if error occurred.
    public func geohash(key: String, members: String..., callback: (_ result: [RedisString?]?, _ error: NSError?) -> Void) {
        geohashArrayOfMembers(key: key, members: members, callback: callback)
    }

    /// Return valid Geohash strings representing the position of one or more elements in a sorted set value representing
    /// a geospatial index (where elements were added using GEOADD).
    ///
    /// - parameter key: The key of the geospatial index.
    /// - parameter members: Array of members from which to get their Geohash strings.
    /// - parameter callback: The callback function.
    /// - parameter result: An array where each element is the Geohash corresponding to each member name passed as
    ///                     argument to the command.
    /// - parameter error: Non-nil if error occurred.
    public func geohashArrayOfMembers(key: String, members: [String], callback: (_ result: [RedisString?]?, _ error: NSError?) -> Void) {
        var command = ["GEOHASH", key]
        for member in members {
            command.append(member)
        }
        issueCommandInArray(command) { (response) in
            redisStringArrayResponseHandler(response, callback: callback)
        }
    }
    
    /// Return the positions (longitude,latitude) of all the specified members of the geospatial index represented by the
    /// sorted set at key.
    ///
    /// - parameter key: The key of the geospatial index.
    /// - parameter members: The members from which to get their positions.
    /// - parameter callback: The callback function.
    /// - parameter result: An array where each element is a two elements array representing longitude and latitude (x,y)
    ///                     of each member name passed as argument to the command.
    ///                     Non existing elements are reported as NULL elements of the array.
    /// - parameter error: Non-nil if error occurred.
    public func geopos(key: String, members: String..., callback: (_ result: [RedisString?]?, _ error: NSError?) -> Void) {
        geoposArrayOfMembers(key: key, members: members, callback: callback)
    }

    /// Return the positions (longitude,latitude) of all the specified members of the geospatial index represented by the
    /// sorted set at key.
    ///
    /// - parameter key: The key of the geospatial index.
    /// - parameter members: The members from which to get their positions.
    /// - parameter callback: The callback function.
    /// - parameter result: An array where each element is a two elements array representing longitude and latitude (x,y)
    ///                     of each member name passed as argument to the command.
    ///                     Non existing elements are reported as NULL elements of the array.
    /// - parameter error: Non-nil if error occurred.
    public func geoposArrayOfMembers(key: String, members: [String], callback: (_ result: [RedisString?]?, _ error: NSError?) -> Void) {
        var command = ["GEOPOS", key]
        for member in members {
            command.append(member)
        }
        issueCommandInArray(command) { (response) in
            redisStringArrayResponseHandler(response, callback: callback)
        }
    }

    /// Return the distance between two members in the geospatial index represented by the sorted set.
    ///
    /// - parameter key: The key of the geospatial index.
    /// - parameter member1: The first member to find the distance from.
    /// - parameter member2: The second member to find the distance from.
    /// - parameter unit: The unit of measurement desired for the result.
    ///                   m - meters (default)
    ///                   km - kilometers
    ///                   mi - miles
    ///                   ft - feet
    /// - parameter callback: The callback function.
    /// - parameter result: Distance as a double (represented as a string) in the specified unit, or NULL if one or both
    ///                     the elements are missing.
    /// - parameter error: Non-nil if error occurred.
    public func geodist(key: String, member1: String, member2: String, unit: String?, callback: (_ result: RedisString?, _ error: NSError?) -> Void) {
        var command = ["GEODIST", key, member1, member2]
        if let unit = unit {
            command.append(unit)
        }
        issueCommandInArray(command) { (response) in
            redisStringResponseHandler(response, callback: callback)
        }
    }
}
