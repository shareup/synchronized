import Foundation

public struct Locked<Element: Sendable>: @unchecked Sendable {
    private final class Lock: ManagedBuffer<Element, os_unfair_lock> {
        deinit {
            withUnsafeMutablePointerToElements { lock in
                _ = lock.deinitialize(count: 1)
            }
        }
    }

    private let buffer: ManagedBuffer<Element, os_unfair_lock>

    public init(_ element: Element) {
        buffer = Lock.create(minimumCapacity: 1) { buffer in
            buffer.withUnsafeMutablePointerToElements { $0.initialize(to: os_unfair_lock()) }
            return element
        }
    }

    public func access<Return>(_ block: (inout Element) throws -> Return) rethrows -> Return {
        try buffer.withUnsafeMutablePointers { element, lock in
            os_unfair_lock_lock(lock)
            defer { os_unfair_lock_unlock(lock) }
            return try block(&element.pointee)
        }
    }
}
