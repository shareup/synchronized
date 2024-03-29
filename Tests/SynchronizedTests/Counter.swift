import Foundation
import Synchronized

final class Counter {
    private var _value: Int = 0

    var currentValue: Int { _value }

    func increment() {
        _value += 1
    }
}
