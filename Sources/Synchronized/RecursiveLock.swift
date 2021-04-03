import Foundation

public final class RecursiveLock {
    private var backing: UnsafeMutablePointer<pthread_mutex_t>

    public init() {
        backing = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
        backing.initialize(to: pthread_mutex_t())

        var attributes = pthread_mutexattr_t()
        guard pthread_mutexattr_init(&attributes) == 0
        else { preconditionFailure() }

        guard pthread_mutexattr_settype(&attributes, PTHREAD_MUTEX_RECURSIVE) == 0
        else { preconditionFailure() }

        guard pthread_mutex_init(backing, &attributes) == 0
        else { preconditionFailure() }

        pthread_mutexattr_destroy(&attributes)
    }

    deinit {
        pthread_mutex_destroy(backing)
        backing.deinitialize(count: 1)
        backing.deallocate()
    }

    public func locked<T>(_ block: () throws -> T) rethrows -> T {
        let ret = pthread_mutex_lock(backing)
        // https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/pthread_mutex_lock.3.html
        precondition(ret == 0, "Could not acquire lock: '\(ret)'")
        defer { pthread_mutex_unlock(backing) }
        return try block()
    }

    public func tryLocked(_ block: () throws -> Void) rethrows -> Bool {
        // https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/pthread_mutex_trylock.3.html#//apple_ref/doc/man/3/pthread_mutex_trylock
        if pthread_mutex_trylock(backing) == 0 {
            defer { pthread_mutex_unlock(backing) }
            try block()
            return true
        } else {
            return false
        }
    }
}
