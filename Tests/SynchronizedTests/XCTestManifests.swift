import XCTest

#if !canImport(ObjectiveC)
    public func allTests() -> [XCTestCaseEntry] {
        [
            testCase(SynchronizedTests.allTests),
        ]
    }
#endif
