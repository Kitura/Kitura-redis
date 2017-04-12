/**
 * Copyright IBM Corporation 2017
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

#if os(OSX)
    import XCTest

    class VerifyLinuxTestCount: XCTestCase {
        var linuxCount: Int = 0
        var darwinCount: Int = 0
    }

    // Non-transaction commands
    extension VerifyLinuxTestCount {
        func testNonTranscationCommands() {
            // AuthTests
            linuxCount = AuthTests.allTests.count
            darwinCount = Int(AuthTests.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from AuthTests.allTests")

            // TestBasicCommands
            linuxCount = TestBasicCommands.allTests.count
            darwinCount = Int(TestBasicCommands.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestBasicCommands.allTests")

            // TestBinarySafeCommands
            linuxCount = TestBinarySafeCommands.allTests.count
            darwinCount = Int(TestBinarySafeCommands.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestBinarySafeCommands.allTests")

            // TestBitfield
            linuxCount = TestBitfield.allTests.count
            darwinCount = Int(TestBitfield.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestBitfield.allTests")

            // TestConnectCommands
            linuxCount = TestConnectCommands.allTests.count
            darwinCount = Int(TestConnectCommands.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestConnectCommands.allTests")

            // TestGeoCommands
            linuxCount = TestGeoCommands.allTests.count
            darwinCount = Int(TestGeoCommands.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestGeoCommands.allTests")

            // TestGeoRadius
            linuxCount = TestGeoRadius.allTests.count
            darwinCount = Int(TestGeoRadius.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestGeoRadius.allTests")

            // TestGeoRadiusByMember
            linuxCount = TestGeoRadiusByMember.allTests.count
            darwinCount = Int(TestGeoRadiusByMember.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestGeoRadiusByMember.allTests")

            // TestHashCommands
            linuxCount = TestHashCommands.allTests.count
            darwinCount = Int(TestHashCommands.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestHashCommands.allTests")

            // TestIssueCommand
            linuxCount = TestIssueCommand.allTests.count
            darwinCount = Int(TestIssueCommand.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestIssueCommand.allTests")

            // TestListsPart1
            linuxCount = TestListsPart1.allTests.count
            darwinCount = Int(TestListsPart1.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestListsPart1.allTests")

            // TestListsPart2
            linuxCount = TestListsPart2.allTests.count
            darwinCount = Int(TestListsPart2.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestListsPart2.allTests")

            // TestListsPart3
            linuxCount = TestListsPart3.allTests.count
            darwinCount = Int(TestListsPart3.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestListsPart3.allTests")

            // TestMoreCommands
            linuxCount = TestMoreCommands.allTests.count
            darwinCount = Int(TestMoreCommands.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestMoreCommands.allTests")

            // TestSetCommands
            linuxCount = TestSetCommands.allTests.count
            darwinCount = Int(TestSetCommands.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestSetCommands.allTests")

            // TestSetCommandsPart2
            linuxCount = TestSetCommandsPart2.allTests.count
            darwinCount = Int(TestSetCommandsPart2.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestSetCommandsPart2.allTests")

            // TestSort
            linuxCount = TestSort.allTests.count
            darwinCount = Int(TestSort.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestSort.allTests")

            // TestStringAndBitCommands
            linuxCount = TestStringAndBitCommands.allTests.count
            darwinCount = Int(TestStringAndBitCommands.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestStringAndBitCommands.allTests")
        }
    }

    // Transaction commands
    extension VerifyLinuxTestCount {
        func testTransactionCommands() {
            // TestTransactionsPart1
            linuxCount = TestTransactionsPart1.allTests.count
            darwinCount = Int(TestTransactionsPart1.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestTransactionsPart1.allTests")

            // TestTransactionsPart2
            linuxCount = TestTransactionsPart2.allTests.count
            darwinCount = Int(TestTransactionsPart2.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestTransactionsPart2.allTests")

            // TestTransactionsPart3
            linuxCount = TestTransactionsPart3.allTests.count
            darwinCount = Int(TestTransactionsPart3.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestTransactionsPart3.allTests")

            // TestTransactionsPart4
            linuxCount = TestTransactionsPart4.allTests.count
            darwinCount = Int(TestTransactionsPart4.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestTransactionsPart4.allTests")

            // TestTransactionsPart5
            linuxCount = TestTransactionsPart5.allTests.count
            darwinCount = Int(TestTransactionsPart5.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestTransactionsPart5.allTests")

            // TestTransactionsPart6
            linuxCount = TestTransactionsPart6.allTests.count
            darwinCount = Int(TestTransactionsPart6.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestTransactionsPart6.allTests")

            // TestTransactionsPart7
            linuxCount = TestTransactionsPart7.allTests.count
            darwinCount = Int(TestTransactionsPart7.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestTransactionsPart7.allTests")

            // TestTransactionsPart8
            linuxCount = TestTransactionsPart8.allTests.count
            darwinCount = Int(TestTransactionsPart8.defaultTestSuite().testCaseCount)
            XCTAssertEqual(linuxCount, darwinCount, "\(darwinCount - linuxCount) tests are missing from TestTransactionsPart8.allTests")
        }
    }
#endif
