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

/// Extend Redis by adding the Geo operations
extension Redis {
    
    //
    //  MARK: Geo API functions
    //
    
    /// (longitude, latitude, name)
    public typealias GeospatialItem = (Double, Double, String)
    
    /// Unit of distance used in various GEO commands
    public enum GeoDistanceUnit: String {
        case m, km, mi, ft
    }
    
    /// Adds the specified geospatial items (longitude, latitude, name) to the
    /// specified key.
    ///
    /// - parameter key: The key of the geospatial index to add the geospacial
    ///                  items to. It will be created if it does not exist.
    /// - parameter geospatialItems: A geospatial item is (longitude: Double,
    ///                              latitude: Double, name: String).
    /// - parameter callback: The callback function.
    /// - parameter result: The number of elements added to the sorted set, not
    ///                     including elements already existing for which the
    ///                     score was updated.
    /// - parameter error: Non-nil if error occurred.
    public func geoadd(key: String, geospatialItems: GeospatialItem..., callback: (_ result: Int?, _ error: NSError?) -> Void) {
        geoaddArrayOfGeospatialItems(key: key, geospatialItems: geospatialItems, callback: callback)
    }
    
    /// Adds the specified geospatial items (longitude, latitude, name) to the
    /// specified key.
    ///
    /// - parameter key: The key of the geospatial index to add the geospacial
    ///                  items to. It will be created if it does not exist.
    /// - parameter geospatialItems: A geospatial item is (longitude: Double,
    ///                              latitude: Double, name: String).
    /// - parameter callback: The callback function.
    /// - parameter result: The number of elements added to the sorted set, not
    ///                     including elements already existing for which the
    ///                     score was updated.
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
    
    /// Return valid Geohash strings representing the position of one or more
    /// elements in a sorted set value representing a geospatial index (where
    /// elements were added using GEOADD).
    ///
    /// - parameter key: The key of the geospatial index.
    /// - parameter members: List of members from which to get their Geohash
    ///                      strings.
    /// - parameter callback: The callback function.
    /// - parameter result: An array where each element is the Geohash
    ///                     corresponding to each member name passed as argument
    ///                     to the command.
    /// - parameter error: Non-nil if error occurred.
    public func geohash(key: String, members: String..., callback: (_ result: [RedisString?]?, _ error: NSError?) -> Void) {
        geohashArrayOfMembers(key: key, members: members, callback: callback)
    }
    
    /// Return valid Geohash strings representing the position of one or more
    /// elements in a sorted set value representing a geospatial index (where
    /// elements were added using GEOADD).
    ///
    /// - parameter key: The key of the geospatial index.
    /// - parameter members: List of members from which to get their Geohash
    ///                      strings.
    /// - parameter callback: The callback function.
    /// - parameter result: An array where each element is the Geohash
    ///                     corresponding to each member name passed as argument
    ///                     to the command.
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
    
    /// Return the positions (longitude, latitude) of all the specified members
    /// of the geospatial index represented by the sorted set at `key`.
    ///
    /// - parameter key: The key of the geospatial index.
    /// - parameter members: The members from which to get their positions.
    /// - parameter callback: The callback function.
    /// - parameter result: An array where each element is (Double, Double)
    ///                     representing longitude and latitude (x,y) of each
    ///                     member name passed as argument to the command. Non
    ///                     existing elements are reported as NULL elements of
    ///                     the array.
    /// - parameter error: Non-nil if error occurred.
    public func geopos(key: String, members: String..., callback: (_ result: [(Double, Double)?]?, _ error: NSError?) -> Void) {
        geoposArrayOfMembers(key: key, members: members, callback: callback)
    }
    
