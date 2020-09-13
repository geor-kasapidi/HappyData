import Foundation

public struct JSON<T: Codable>: SupportedAttributeType {
    public var value: T

    public init(_ value: T) {
        self.value = value
    }

    public func encodePrimitive() -> Any? {
        try? JSONEncoder().encode(self.value)
    }

    public static func decodePrimitive(value: Any?) throws -> JSON<T> {
        guard let data = value as? Data else {
            throw AttributeError.invalidInput
        }
        return .init(try JSONDecoder().decode(T.self, from: data))
    }
}

extension JSON: Equatable where T: Equatable {}

extension JSON: Hashable where T: Hashable {}
