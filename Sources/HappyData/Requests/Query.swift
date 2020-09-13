import Foundation

public enum Query {}

extension Query {
    public static func not(
        _ original: Predicate
    ) -> Predicate {
        return InversePredicate(
            original: original
        )
    }
}

extension Query {
    public static func and(
        _ left: Predicate,
        _ right: Predicate
    ) -> Predicate {
        return CompoundPredicate(
            left: left,
            right: right,
            operator: .and
        )
    }

    public static func or(
        _ left: Predicate,
        _ right: Predicate
    ) -> Predicate {
        return CompoundPredicate(
            left: left,
            right: right,
            operator: .or
        )
    }
}

extension Query {
    public static func equalTo<PlainObject: ManagedObjectConvertible, Attribute: SupportedAttributeType & EquatableAttribute>(
        _ keyPath: KeyPath<PlainObject, Attribute>,
        _ value: Attribute
    ) -> Predicate {
        return ComparisonPredicate<PlainObject>(
            keyPath: keyPath,
            value: value.encodePrimitive(),
            operator: .equalTo
        )
    }

    public static func notEqualTo<PlainObject: ManagedObjectConvertible, Attribute: SupportedAttributeType & EquatableAttribute>(
        _ keyPath: KeyPath<PlainObject, Attribute>,
        _ value: Attribute
    ) -> Predicate {
        return ComparisonPredicate<PlainObject>(
            keyPath: keyPath,
            value: value.encodePrimitive(),
            operator: .notEqualTo
        )
    }

    public static func greaterThan<PlainObject: ManagedObjectConvertible, Attribute: SupportedAttributeType & ComparableAttribute>(
        _ keyPath: KeyPath<PlainObject, Attribute>,
        _ value: Attribute
    ) -> Predicate {
        return ComparisonPredicate<PlainObject>(
            keyPath: keyPath,
            value: value.encodePrimitive(),
            operator: .greaterThan
        )
    }

    public static func lessThan<PlainObject: ManagedObjectConvertible, Attribute: SupportedAttributeType & ComparableAttribute>(
        _ keyPath: KeyPath<PlainObject, Attribute>,
        _ value: Attribute
    ) -> Predicate {
        return ComparisonPredicate<PlainObject>(
            keyPath: keyPath,
            value: value.encodePrimitive(),
            operator: .lessThan
        )
    }

    public static func greaterThanOrEqualTo<PlainObject: ManagedObjectConvertible, Attribute: SupportedAttributeType & ComparableAttribute>(
        _ keyPath: KeyPath<PlainObject, Attribute>,
        _ value: Attribute
    ) -> Predicate {
        return ComparisonPredicate<PlainObject>(
            keyPath: keyPath,
            value: value.encodePrimitive(),
            operator: .greaterThanOrEqualTo
        )
    }

    public static func lessThanOrEqualTo<PlainObject: ManagedObjectConvertible, Attribute: SupportedAttributeType & ComparableAttribute>(
        _ keyPath: KeyPath<PlainObject, Attribute>,
        _ value: Attribute
    ) -> Predicate {
        return ComparisonPredicate<PlainObject>(
            keyPath: keyPath,
            value: value.encodePrimitive(),
            operator: .lessThanOrEqualTo
        )
    }

    public static func `in`<PlainObject: ManagedObjectConvertible, Attribute: SupportedAttributeType & EquatableAttribute>(
        _ keyPath: KeyPath<PlainObject, Attribute>,
        _ values: [Attribute]
    ) -> Predicate {
        return ComparisonPredicate<PlainObject>(
            keyPath: keyPath,
            value: values.map({ $0.encodePrimitive() }),
            operator: .in
        )
    }
}

extension Query {
    public static func contains<PlainObject: ManagedObjectConvertible>(
        _ keyPath: KeyPath<PlainObject, String>,
        _ value: String,
        caseInsensitive: Bool = true
    ) -> Predicate {
        return TextPredicate<PlainObject>(
            keyPath: keyPath,
            value: value,
            operator: .contains,
            caseInsensitive: caseInsensitive
        )
    }

    public static func contains<PlainObject: ManagedObjectConvertible>(
        _ keyPath: KeyPath<PlainObject, Optional<String>>,
        _ value: String,
        caseInsensitive: Bool = true
    ) -> Predicate {
        return TextPredicate<PlainObject>(
            keyPath: keyPath,
            value: value,
            operator: .contains,
            caseInsensitive: caseInsensitive
        )
    }

    public static func beginsWith<PlainObject: ManagedObjectConvertible>(
        _ keyPath: KeyPath<PlainObject, String>,
        _ value: String,
        caseInsensitive: Bool = true
    ) -> Predicate {
        return TextPredicate<PlainObject>(
            keyPath: keyPath,
            value: value,
            operator: .beginsWith,
            caseInsensitive: caseInsensitive
        )
    }

    public static func beginsWith<PlainObject: ManagedObjectConvertible>(
        _ keyPath: KeyPath<PlainObject, Optional<String>>,
        _ value: String,
        caseInsensitive: Bool = true
    ) -> Predicate {
        return TextPredicate<PlainObject>(
            keyPath: keyPath,
            value: value,
            operator: .beginsWith,
            caseInsensitive: caseInsensitive
        )
    }

    public static func endsWith<PlainObject: ManagedObjectConvertible>(
        _ keyPath: KeyPath<PlainObject, String>,
        _ value: String,
        caseInsensitive: Bool = true
    ) -> Predicate {
        return TextPredicate<PlainObject>(
            keyPath: keyPath,
            value: value,
            operator: .endsWith,
            caseInsensitive: caseInsensitive
        )
    }

    public static func endsWith<PlainObject: ManagedObjectConvertible>(
        _ keyPath: KeyPath<PlainObject, Optional<String>>,
        _ value: String,
        caseInsensitive: Bool = true
    ) -> Predicate {
        return TextPredicate<PlainObject>(
            keyPath: keyPath,
            value: value,
            operator: .endsWith,
            caseInsensitive: caseInsensitive
        )
    }
}