    /// Return the positions (longitude, latitude) of all the specified members
    /// of the geospatial index represented by the sorted set at `key`.
    ///
    /// - parameter key: The key of the geospatial index.
    /// - parameter members: The members from which to get their positions.
    /// - parameter callback: The callback function.
    /// - parameter result: An array where each element is (Double, Double)
    ///                     representing longitude and latitude (x,y) of each
    ///                     member name passed as argument to the command. Non
    ///                     existing elements are reported as NULL elements of
    ///                     the array.
    /// - parameter error: Non-nil if error occurred.
    public func geoposArrayOfMembers(key: String, members: [String], callback: (_ result: [(Double, Double)?]?, _ error: NSError?) -> Void) {
        var command = ["GEOPOS", key]
        for member in members {
            command.append(member)
        }
        issueCommandInArray(command) { (response) in
            redisArrayResponseHandler(response: response, callback: { (responses, err) in
                if let err = err {
                    callback(nil, err)
                    return
                }
                getCoordinates(from: responses, callback: callback)
            })
        }
    }
    
    /// Return the distance between two members in the geospatial index
    /// represented by the sorted set.
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
    /// - parameter result: Distance as a double (represented as a string) in
    ///                     the specified unit, or NULL if one or both the
    ///                     elements are missing.
    /// - parameter error: Non-nil if error occurred.
    public func geodist(key: String, member1: String, member2: String, unit: GeoDistanceUnit?=nil, callback: (_ result: RedisString?, _ error: NSError?) -> Void) {
        var command = ["GEODIST", key, member1, member2]
        if let unit = unit {
            switch unit {
            case .m: command.append(GeoDistanceUnit.m.rawValue)
            case .km: command.append(GeoDistanceUnit.km.rawValue)
            case .mi: command.append(GeoDistanceUnit.mi.rawValue)
            case .ft: command.append(GeoDistanceUnit.ft.rawValue)
            }
        }
        issueCommandInArray(command) { (response) in
            redisStringResponseHandler(response, callback: callback)
        }
    }
    
    /// Return the members of a sorted set populated with geospatial information
    /// using GEOADD, which are within the borders of the area specified with
    /// the center location and the maximum distance from the center (the
    /// radius).
    ///
    /// - parameter key: The key of the geospatial index.
    /// - parameter longitude: The longitude of the center area of which to
    ///                        perform the search.
    /// - parameter latitude: The latitude of the center area of which to
    ///                       perform the search.
    /// - parameter radius: The radius of the circle from which to perform the
    ///                     search.
    /// - parameter unit: The unit of distance for the radius.
    ///                   m - meters
    ///                   km - kilometers
    ///                   mi - miles
    ///                   ft - feet
    /// - parameter withCoord: If true, result will also return the longitude,
    ///                        latitude coordinates of the matching items.
    /// - parameter withDist: If true, result will also return the distance of
    ///                       the returned items from the specified center. The
    ///                       distance is returned in the same unit as the unit
    ///                       specified as the radius argument of the command.
    /// - parameter withHash: If true, result will also return the raw geohash-
    ///                       encoded sorted set score of the item, in the form
    ///                       of a 52 bit unsigned integer. This is only useful
    ///                       for low level hacks or debugging and is otherwise
    ///                       of little interest for the general user.
    /// - parameter count: Amount to limit number of results to. Exclude to
    ///                    retrieve all results.
    /// - parameter ascending: If true, return results sorted nearest to
    ///                        farthest. If false, return results sorted
    ///                        farthest to nearest. If excluded, results are
    ///                        unsorted.
    /// - parameter callback: The callback function.
    /// - parameter result: With no `WITH` options included, returns a linear
    ///                     array of location names. If any `WITH` options are
    ///                     included, returns an array of sub-arrays, where each
    ///                     represents an item with its extra data.
    /// - parameter error: Non-nil if error occurred.
    public func georadius(key: String, longitude: Double, latitude: Double, radius: Double, unit: GeoDistanceUnit, withCoord: Bool?=nil, withDist: Bool?=nil, withHash: Bool?=nil, count: Int?=nil, ascending: Bool?=nil, callback: (_ result: [RedisResponse?]?, _ error: NSError?) -> Void) {
        var command = ["GEORADIUS", key, String(longitude), String(latitude), String(radius)]
        switch unit {
        case .m: command.append(GeoDistanceUnit.m.rawValue)
        case .km: command.append(GeoDistanceUnit.km.rawValue)
        case .mi: command.append(GeoDistanceUnit.mi.rawValue)
        case .ft: command.append(GeoDistanceUnit.ft.rawValue)
        }
        if let withCoord = withCoord, withCoord {
            command.append("WITHCOORD")
        }
        if let withDist = withDist, withDist {
            command.append("WITHDIST")
        }
        if let withHash = withHash, withHash {
            command.append("WITHHASH")
        }
        if let count = count {
            command.append("COUNT")
            command.append(String(count))
        }
        if let ascending = ascending {
            if ascending {
                command.append("ASC")
            } else {
                command.append("DESC")
            }
        }
        issueCommandInArray(command) { (response) in
            redisArrayResponseHandler(response: response, callback: callback)
        }
    }
    
