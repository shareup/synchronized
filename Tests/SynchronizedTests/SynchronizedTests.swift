import XCTest
import Synchronized

final class SynchronizedTests: XCTestCase {
    func testReturnsValueFromLock() {
        let lock = Lock()
        let input: Int = 0
        let output = lock.locked { input + 1 }
        XCTAssertEqual(1, output)
    }

    func testReturnsValueFromRecursiveLock() {
        let lock = RecursiveLock()
        let input: Int = 0
        let output = lock.locked { input + 1 }
        XCTAssertEqual(1, output)
    }

	enum TestError: Error {
		case locked
	}

    func testThrowsErrorFromLock() {
        let lock = Lock()
        XCTAssertThrowsError(try lock.locked { throw TestError.locked })
    }

    func testThrowsErrorFromRecursiveLock() {
        let lock = RecursiveLock()
        XCTAssertThrowsError(try lock.locked { throw TestError.locked })
    }

    func testCounterWithLock() {
        let iterations = 100_000
        let counter = Counter()
        let lock = Lock()
        let group = DispatchGroup()

        (0..<iterations).forEach { _ in
            group.enter()
            DispatchQueue.global().async {
                lock.locked { counter.increment() }
                group.leave()
            }
        }

        group.wait()

        XCTAssertEqual(iterations, counter.currentValue)
    }

    func testCounterWithRecursiveLock() {
        let iterations = 100_000
        let counter = Counter()
        let lock = RecursiveLock()
        let group = DispatchGroup()

        (0..<iterations).forEach { _ in
            group.enter()
            DispatchQueue.global().async {
                lock.locked { counter.increment() }
                group.leave()
            }
        }

        group.wait()

        XCTAssertEqual(iterations, counter.currentValue)
    }

    func testCounterWithLockWithDifferentQoS() {
        let iterations = 100_000
        let counter = Counter()
        let lock = Lock()
        let group = DispatchGroup()

        (0..<iterations).forEach { _ in
            group.enter()

            let qos: DispatchQoS.QoSClass = Bool.random() ? .userInteractive : .background
            DispatchQueue.global(qos: qos).async {
                lock.locked { counter.increment() }
                group.leave()
            }
        }

        group.wait()

        XCTAssertEqual(iterations, counter.currentValue)
    }

    func testCounterWithRecursiveLockWithDifferentQoS() {
        let iterations = 100_000
        let counter = Counter()
        let lock = RecursiveLock()
        let group = DispatchGroup()

        (0..<iterations).forEach { _ in
            group.enter()

            let qos: DispatchQoS.QoSClass = Bool.random() ? .userInteractive : .background
            DispatchQueue.global(qos: qos).async {
                lock.locked { counter.increment() }
                group.leave()
            }
        }

        group.wait()

        XCTAssertEqual(iterations, counter.currentValue)
    }

    func testMultipleCountersWithLock() {
        let iterations = 100_000
        let first = Counter()
        let second = Counter()
        let third = Counter()
        let counters = [first, second, third]
        let lock = Lock()

        let group = DispatchGroup()

        (0..<iterations).forEach { iteration in
            counters.forEach { counter in
                group.enter()
                DispatchQueue.global().async {
                    lock.locked { counter.increment() }
                    group.leave()
                }
            }
        }

        group.wait()

        XCTAssertEqual(iterations, first.currentValue)
        XCTAssertEqual(iterations, second.currentValue)
        XCTAssertEqual(iterations, third.currentValue)
    }

    func testMultipleCountersWithRecursiveLock() {
        let iterations = 100_000
        let first = Counter()
        let second = Counter()
        let third = Counter()
        let counters = [first, second, third]
        let lock = RecursiveLock()

        let group = DispatchGroup()

        (0..<iterations).forEach { iteration in
            counters.forEach { counter in
                group.enter()
                DispatchQueue.global().async {
                    lock.locked { counter.increment() }
                    group.leave()
                }
            }
        }

        group.wait()

        XCTAssertEqual(iterations, first.currentValue)
        XCTAssertEqual(iterations, second.currentValue)
        XCTAssertEqual(iterations, third.currentValue)
    }

    func testMultipleCountersWithLockWithDifferentQoS() {
        let iterations = 100_000
        let first = Counter()
        let second = Counter()
        let third = Counter()
        let counters = [first, second, third]
        let lock = Lock()

        let group = DispatchGroup()

        (0..<iterations).forEach { iteration in
            counters.forEach { counter in
                group.enter()
                let qos: DispatchQoS.QoSClass = Bool.random() ? .userInteractive : .background
                DispatchQueue.global(qos: qos).async {
                    lock.locked { counter.increment() }
                    group.leave()
                }
            }
        }

        group.wait()

        XCTAssertEqual(iterations, first.currentValue)
        XCTAssertEqual(iterations, second.currentValue)
        XCTAssertEqual(iterations, third.currentValue)
    }

