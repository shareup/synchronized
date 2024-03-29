import Synchronized
import XCTest

final class SynchronizedTests: XCTestCase {
    func testReturnsValueFromLock() {
        let lock = Lock()
        let input = 0
        let output = lock.locked { input + 1 }
        XCTAssertEqual(1, output)
    }

    func testReturnsValueFromRecursiveLock() {
        let lock = RecursiveLock()
        let input = 0
        let output = lock.locked { input + 1 }
        XCTAssertEqual(1, output)
    }

    func testReturnsValueFromLocked() {
        let input = Locked(0)
        let output: Int = input.access { $0 += 1; return $0 }
        XCTAssertEqual(1, output)
        XCTAssertEqual(1, input.access { $0 })
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

    func testLockedElementDoesNotNeedToBeSendable() {
        class ThreadUnsafe {
            var name: String
            init(name: String) { self.name = name }
        }

        let unsafe = Locked(ThreadUnsafe(name: "something"))
        unsafe.access { $0.name = "else" }
        XCTAssertEqual("else", unsafe.access { $0.name })
    }

    func testCounterWithLock() {
        let iterations = 100_000
        let counter = Counter()
        let lock = Lock()
        let group = DispatchGroup()

        (0 ..< iterations).forEach { _ in
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

        (0 ..< iterations).forEach { _ in
            group.enter()
            DispatchQueue.global().async {
                lock.locked { counter.increment() }
                group.leave()
            }
        }

        group.wait()

        XCTAssertEqual(iterations, counter.currentValue)
    }

    func testCounterWithLocked() {
        let iterations = 100_000
        let counter = Locked<Counter>(Counter())
        let group = DispatchGroup()

        (0 ..< iterations).forEach { _ in
            group.enter()
            DispatchQueue.global().async {
                counter.access { $0.increment() }
                group.leave()
            }
        }

        group.wait()

        XCTAssertEqual(iterations, counter.access { $0.currentValue })
    }

    func testCounterWithLockWithDifferentQoS() {
        let iterations = 100_000
        let counter = Counter()
        let lock = Lock()
        let group = DispatchGroup()

        (0 ..< iterations).forEach { _ in
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

        (0 ..< iterations).forEach { _ in
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

    func testCounterWithLockedWithDifferentQoS() {
        let iterations = 100_000
        let counter = Locked(Counter())
        let group = DispatchGroup()

        (0 ..< iterations).forEach { _ in
            group.enter()

            let qos: DispatchQoS.QoSClass = Bool.random() ? .userInteractive : .background
            DispatchQueue.global(qos: qos).async {
                counter.access { $0.increment() }
                group.leave()
            }
        }

        group.wait()

        XCTAssertEqual(iterations, counter.access { $0.currentValue })
    }

    func testSuccessfulTryLockedWithLock() {
        let counter = Counter()
        let lock = Lock()
        XCTAssertTrue(lock.tryLocked { counter.increment() })
        XCTAssertEqual(1, counter.currentValue)
    }

    func testSuccessfulTryLockedWithRecursiveLock() {
        let counter = Counter()
        let lock = RecursiveLock()
        XCTAssertTrue(lock.tryLocked { counter.increment() })
        XCTAssertEqual(1, counter.currentValue)
    }

    func testUnsuccessfulRecursiveTryLockedWithLock() {
        var count = 0

        let lock = Lock()
        let group = DispatchGroup()

        group.enter()
        lock.locked {
            count += 1
            XCTAssertFalse(lock.tryLocked { count += 1 })
            group.leave()
        }
        group.wait()

        XCTAssertEqual(1, count)
    }

    func testUnsuccessfulTryLockedWithLock() {
        let iterations = 100_000
        let counter = Counter()
        let lock = Lock()
        let group = DispatchGroup()

        (0 ..< iterations).forEach { _ in
            group.enter()
            DispatchQueue.global().async {
                _ = lock.tryLocked { counter.increment() }
                group.leave()
            }
        }

        group.wait()

        XCTAssertNotEqual(iterations, counter.currentValue)
    }

    func testUnsuccessfulTryLockedWithRecursiveLock() {
        let iterations = 100_000
        let counter = Counter()
        let lock = RecursiveLock()
        let group = DispatchGroup()

        (0 ..< iterations).forEach { _ in
            group.enter()
            DispatchQueue.global().async {
                _ = lock.tryLocked { counter.increment() }
                group.leave()
            }
        }

        group.wait()

        XCTAssertNotEqual(iterations, counter.currentValue)
    }

    func testMultipleCountersWithLock() {
        let iterations = 100_000
        let first = Counter()
        let second = Counter()
        let third = Counter()
        let counters = [first, second, third]
        let lock = Lock()

        let group = DispatchGroup()

        (0 ..< iterations).forEach { _ in
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

        (0 ..< iterations).forEach { _ in
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

        (0 ..< iterations).forEach { _ in
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

        (0 ..< iterations).forEach { _ in
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
        let group = DispatchGroup()

        group.enter()
        lock.locked {
            count += 1
            lock.locked {
                count += 1
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

            (0 ..< iterations).forEach { _ in
                counters.forEach { counter in
                    group.enter()
                    let qos: DispatchQoS.QoSClass = Bool
                        .random() ? .userInteractive : .background
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

            (0 ..< iterations).forEach { _ in
                counters.forEach { counter in
                    group.enter()
                    let qos: DispatchQoS.QoSClass = Bool
                        .random() ? .userInteractive : .background
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
}
