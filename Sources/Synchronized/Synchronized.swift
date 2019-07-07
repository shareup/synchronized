import Foundation

public func synchronized<T>(_ object: AnyObject, _ block: () throws -> T) rethrows -> T {
    let queue = getQueue(for: object)
    if queue.isCurrent {
        return try block()
    } else {
        return try queue.backing.sync(execute: block)
    }
}

public protocol Synchronized: class { }

extension Synchronized {
    public func sync<T>(_ block: () throws -> T) rethrows -> T {
        return try synchronized(self, block)
    }
}
