import XCTest
import Synchronized

final class SynchronizedTests: XCTestCase {
    func testReturnsValueSynchronized() {
        let lock = NSObject()
        let input: Int = 0
        let output = synchronized(lock) { input + 1 }
        XCTAssertEqual(1, output)
    }

	enum TestError: Error {
		case locked
	}

    func testThrowsErrorSynchronized() {
        let lock = NSObject()
        XCTAssertThrowsError(try synchronized(lock, { throw TestError.locked }))
    }

    func testCounterWithSynchronized() {
        let iterations = 100_000
        let counter = Counter()
        let group = DispatchGroup()

        (0..<iterations).forEach { _ in
            group.enter()
            DispatchQueue.global().async {
                synchronized(counter) { counter.increment() }
                group.leave()
            }
        }

        group.wait()

        XCTAssertEqual(iterations, counter.currentValue)
    }

    func testCounterWithSynchronizedAndSync() {
        let iterations = 100_000
        let counter = Counter()
        let group = DispatchGroup()

        (0..<iterations).forEach { iteration in
            group.enter()

            if iteration % 2 == 0 {
                DispatchQueue.global().async {
                    synchronized(counter) { counter.increment() }
                    group.leave()
                }
            } else {
                DispatchQueue.global().async {
                    counter.synchronizedIncrement()
                    group.leave()
                }
            }
        }

        group.wait()

        XCTAssertEqual(iterations, counter.currentValue)
    }

    func testCounterWithSynchronizedWithDifferentQoS() {
        let iterations = 100_000
        let counter = Counter()
        let group = DispatchGroup()

        (0..<iterations).forEach { _ in
            group.enter()

            let qos: DispatchQoS.QoSClass = Bool.random() ? .userInteractive : .background
            DispatchQueue.global(qos: qos).async {
                synchronized(counter) { counter.increment() }
                group.leave()
            }
        }

        group.wait()

        XCTAssertEqual(iterations, counter.currentValue)
    }

    func testMultipleCountersWithSynchronized() {
        let iterations = 100_000
        let first = Counter()
        let second = Counter()
        let third = Counter()
        let counters = [first, second, third]

        let group = DispatchGroup()

        (0..<iterations).forEach { iteration in
            counters.forEach { counter in
                group.enter()
                DispatchQueue.global().async {
                    synchronized(counter) { counter.increment() }
                    group.leave()
                }
            }
        }

        group.wait()

        XCTAssertEqual(iterations, first.currentValue)
        XCTAssertEqual(iterations, second.currentValue)
        XCTAssertEqual(iterations, third.currentValue)
    }

    func testMultipleCountersWithSynchronizedWithDifferentQoS() {
        let iterations = 100_000
        let first = Counter()
        let second = Counter()
        let third = Counter()
        let counters = [first, second, third]

        let group = DispatchGroup()

        (0..<iterations).forEach { iteration in
            counters.forEach { counter in
                group.enter()
                let qos: DispatchQoS.QoSClass = Bool.random() ? .userInteractive : .background
                DispatchQueue.global(qos: qos).async {
                    synchronized(counter) { counter.increment() }
                    group.leave()
                }
            }
        }

        group.wait()

        XCTAssertEqual(iterations, first.currentValue)
        XCTAssertEqual(iterations, second.currentValue)
        XCTAssertEqual(iterations, third.currentValue)
    }

    func testRecursiveCallsToSynchronized() {
        let object = NSObject()
        var count = 0

        let queue = DispatchQueue(label: "RecursiveCounterQueue")
        let group = DispatchGroup()

        group.enter()
        synchronized(object) {
            count += 1
            queue.sync {
                synchronized(object) {
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

    func testPerformanceOfMultipleCountersWithDifferentQoS() {
        measure {
            let iterations = 100_000
            let first = Counter()
            let second = Counter()
            let third = Counter()
            let counters = [first, second, third]

            let group = DispatchGroup()

            (0..<iterations).forEach { iteration in
                counters.forEach { counter in
                    group.enter()
                    let qos: DispatchQoS.QoSClass = Bool.random() ? .userInteractive : .background
                    DispatchQueue.global(qos: qos).async {
                        synchronized(counter) { counter.increment() }
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
        ("testReturnsValueSynchronized", testReturnsValueSynchronized),
        ("testThrowsErrorSynchronized", testThrowsErrorSynchronized),
        ("testCounterWithSynchronized", testCounterWithSynchronized),
        ("testCounterWithSynchronizedAndSync", testCounterWithSynchronizedAndSync),
        ("testCounterWithSynchronizedWithDifferentQoS", testCounterWithSynchronizedWithDifferentQoS),
        ("testMultipleCountersWithSynchronized", testMultipleCountersWithSynchronized),
        ("testMultipleCountersWithSynchronizedWithDifferentQoS", testMultipleCountersWithSynchronizedWithDifferentQoS),
        ("testRecursiveCallsToSynchronized", testRecursiveCallsToSynchronized),
        ("testPerformanceOfMultipleCountersWithDifferentQoS", testPerformanceOfMultipleCountersWithDifferentQoS),
    ]
}
