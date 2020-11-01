import Foundation

public struct JSON<T: Codable>: SupportedAttributeType {
    public var value: T

    public init(_ value: T) {
        self.value = value
    }

    public func encodePrimitiveValue() -> Data {
        try! JSONEncoder().encode(self.value)
    }

    public static func decode(primitiveValue: Data) throws -> JSON<T> {
        .init(try JSONDecoder().decode(T.self, from: primitiveValue))
    }
}

extension JSON: Equatable where T: Equatable {}

extension JSON: Hashable where T: Hashable {}
