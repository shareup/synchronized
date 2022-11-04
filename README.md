# synchronized

Synchronized provides a simple Swift-y implementation of a lock and a recursive lock. `Lock` wraps `os_unfair_lock`. `RecursiveLock` wraps `pthread_mutex_t`. Synchronized's API is designed for convenience and simplicity.

The two lock's APIs are identical and limited to two public methods: `func locked<T>(_ block: () throws -> T) rethrows -> T` and `func tryLocked(_ block: () throws -> Void) rethrows`. `locked()` blocks on contention and then executes the supplied closure, returning or throwing the closure's return value or thrown error. `tryLocked()` attemps to acquire the lock. If the lock can be acquired, the supplied closure is executed and `true` is returned. If the lock cannot be acquired, the closure is not executed and `false` is returned.

Synchronized also provides `Locked` which wraps an entity and only allows access to it via the secure method `access(_:)`. `Locked` makes it easy to ensure your class only accesses its mutable state in a safe manner.

## @synchonized replacement 

_Synchronized started life as a simple (and simplified) re-implmentation of [Objective-C's @synchronized](http://www.opensource.apple.com/source/objc4/objc4-646/runtime/objc-sync.mm) for Swift. If you're interested in that version, you should look at [v1.2.1](https://github.com/shareup/synchronized/releases/tag/v1.2.1)._ 

## Usage

```swift
let lock = Lock()
let lockInput: Int = 0
let lockOutput = lock.locked { lockInput + 1 }
XCTAssertEqual(1, lockOutput)

let recursiveLock = RecursiveLock()
let recursiveLockInput: Int = 0
let recursiveLockOutput = recursiveLock.locked { recursiveLockInput + 1 }
XCTAssertEqual(1, recursiveLockOutput)

let lockedInput = Locked(0)
lockedInput.access { $0 += 1 }
XCTAssertEqual(1, lockedInput.access { $0 })
```

## Installation

### Swift Package Manager

To use Synchronized with the Swift Package Manager, add a dependency to your Package.swift file:

```swift
let package = Package(
  dependencies: [
    .package(url: "https://github.com/shareup/synchronized.git", .upToNextMajor(from: "4.0.0"))
  ]
)
```

_Linux is not currently supported_
