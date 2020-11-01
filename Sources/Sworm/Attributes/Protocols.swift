import CoreData

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

public extension PrimitiveAttribute {
    func encodePrimitiveValue() -> Self { self }

    static func decode(primitiveValue: Self) throws -> Self { primitiveValue }
}

extension SupportedAttributeType {
    static func decodeAny(_ someValue: Any?) throws -> Self {
        guard let value = someValue as? Self.PrimitiveAttributeType else {
            throw AttributeError.badInput(someValue)
        }
        return try Self.decode(primitiveValue: value)
    }
}

extension Optional where Wrapped: SupportedAttributeType {
    static func decodeAny(_ someValue: Any?) throws -> Self {
        try someValue.flatMap {
            try Wrapped.decodeAny($0)
        }
    }
}
