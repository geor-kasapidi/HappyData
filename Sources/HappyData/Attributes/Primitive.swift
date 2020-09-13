import Foundation

public protocol PrimitiveAttribute: SupportedAttributeType {}

extension PrimitiveAttribute {
    public func encodePrimitive() -> Any? {
        self
    }

    public static func decodePrimitive(value: Any?) throws -> Self {
        guard let value = value as? Self else {
            throw AttributeError.invalidInput
        }
        return value
    }
}

extension Bool: PrimitiveAttribute, EquatableAttribute {}
extension Int: PrimitiveAttribute, ComparableAttribute {}
extension Int16: PrimitiveAttribute, ComparableAttribute {}
extension Int32: PrimitiveAttribute, ComparableAttribute {}
extension Int64: PrimitiveAttribute, ComparableAttribute {}
extension Float: PrimitiveAttribute, ComparableAttribute {}
extension Double: PrimitiveAttribute, ComparableAttribute {}
extension Decimal: PrimitiveAttribute, ComparableAttribute {}
extension Date: PrimitiveAttribute, ComparableAttribute {}
extension String: PrimitiveAttribute, EquatableAttribute {}
extension Data: PrimitiveAttribute, EquatableAttribute {}
extension UUID: PrimitiveAttribute, EquatableAttribute {}
extension URL: PrimitiveAttribute, EquatableAttribute {}
