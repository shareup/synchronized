import Foundation

final class Queue {
    private var _backing = pthread_mutex_t()

    init() {
        var attributes = pthread_mutexattr_t()
        guard pthread_mutexattr_init(&attributes) == 0 else { preconditionFailure() }
        pthread_mutexattr_settype(&attributes, PTHREAD_MUTEX_RECURSIVE)
        guard pthread_mutex_init(&_backing, &attributes) == 0 else { preconditionFailure() }
        pthread_mutexattr_destroy(&attributes)
    }

    deinit {
        pthread_mutex_destroy(&_backing)
    }

    func sync<T>(_ block: () throws -> T) rethrows -> T {
        pthread_mutex_lock(&_backing)
        defer { pthread_mutex_unlock(&_backing) }
        return try block()
    }
}

private let lock: Lock = Lock()
private let cleanupQueue = DispatchQueue(label: "Synchronized.cleanupQueue")
private var objectToQueueMap = Dictionary<WeakWrapper, Queue>()
private var cleanupCounter = 0

func getQueue(for object: AnyObject) -> Queue {
    var shouldCleanup: Bool = false
    
    let queue = lock.locked { () -> Queue in
        cleanupCounter += 1
        shouldCleanup = cleanupCounter % 10 == 0

        let queueForObject: Queue
        let wrapper = WeakWrapper(object)
        if let queue = objectToQueueMap[wrapper] {
            queueForObject = queue
        } else {
            queueForObject = Queue()
            objectToQueueMap[wrapper] = queueForObject
        }
        return queueForObject
    }

    if shouldCleanup {
        removeQueuesForDeallocatedObjects()
    }
    
    return queue
}

private func removeQueuesForDeallocatedObjects() {
    cleanupQueue.async {
        var optionalCopy: Dictionary<WeakWrapper, Queue>? = nil
        lock.tryLocked { optionalCopy = objectToQueueMap }

        guard var copy = optionalCopy else { return }
        
        var keysToRemove = Array<WeakWrapper>()
        for (key, _) in copy {
            if key.doesNotExist {
                keysToRemove.append(key)
            }
        }
        keysToRemove.forEach { copy.removeValue(forKey: $0) }

        lock.tryLocked { objectToQueueMap = copy }
    }
}
