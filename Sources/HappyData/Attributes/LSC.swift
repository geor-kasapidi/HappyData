public struct LSC<T: LosslessStringConvertible>: SupportedAttributeType {
    public var value: T

    public init(_ value: T) {
        self.value = value
    }

    public func encodePrimitive() -> Any? {
        return self.value.description
    }

    public static func decodePrimitive(value: Any?) throws -> LSC<T> {
        guard let description = value as? String, let value = T(description) else {
            throw AttributeError.invalidInput
        }
        return .init(value)
    }
}

extension LSC: Equatable where T: Equatable {}

extension LSC: Hashable where T: Hashable {}
