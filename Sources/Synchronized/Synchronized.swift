import Foundation

public func synchronized(_ object: AnyObject, _ block: () -> Void) {
    let queue = getQueue(for: object)
    if queue.isCurrent {
        block()
    } else {
        queue.backing.sync(execute: block)
    }
}

public protocol Synchronized: class { }

extension Synchronized {
    public func sync(_ block: () -> Void) {
        synchronized(self, block)
    }
}