    func testMultipleCountersWithRecursiveLockWithDifferentQoS() {
        let iterations = 100_000
        let first = Counter()
        let second = Counter()
        let third = Counter()
        let counters = [first, second, third]
        let lock = RecursiveLock()

        let group = DispatchGroup()

        (0..<iterations).forEach { iteration in
            counters.forEach { counter in
                group.enter()
                let qos: DispatchQoS.QoSClass = Bool.random() ? .userInteractive : .background
                DispatchQueue.global(qos: qos).async {
                    lock.locked { counter.increment() }
                    group.leave()
                }
            }
        }

        group.wait()

        XCTAssertEqual(iterations, first.currentValue)
        XCTAssertEqual(iterations, second.currentValue)
        XCTAssertEqual(iterations, third.currentValue)
    }

    func testRecursiveCalls() {
        var count = 0

        let lock = RecursiveLock()
        let queue = DispatchQueue(label: "RecursiveCounterQueue")
        let group = DispatchGroup()

        group.enter()
        lock.locked {
            count += 1
            queue.sync {
                lock.locked {
                    group.enter()
                    count += 1
                    group.leave()
                }
            }
            group.leave()
        }
        group.wait()

        XCTAssertEqual(2, count)
    }

    func testPerformanceOfLock() {
        measure {
            let iterations = 100_000
            let first = Counter()
            let second = Counter()
            let third = Counter()
            let counters = [first, second, third]
            let lock = Lock()

            let group = DispatchGroup()

            (0..<iterations).forEach { iteration in
                counters.forEach { counter in
                    group.enter()
                    let qos: DispatchQoS.QoSClass = Bool.random() ? .userInteractive : .background
                    DispatchQueue.global(qos: qos).async {
                        lock.locked { counter.increment() }
                        group.leave()
                    }
                }
            }

            group.wait()

            XCTAssertEqual(iterations, first.currentValue)
            XCTAssertEqual(iterations, second.currentValue)
            XCTAssertEqual(iterations, third.currentValue)
        }
    }

    func testPerformanceOfRecursiveLock() {
        measure {
            let iterations = 100_000
            let first = Counter()
            let second = Counter()
            let third = Counter()
            let counters = [first, second, third]
            let lock = RecursiveLock()

            let group = DispatchGroup()

            (0..<iterations).forEach { iteration in
                counters.forEach { counter in
                    group.enter()
                    let qos: DispatchQoS.QoSClass = Bool.random() ? .userInteractive : .background
                    DispatchQueue.global(qos: qos).async {
                        lock.locked { counter.increment() }
                        group.leave()
                    }
                }
            }

            group.wait()

            XCTAssertEqual(iterations, first.currentValue)
            XCTAssertEqual(iterations, second.currentValue)
            XCTAssertEqual(iterations, third.currentValue)
        }
    }

    static var allTests = [
        ("testReturnsValueFromLock", testReturnsValueFromLock),
        ("testReturnsValueFromRecursiveLock", testReturnsValueFromRecursiveLock),
        ("testThrowsErrorFromLock", testThrowsErrorFromLock),
        ("testThrowsErrorFromRecursiveLock", testThrowsErrorFromRecursiveLock),
        ("testCounterWithLock", testCounterWithLock),
        ("testCounterWithRecursiveLock", testCounterWithRecursiveLock),
        ("testCounterWithLockWithDifferentQoS", testCounterWithLockWithDifferentQoS),
        ("testCounterWithRecursiveLockWithDifferentQoS", testCounterWithRecursiveLockWithDifferentQoS),
        ("testMultipleCountersWithLock", testMultipleCountersWithLock),
        ("testMultipleCountersWithRecursiveLock", testMultipleCountersWithRecursiveLock),
        ("testMultipleCountersWithLockWithDifferentQoS", testMultipleCountersWithLockWithDifferentQoS),
        ("testMultipleCountersWithRecursiveLockWithDifferentQoS", testMultipleCountersWithRecursiveLockWithDifferentQoS),
        ("testRecursiveCalls", testRecursiveCalls),
        ("testPerformanceOfLock", testPerformanceOfLock),
        ("testPerformanceOfRecursiveLock", testPerformanceOfRecursiveLock),
    ]
}
