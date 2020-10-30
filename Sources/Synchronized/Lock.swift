import Foundation

public final class Lock {
    private var _backing: UnsafeMutablePointer<os_unfair_lock>

    public init() {
        _backing = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        _backing.initialize(to: os_unfair_lock())
    }

    deinit {
        _backing.deallocate()
    }

    public func locked<T>(_ block: () throws -> T) rethrows -> T {
        // https://developer.apple.com/documentation/os/1646466-os_unfair_lock_lock
        os_unfair_lock_lock(_backing)
        defer { os_unfair_lock_unlock(_backing) }
        return try block()
    }

    public func tryLocked(_ block: () throws -> Void) rethrows -> Bool {
        // https://developer.apple.com/documentation/os/1646469-os_unfair_lock_trylock
        if os_unfair_lock_trylock(_backing) {
            defer { os_unfair_lock_unlock(_backing) }
            try block()
            return true
        } else {
            return false
        }
    }
}
