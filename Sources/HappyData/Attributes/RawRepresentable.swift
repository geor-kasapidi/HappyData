extension RawRepresentable where RawValue: PrimitiveAttribute {
    public func encodePrimitive() -> Any? {
        self.rawValue.encodePrimitive()
    }

    public static func decodePrimitive(value: Any?) throws -> Self {
        let rawValue = try RawValue.decodePrimitive(value: value)
        guard let value = Self.init(rawValue: rawValue) else {
            throw AttributeError.invalidInput
        }
        return value
    }
}
