import Foundation

public final class Lock {
    private var backing: UnsafeMutablePointer<os_unfair_lock>

    public init() {
        backing = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        backing.initialize(to: os_unfair_lock())
    }

    deinit {
        backing.deinitialize(count: 1)
        backing.deallocate()
    }

    public func locked<T>(_ block: () throws -> T) rethrows -> T {
        // https://developer.apple.com/documentation/os/1646466-os_unfair_lock_lock
        os_unfair_lock_lock(backing)
        defer { os_unfair_lock_unlock(backing) }
        return try block()
    }

    public func tryLocked(_ block: () throws -> Void) rethrows -> Bool {
        // https://developer.apple.com/documentation/os/1646469-os_unfair_lock_trylock
        if os_unfair_lock_trylock(backing) {
            defer { os_unfair_lock_unlock(backing) }
            try block()
            return true
        } else {
            return false
        }
    }
}
