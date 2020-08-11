# synchronized

Synchronized is a simple (and simplified) re-implmentation of [Objective-C's @synchronized](http://www.opensource.apple.com/source/objc4/objc4-646/runtime/objc-sync.mm) for Swift.

Synchronized enables users to protect access to blocks of code by providing an object pointer as a parameter. The object pointer acts as a lock. Given the same object pointer, only one thread is permitted within a synchronized block at a time. For added convenience, classes are able to add conformance to the empty `Synchronized` protocol. Conforming to `Synchronized` grants the class access to the `sync` function, which uses `self` as the "lock" for blocks passed to it. 

## Usage

```swift
final class Counter: Synchronized {
  private var _value: Int = 0

  var currentValue: Int { return _value }

  func increment() {
    _value += 1
  }

  func synchronizedIncrement() {
    self.sync { _value += 1 }
  }
}

let counter = Counter()

DispatchQueue.global().async {
  synchronized(counter) { counter.increment() }
}
DispatchQueue.global().async {
  counter.synchronizedIncrement()
}
```

## Installation

### Swift Package Manager

To use Synchronized with the Swift Package Manager, add a dependency to your Package.swift file:

```swift
let package = Package(
  dependencies: [
    .package(url: "https://github.com/shareup/synchronized.git", .upToNextMajor(from: "2.0.0"))
  ]
)
```

_Linux is not currently supported_
