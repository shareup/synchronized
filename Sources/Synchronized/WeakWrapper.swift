import Foundation

struct WeakWrapper: Hashable {
    private weak var _object: AnyObject?
    private let _id: ObjectIdentifier

    init(_ object: AnyObject) {
        _object = object
        _id = ObjectIdentifier(object)
    }

    var exists: Bool { return doesNotExist == false }
    var doesNotExist: Bool { return _object == nil }

    func hash(into hasher: inout Hasher) {
        _id.hash(into: &hasher)
    }

    static func == (lhs: WeakWrapper, rhs: WeakWrapper) -> Bool {
        return lhs._id == rhs._id
    }
}
