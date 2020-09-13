public protocol SupportedAttributeType {
    func encodePrimitive() -> Any?

    static func decodePrimitive(value: Any?) throws -> Self
}

public protocol EquatableAttribute {}

public protocol ComparableAttribute: EquatableAttribute {}
