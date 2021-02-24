import Foundation
import Sworm

extension CustomAttributeSet.CustomType: SupportedAttributeType {
    func encodePrimitiveValue() -> String {
        self.description
    }

    static func decode(primitiveValue: String) throws -> CustomAttributeSet.CustomType {
        guard let value = CustomAttributeSet.CustomType(primitiveValue) else {
            throw AttributeError.badInput(primitiveValue)
        }
        return value
    }
}

extension CustomAttributeSet.CustomEnumeration: SupportedAttributeType {}

extension PrimitiveAttributeFullSet: ManagedObjectConvertible {
    static let entityName: String = "PrimitiveAttributeFullSet"

    static let attributes: Set<Attribute<PrimitiveAttributeFullSet>> = [
        .init(\.x1, "x1"),
        .init(\.x2, "x2"),
        .init(\.x3, "x3"),
        .init(\.x4, "x4"),
        .init(\.x5, "x5"),
        .init(\.x6, "x6"),
        .init(\.x7, "x7"),
        .init(\.x8, "x8"),
        .init(\.x9, "x9"),
        .init(\.x10, "x10"),
        .init(\.x11, "x11"),
        .init(\.x12, "x12"),
        .init(\.x13, "x13"),
    ]

    static let relations: Void = ()
}

extension CustomAttributeSet: ManagedObjectConvertible {
    static let entityName: String = "CustomAttributeSet"

    static let attributes: Set<Attribute<CustomAttributeSet>> = [
        .init(\.x1, "x1"),
        .init(\.x2, "x2"),
        .init(\.x3, "x3"),
        .init(\.x4, "x4"),
        .init(\.x5, "x5"),
        .init(\.x6, "x6"),
    ]

    static let relations: Void = ()
}

extension DemoAttributeSetRef: ManagedObjectConvertible {
    static let entityName: String = "DemoAttributeSetRef"

    static let attributes: Set<Attribute<DemoAttributeSetRef>> = [
        .init(\.x1, "x1"),
        .init(\.x2, "x2"),
    ]

    static let relations: Void = ()
}
