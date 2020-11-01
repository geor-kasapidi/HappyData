public struct LSC<T: LosslessStringConvertible>: SupportedAttributeType {
    public var value: T

    public init(_ value: T) {
        self.value = value
    }

    public func encodePrimitiveValue() -> String {
        self.value.description
    }

    public static func decode(primitiveValue: String) throws -> LSC<T> {
        guard let value = T(primitiveValue) else {
            throw AttributeError.badInput(primitiveValue)
        }
        return .init(value)
    }
}

extension LSC: Equatable where T: Equatable {}

extension LSC: Hashable where T: Hashable {}
