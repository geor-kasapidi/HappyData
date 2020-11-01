public extension RawRepresentable where RawValue: PrimitiveAttribute {
    func encodePrimitiveValue() -> RawValue {
        self.rawValue.encodePrimitiveValue()
    }

    static func decode(primitiveValue: RawValue) throws -> Self {
        let rawValue = try RawValue.decode(primitiveValue: primitiveValue)
        guard let value = Self(rawValue: rawValue) else {
            throw AttributeError.badInput(rawValue)
        }
        return value
    }
}
