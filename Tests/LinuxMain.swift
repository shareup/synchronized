import XCTest

import SynchronizedTests

var tests = [XCTestCaseEntry]()
tests += SynchronizedTests.allTests()
XCTMain(tests)
