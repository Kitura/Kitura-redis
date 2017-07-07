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

import XCTest
import Glibc
@testable import SwiftRedisTests

srand(UInt32(time(nil)))

// http://stackoverflow.com/questions/24026510/how-do-i-shuffle-an-array-in-swift
extension MutableCollection where Indices.Iterator.Element == Index {
    mutating func shuffle() {
        let c = count
        guard c > 1 else { return }

        for (firstUnshuffled, unshuffledCount) in zip(indices, stride(from: c, to: 1, by: -1)) {
            let d: IndexDistance = numericCast(random() % numericCast(unshuffledCount))
            guard d != 0 else { continue }
            let i = index(firstUnshuffled, offsetBy: d)
            swap(&self[firstUnshuffled], &self[i])
        }
    }
}

extension Sequence {
    func shuffled() -> [Iterator.Element] {
        var result = Array(self)
        result.shuffle()
        return result
    }
}

XCTMain([
    testCase(AuthTests.allTests.shuffled()),
    testCase(TestBasicCommands.allTests.shuffled()),
    testCase(TestBinarySafeCommands.allTests.shuffled()),
    testCase(TestBitfield.allTests.shuffled()),
    testCase(TestConnectCommands.allTests.shuffled()),
    testCase(TestGeoCommands.allTests.shuffled()),
    testCase(TestGeoRadius.allTests.shuffled()),
    testCase(TestGeoRadiusByMember.allTests.shuffled()),
    testCase(TestHashCommands.allTests.shuffled()),
    testCase(TestIssueCommand.allTests.shuffled()),
    testCase(TestListsPart1.allTests.shuffled()),
    testCase(TestListsPart2.allTests.shuffled()),
    testCase(TestListsPart3.allTests.shuffled()),
    testCase(TestMoreCommands.allTests.shuffled()),
    testCase(TestSetCommands.allTests.shuffled()),
    testCase(TestSetCommandsPart2.allTests.shuffled()),
    testCase(TestSort.allTests.shuffled()),
    testCase(TestStringAndBitCommands.allTests.shuffled()),
    testCase(TestTransactionsPart1.allTests.shuffled()),
    testCase(TestTransactionsPart2.allTests.shuffled()),
    testCase(TestTransactionsPart3.allTests.shuffled()),
    testCase(TestTransactionsPart4.allTests.shuffled()),
    testCase(TestTransactionsPart5.allTests.shuffled()),
    testCase(TestTransactionsPart6.allTests.shuffled()),
    testCase(TestTransactionsPart7.allTests.shuffled()),
    testCase(TestTransactionsPart8.allTests.shuffled())
    ].shuffled())
