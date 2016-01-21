//
//  TestStringAndBitCommands.swift
//  Phoenix
//
//  Created by Samuel Kallner on 01/01/2016.
//  Copyright © 2016 Daniel Firsht. All rights reserved.
//

import SwiftRedis

import Foundation
import XCTest

public struct TestStringAndBitCommands: XCTestCase {
    public var allTests : [(String, () throws -> Void)] {
        return [
            ("test_StringManipulation", test_StringManipulation),
            ("test_bitPosAndCountCommands", test_bitPosAndCountCommands),
            ("test_bitSetAndGetCommands", test_bitSetAndGetCommands),
            ("test_bitOpCommands", test_bitOpCommands)
        ]
    }
    
    let key1 = "test1"
    let key2 = "test2"
    let key3 = "test3"
    
    let expVal1 = "Hi ho, hi ho"
    let expVal2 = " it's off to test"
    let expVal3 = "we go"
    let expVal4 = "Testing"
    let expVal5 = "testing 1 2 3"
    
    func test_StringManipulation() {
        setupTests() {
            redis.set(self.key1, value: self.expVal1) {(wasSet: Bool, error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                
                redis.append(self.key1, value: self.expVal2) {(length: Int?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(length, "Length result shouldn't be nil")
                    XCTAssertEqual(length!, self.expVal1.characters.count+self.expVal2.characters.count, "Length of updated \(self.key1) is incorrect")
                    
                    redis.strlen(self.key1)  {(length: Int?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(length, "Length result shouldn't be nil")
                        XCTAssertEqual(length!, self.expVal1.characters.count+self.expVal2.characters.count, "Length of updated \(self.key1) is incorrect")
                        
                        redis.getrange(self.key1, start: 7, end: 11) {(value: RedisString?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertNotNil(value, "Value result shouldn't be nil")
                            XCTAssertEqual(value!.asString, "hi ho", "Value of getrange wasn't 'hi ho', was '\(value!)'")
                            
                            redis.setrange(self.key1, offset: 7, value: self.expVal3) {(length: Int?, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssertNotNil(length, "Length result shouldn't be nil")
                                XCTAssertEqual(length!, self.expVal1.characters.count+self.expVal2.characters.count, "Length of updated \(self.key1) is incorrect")
                                
                                redis.get(self.key1) {(value: RedisString?, error: NSError?) in
                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                    XCTAssertNotNil(value, "Value result shouldn't be nil")
                                    let updatedValue = "Hi ho, we go it's off to test"
                                    XCTAssertEqual(value!.asString, updatedValue, "Value of getrange wasn't '\(updatedValue)', was '\(value!)'")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func test_bitPosAndCountCommands() {
        setupTests() {
            let bytes: [UInt8] = [0x00, 0x01, 0x01, 0x00]
            let expVal1 = NSData(bytes: bytes, length: bytes.count)
            
            redis.set(self.key1, value: RedisString(expVal1)) {(wasSet: Bool,  error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    
                redis.bitpos(self.key1, bit: true) {(position: Int?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(position, "Position result shouldn't be nil")
                    XCTAssertEqual(position!, 15, "Bit position should have been 15, was \(position)")
                        
                    redis.bitpos(self.key1, bit: true, start: 2){(position: Int?, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(position, "Position result shouldn't be nil")
                        XCTAssertEqual(position!, 23, "Bit position should have been 23, was \(position)")
                            
                        redis.bitpos(self.key1, bit: true, start: 1, end: 2) {(position: Int?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertNotNil(position, "Position result shouldn't be nil")
                            XCTAssertEqual(position!, 15, "Bit position should have been 15, was \(position)")
                                
                            redis.bitcount(self.key1) {(count: Int?, error: NSError?) in
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssertNotNil(count, "Count result shouldn't be nil")
                                XCTAssertEqual(count!, 2, "Bit count should have been 2, was \(count)")
                                    
                                redis.bitcount(self.key1, start: 2, end: 2) {(count: Int?, error: NSError?) in
                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                    XCTAssertNotNil(count, "Count result shouldn't be nil")
                                    XCTAssertEqual(count!, 1, "Bit count should have been 1, was \(count)")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func test_bitSetAndGetCommands() {
        setupTests() {
            var bytes: [UInt8] = [0x00, 0x01, 0x01, 0x00]
            let expVal1 = NSData(bytes: bytes, length: bytes.count)
            redis.set(self.key1, value: RedisString(expVal1)) {(wasSet: Bool,  error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    
                redis.getbit(self.key1, offset: 14) {(value: Bool, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertFalse(value, "The bit should have been a 0, it was 1")
                        
                    redis.setbit(self.key1, offset: 13, value: true) {(oldValue: Bool, error: NSError?) in
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertFalse(oldValue, "The bit should have been a 0, it was 1")
                            
                        bytes = [0x00, 0x05, 0x01, 0x00]
                        let newVal1 = NSData(bytes: bytes, length: bytes.count)
                            
                        redis.get(self.key1) {(value: RedisString?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertEqual(value!.asData, newVal1, "The updated bit string had a value of '\(value)'")
                        }
                    }
                }
            }
        }
    }
    
    func test_bitOpCommands() {
        setupTests() {
            var bytes: [UInt8] = [0x00, 0x01, 0x01, 0x04]
            let expVal1 = NSData(bytes: bytes, length: bytes.count)
            bytes = [0x00, 0x08, 0x08, 0x04]
            let expVal2 = NSData(bytes: bytes, length: bytes.count)
            
            redis.mset((self.key1, RedisString(expVal1)), (self.key2, RedisString(expVal2))) {(wasSet: Bool,  error: NSError?) in
                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    
                redis.bitop(self.key3, and: self.key1, self.key2) {(length: Int?, error: NSError?) in
                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                    XCTAssertNotNil(length, "Length result shouldn't be nil")
                    XCTAssertEqual(length!, 4, "Destination field length should have been 4, was \(length)")
                        
                    redis.get(self.key3) {(value: RedisString?, error: NSError?) in
                        bytes = [0x00, 0x00, 0x00, 0x04]
                        let newValue = NSData(bytes: bytes, length: bytes.count)
                            
                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                        XCTAssertNotNil(value, "Value result shouldn't be nil")
                        XCTAssertEqual(value!.asData, newValue, "\(self.key3) after an and had a value of '\(value)'")
                            
                        redis.bitop(self.key3, or: self.key1, self.key2) {(length: Int?, error: NSError?) in
                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                            XCTAssertNotNil(length, "Length result shouldn't be nil")
                            XCTAssertEqual(length!, 4, "Destination field length should have been 4, was \(length)")
                                
                            redis.get(self.key3) {(value: RedisString?, error: NSError?) in
                                bytes = [0x00, 0x09, 0x09, 0x04]
                                let newValue = NSData(bytes: bytes, length: bytes.count)
                                    
                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                XCTAssertNotNil(value, "Value result shouldn't be nil")
                                XCTAssertEqual(value!.asData, newValue, "\(self.key3) after an or had a value of '\(value)'")
                                    
                                redis.bitop(self.key3, xor: self.key1, self.key2) {(length: Int?, error: NSError?) in
                                    XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                    XCTAssertNotNil(length, "Length result shouldn't be nil")
                                    XCTAssertEqual(length!, 4, "Destination field length should have been 4, was \(length)")
                                        
                                    redis.get(self.key3) {(value: RedisString?, error: NSError?) in
                                        bytes = [0x00, 0x09, 0x09, 0x00]
                                        let newValue = NSData(bytes: bytes, length: bytes.count)
                                            
                                        XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                        XCTAssertNotNil(value, "Value result shouldn't be nil")
                                        XCTAssertEqual(value!.asData, newValue, "\(self.key3) after a xor had a value of '\(value)'")
                                            
                                        redis.bitop(self.key3, not: self.key1) {(length: Int?, error: NSError?) in
                                            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                            XCTAssertNotNil(length, "Length result shouldn't be nil")
                                            XCTAssertEqual(length!, 4, "Destination field length should have been 4, was \(length)")
                                                
                                            redis.get(self.key3) {(value: RedisString?, error: NSError?) in
                                                bytes = [0xff, 0xfe, 0xfe, 0xfb]
                                                let newValue = NSData(bytes: bytes, length: bytes.count)
                                                    
                                                XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
                                                XCTAssertNotNil(value, "Value result shouldn't be nil")
                                                XCTAssertEqual(value!.asData, newValue, "\(self.key3) after a not had a value of '\(value)'")
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
    }
    
    
    private func setupTests(callback: () -> Void) {
        connectRedis() {(error: NSError?) in
            XCTAssertNil(error, "\(error != nil ? error!.localizedDescription : "")")
            
            redis.del(self.key1, self.key2, self.key3) {(deleted: Int?, error: NSError?) in
                callback()
            }
        }
    }
}