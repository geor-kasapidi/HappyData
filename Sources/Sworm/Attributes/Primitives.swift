import Foundation.NSData
import Foundation.NSDate
import Foundation.NSDecimal
import Foundation.NSURL
import Foundation.NSUUID

public extension PrimitiveAttribute {
    func encodePrimitiveValue() -> Self { self }

    static func decode(primitiveValue: Self) throws -> Self { primitiveValue }
}

extension Bool: PrimitiveAttribute, SupportedAttributeType { public static let metadata: PrimitiveAttributeMetadata = .init() }
extension Int: PrimitiveAttribute, SupportedAttributeType { public static let metadata: PrimitiveAttributeMetadata = .init() }
extension Int16: PrimitiveAttribute, SupportedAttributeType { public static let metadata: PrimitiveAttributeMetadata = .init() }
extension Int32: PrimitiveAttribute, SupportedAttributeType { public static let metadata: PrimitiveAttributeMetadata = .init() }
extension Int64: PrimitiveAttribute, SupportedAttributeType { public static let metadata: PrimitiveAttributeMetadata = .init() }
extension Float: PrimitiveAttribute, SupportedAttributeType { public static let metadata: PrimitiveAttributeMetadata = .init() }
extension Double: PrimitiveAttribute, SupportedAttributeType { public static let metadata: PrimitiveAttributeMetadata = .init() }
extension Decimal: PrimitiveAttribute, SupportedAttributeType { public static let metadata: PrimitiveAttributeMetadata = .init() }
extension Date: PrimitiveAttribute, SupportedAttributeType { public static let metadata: PrimitiveAttributeMetadata = .init() }
extension String: PrimitiveAttribute, SupportedAttributeType { public static let metadata: PrimitiveAttributeMetadata = .init() }
extension Data: PrimitiveAttribute, SupportedAttributeType { public static let metadata: PrimitiveAttributeMetadata = .init() }
extension UUID: PrimitiveAttribute, SupportedAttributeType { public static let metadata: PrimitiveAttributeMetadata = .init() }
extension URL: PrimitiveAttribute, SupportedAttributeType { public static let metadata: PrimitiveAttributeMetadata = .init() }
