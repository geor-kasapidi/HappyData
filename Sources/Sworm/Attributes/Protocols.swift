public struct PrimitiveAttributeMetadata {
    internal init() {}
}

public protocol PrimitiveAttribute {
    static var metadata: PrimitiveAttributeMetadata { get }
}

public protocol SupportedAttributeType {
    associatedtype PrimitiveAttributeType: PrimitiveAttribute

    func encodePrimitiveValue() -> PrimitiveAttributeType

    static func decode(primitiveValue: PrimitiveAttributeType) throws -> Self
}
