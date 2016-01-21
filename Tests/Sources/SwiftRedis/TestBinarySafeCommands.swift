//
//  TestBinarySafeCommands.swift
//  Phoenix
//
//  Created by Samuel Kallner on 03/01/2016.
//  Copyright © 2016 Daniel Firsht. All rights reserved.
//

import SwiftRedis

import Foundation
import XCTest

public struct TestBinarySafeCommands: XCTestCase {
    public var allTests : [(String, () throws -> Void)] {
        return [
            ("test_setWithBinary", test_setWithBinary),
            ("test_SetExistOptionsWithBinary", test_SetExistOptionsWithBinary),
            ("test_SetExpireOptionsWithBinary", test_SetExpireOptionsWithBinary),
            ("test_BinarySafeMsetAndMget", test_BinarySafeMsetAndMget)
        ]
    }
    
    let key1 = "test1"
    let key2 = "test2"
    let key3 = "test3"
    let key4 = "test4"
    let key5 = "test5"
    
    func test_setWithBinary() {
        self.setupTests() {
            var bytes: [UInt8] = [0xff, 0x00, 0xfe, 0x02]
            let expData = NSData(bytes: bytes, length: bytes.count)
            redis.set(self.key1, value: RedisString(expData)) {(wasSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssert(wasSet, "\(self.key1) wasn't set")
                
                bytes = [0x00, 0x01, 0x02, 0x03, 0x04]
                let newData = NSData(bytes: bytes, length: bytes.count)
                redis.getSet(self.key1, value: RedisString(newData)) {(oldValue: RedisString?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(oldValue, "oldValue wasn't suppose to be nil")
                    XCTAssertEqual(oldValue!.asData, expData, "Old data wasn't \(expData)")
                    
                    redis.get(self.key1) {(value: RedisString?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(value, "Value wasn't suppose to be nil")
                        XCTAssertEqual(value!.asData, newData, "Value of \(self.key1) wasn't \(newData)")
                    }
                }
            }
        }
    }
    
    func test_SetExistOptionsWithBinary() {
        setupTests() {
            var bytes: [UInt8] = [0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77]
            let expectedValue = NSData(bytes: bytes, length: bytes.count)
            bytes = [0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa]
            let newValue = NSData(bytes: bytes, length: bytes.count)
            
            redis.set(self.key2, value: RedisString(expectedValue), exists: true) {(wasSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssertFalse(wasSet, "Shouldn't have set \(self.key2)")
                
                redis.get(self.key2) {(returnedValue: RedisString?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNil(returnedValue, "\(self.key2) shouldn't exist")
                    
                    redis.set(self.key2, value: RedisString(expectedValue), exists: false) {(wasSet: Bool, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssert(wasSet, "Failed to set \(self.key2)")
                        
                        redis.get(self.key2) {(returnedValue: RedisString?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertEqual(returnedValue!.asData, expectedValue, "Returned value was not '\(expectedValue)'")
                            
                            redis.set(self.key2, value: RedisString(newValue), exists: false) {(wasSet: Bool, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssertFalse(wasSet, "Shouldn't have set \(self.key2)")
                                
                                redis.del(self.key2) {(deleted: Int?, error: NSError?) in
                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                    
                                    redis.set(self.key2, value: RedisString(newValue), exists: false) {(wasSet: Bool, error: NSError?) in
                                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                        XCTAssert(wasSet, "Failed to set \(self.key2)")
                                        
                                        redis.get(self.key2) {(returnedValue: RedisString?, error: NSError?) in
                                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                            XCTAssertEqual(returnedValue!.asData, newValue, "Returned value was not '\(newValue)'")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func test_SetExpireOptionsWithBinary() {
        setupTests() {
            let bytes: [UInt8] = [0x00, 0xff, 0x01, 0xfe, 0x02, 0xfd, 0x03, 0xfc, 0x04, 0xfb]
            let expectedValue = NSData(bytes: bytes, length: bytes.count)
            
            redis.set(self.key3, value: RedisString(expectedValue), expiresIn: 2.0) {(wasSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssert(wasSet, "Failed to set \(self.key3)")
                
                redis.get(self.key3) {(returnedValue: RedisString?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertEqual(returnedValue!.asData, expectedValue, "Returned value was not '\(expectedValue)'")
                    
                    usleep(2500000)
                    
                    redis.get(self.key3) {(returnedValue: RedisString?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNil(returnedValue, "\(self.key3) shouldn't exist any more")
                        
                        redis.set(self.key4, value: RedisString(expectedValue), expiresIn: 0.750) {(wasSet: Bool, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssert(wasSet, "Failed to set \(self.key4)")
                            
                            redis.get(self.key4) {(returnedValue: RedisString?, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssertEqual(returnedValue!.asData, expectedValue, "Returned value was not '\(expectedValue)'")
                                
                                usleep(800000)
                                
                                redis.get(self.key4) {(returnedValue: RedisString?, error: NSError?) in
                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                    XCTAssertNil(returnedValue, "\(self.key4) shouldn't exist any more")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func test_BinarySafeMsetAndMget() {
        setupTests() {
            var bytes: [UInt8] = [0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6]
            let expVal1 = NSData(bytes: bytes, length: bytes.count)
            bytes = [0xb1, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6]
            let expVal2 = NSData(bytes: bytes, length: bytes.count)
            bytes = [0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6]
            let expVal3 = NSData(bytes: bytes, length: bytes.count)
            bytes = [0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6]
            let expVal4 = NSData(bytes: bytes, length: bytes.count)
            bytes = [0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6]
            let expVal5 = NSData(bytes: bytes, length: bytes.count)
            
            redis.mset((self.key1, RedisString(expVal1)), (self.key2, RedisString(expVal2)), (self.key3, RedisString(expVal3))) {(wereSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                XCTAssert(wereSet, "Keys 1,2,3 should have been set")
                
                redis.get(self.key1) {(value: RedisString?, error:NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertEqual(value!.asData, expVal1, "\(self.key1) wasn't set to \(expVal1). Instead was \(value)")
                    
                    redis.mget(self.key1, self.key2, self.key4, self.key3) {(values: [RedisString?]?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(values, "Received a nil values array")
                        XCTAssertEqual(values!.count, 4, "Values array didn't have four elements. Had \(values!.count) elements")
                        XCTAssertNotNil(values![0], "Values array [0] was nil")
                        XCTAssertEqual(values![0]!.asData, expVal1, "Values array [0] wasn't equal to \(expVal1), was \(values![0]!)")
                        XCTAssertNotNil(values![1], "Values array [1] was nil")
                        XCTAssertEqual(values![1]!.asData, expVal2, "Values array [1] wasn't equal to \(expVal2), was \(values![1]!)")
                        XCTAssertNil(values![2], "Values array [2] wasn't nil. Was \(values![2])")
                        XCTAssertNotNil(values![3], "Values array [3] was nil")
                        XCTAssertEqual(values![3]!.asData, expVal3, "Values array [3] wasn't equal to \(expVal3), was \(values![3]!)")
                        
                        redis.mset((self.key3, RedisString(expVal3)), (self.key4, RedisString(expVal4)), (self.key5, RedisString(expVal5)), exists: false) {(wereSet: Bool, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertFalse(wereSet, "Keys shouldn't have been set \(self.key3) still has a value")
                            
                            redis.del(self.key3) {(deleted: Int?, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                
                                redis.mset((self.key3, RedisString(expVal3)), (self.key4, RedisString(expVal4)), (self.key5, RedisString(expVal5)), exists: false) {(wereSet: Bool, error: NSError?) in
                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                    XCTAssert(wereSet, "Keys 3,4,5 should have been set")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    
    private func setupTests(callback: () -> Void) {
        connectRedis() {(error: NSError?) in
            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
            
            redis.del(self.key1, self.key2, self.key3, self.key4, self.key5) {(deleted: Int?, error: NSError?) in
                callback()
            }
        }
    }
}

