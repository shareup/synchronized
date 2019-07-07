import Foundation
import Synchronized

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
