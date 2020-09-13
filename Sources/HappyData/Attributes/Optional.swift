extension Optional: SupportedAttributeType where Wrapped: SupportedAttributeType {
    public func encodePrimitive() -> Any? {
        self.flatMap {
            $0.encodePrimitive()
        }
    }

    public static func decodePrimitive(value: Any?) throws -> Optional<Wrapped> {
        try value.flatMap {
            try Wrapped.decodePrimitive(value: $0)
        }
    }
}

extension Optional: EquatableAttribute where Wrapped: EquatableAttribute {}

extension Optional: ComparableAttribute where Wrapped: ComparableAttribute {}
