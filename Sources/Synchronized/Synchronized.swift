import Foundation

public func synchronized<T>(_ object: AnyObject, _ block: () throws -> T) rethrows -> T {
    return try getQueue(for: object).sync(block)
}

public protocol Synchronized: class { }

extension Synchronized {
    public func sync<T>(_ block: () throws -> T) rethrows -> T {
        return try synchronized(self, block)
    }
}
