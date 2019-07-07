import Foundation

final class Queue {
    let backing: DispatchQueue

    private let _queueKey: DispatchSpecificKey<Int>
    private lazy var _queueContext: Int = unsafeBitCast(self, to: Int.self)

    init() {
        _queueKey = DispatchSpecificKey<Int>()
        backing = DispatchQueue(label: UUID().uuidString)
        backing.setSpecific(key: _queueKey, value: _queueContext)
    }

    var isCurrent: Bool {
        return DispatchQueue.getSpecific(key: _queueKey) == _queueContext
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
        lock.tryLocked {
            var keysToRemove = Array<WeakWrapper>()
            for (key, _) in objectToQueueMap {
                if key.doesNotExist {
                    keysToRemove.append(key)
                }
            }
            keysToRemove.forEach { objectToQueueMap.removeValue(forKey: $0) }
        }
    }
}
