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
        os_unfair_lock_lock(_backing)
        defer { os_unfair_lock_unlock(_backing) }
        return try block()
    }

    public func tryLocked(_ block: () throws -> Void) rethrows {
        if os_unfair_lock_trylock(_backing) {
            defer { os_unfair_lock_unlock(_backing) }
            try block()
        }
    }
}
