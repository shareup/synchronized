import XCTest
@testable import Synchronized

final class SynchronizedTests: XCTestCase {
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

    static var allTests = [
        ("testCounterWithSynchronized", testCounterWithSynchronized),
        ("testCounterWithSynchronizedAndSync", testCounterWithSynchronizedAndSync),
        ("testCounterWithSynchronizedWithDifferentQoS", testCounterWithSynchronizedWithDifferentQoS),
        ("testMultipleCountersWithSynchronized", testMultipleCountersWithSynchronized),
        ("testMultipleCountersWithSynchronizedWithDifferentQoS", testMultipleCountersWithSynchronizedWithDifferentQoS),
    ]
}
