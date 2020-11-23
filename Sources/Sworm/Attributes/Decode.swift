extension SupportedAttributeType {
    static func decodeAny(_ someValue: Any?) throws -> Self {
        guard let value = someValue as? Self.PrimitiveAttributeType else {
            throw AttributeError.badInput(someValue)
        }
        return try Self.decode(primitiveValue: value)
    }
}

extension Optional where Wrapped: SupportedAttributeType {
    static func decodeAny(_ someValue: Any?) throws -> Wrapped? {
        try someValue.flatMap {
            try Wrapped.decodeAny($0)
        }
    }
}