    /// This command is exactly like GEORADIUS with the sole difference that
    /// instead of taking, as the center of the area to query, a longitude and
    /// latitude value, it takes the name of a member already existing inside
    /// the geospatial index represented by the sorted set.
    ///
    /// - parameter key: The key of the geospatial index.
    /// - parameter member: The existing member of the geospatial index in which
    ///                     to set as the center of the search.
    /// - parameter radius: The radius of the circle from which to perform the
    ///                     search.
    /// - parameter unit: The unit of distance for the radius.
    ///                   m - meters
    ///                   km - kilometers
    ///                   mi - miles
    ///                   ft - feet
    /// - parameter withCoord: If true, result will also return the longitude,
    ///                        latitude coordinates of the matching items.
    /// - parameter withDist: If true, result will also return the distance of
    ///                       the returned items from the specified center. The
    ///                       distance is returned in the same unit as the unit
    ///                       specified as the radius argument of the command.
    /// - parameter withHash: If true, result will also return the raw geohash-
    ///                       encoded sorted set score of the item, in the form
    ///                       of a 52 bit unsigned integer. This is only useful
    ///                       for low level hacks or debugging and is otherwise
    ///                       of little interest for the general user.
    /// - parameter count: Amount to limit number of results to. Exclude to
    ///                    retrieve all results.
    /// - parameter ascending: If true, return results sorted nearest to
    ///                        farthest. If false, return results sorted
    ///                        farthest to nearest. If excluded, results are
    ///                        unsorted.
    /// - parameter callback: The callback function.
    /// - parameter result: With no `WITH` options included, returns a linear
    ///                     array of location names. If any `WITH` options are
    ///                     included, returns an array of sub-arrays, where each
    ///                     represents an item with its extra data.
    /// - parameter error: Non-nil if error occurred.
    public func georadiusbymember(key: String, member: String, radius: Double, unit: GeoDistanceUnit, withCoord: Bool?=nil, withDist: Bool?=nil, withHash: Bool?=nil, count: Int?=nil, ascending: Bool?=nil, callback: (_ result: [RedisResponse?]?, _ error: NSError?) -> Void) {
        var command = ["GEORADIUSBYMEMBER", key, member, String(radius)]
        switch unit {
        case .m: command.append(GeoDistanceUnit.m.rawValue)
        case .km: command.append(GeoDistanceUnit.km.rawValue)
        case .mi: command.append(GeoDistanceUnit.mi.rawValue)
        case .ft: command.append(GeoDistanceUnit.ft.rawValue)
        }
        if let withCoord = withCoord, withCoord {
            command.append("WITHCOORD")
        }
        if let withDist = withDist, withDist {
            command.append("WITHDIST")
        }
        if let withHash = withHash, withHash {
            command.append("WITHHASH")
        }
        if let count = count {
            command.append("COUNT")
            command.append(String(count))
        }
        if let ascending = ascending {
            if ascending {
                command.append("ASC")
            } else {
                command.append("DESC")
            }
        }
        issueCommandInArray(command) { (response) in
            redisArrayResponseHandler(response: response, callback: callback)
        }
    }
}
