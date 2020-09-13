import Foundation

public prefix func ! (
    original: Predicate
) -> Predicate {
    return Query.not(original)
}

public func && (
    left: Predicate,
    right: Predicate
) -> Predicate {
    return Query.and(left, right)
}

public func || (
    left: Predicate,
    right: Predicate
) -> Predicate {
    return Query.or(left, right)
}

public func == <PlainObject: ManagedObjectConvertible, Attribute: SupportedAttributeType & EquatableAttribute>(
    keyPath: KeyPath<PlainObject, Attribute>,
    value: Attribute
) -> Predicate {
    return Query.equalTo(keyPath, value)
}

public func != <PlainObject: ManagedObjectConvertible, Attribute: SupportedAttributeType & EquatableAttribute>(
    keyPath: KeyPath<PlainObject, Attribute>,
    value: Attribute
) -> Predicate {
    return Query.notEqualTo(keyPath, value)
}

public func > <PlainObject: ManagedObjectConvertible, Attribute: SupportedAttributeType & ComparableAttribute>(
    keyPath: KeyPath<PlainObject, Attribute>,
    value: Attribute
) -> Predicate {
    return Query.greaterThan(keyPath, value)
}

public func < <PlainObject: ManagedObjectConvertible, Attribute: SupportedAttributeType & ComparableAttribute>(
    keyPath: KeyPath<PlainObject, Attribute>,
    value: Attribute
) -> Predicate {
    return Query.lessThan(keyPath, value)
}

public func >= <PlainObject: ManagedObjectConvertible, Attribute: SupportedAttributeType & ComparableAttribute>(
    keyPath: KeyPath<PlainObject, Attribute>,
    value: Attribute
) -> Predicate {
    return Query.greaterThanOrEqualTo(keyPath, value)
}

public func <= <PlainObject: ManagedObjectConvertible, Attribute: SupportedAttributeType & ComparableAttribute>(
    keyPath: KeyPath<PlainObject, Attribute>,
    value: Attribute
) -> Predicate {
    return Query.lessThanOrEqualTo(keyPath, value)
}

public func === <PlainObject: ManagedObjectConvertible, Attribute: SupportedAttributeType & EquatableAttribute>(
    keyPath: KeyPath<PlainObject, Attribute>,
    values: [Attribute]
) -> Predicate {
    return Query.in(keyPath, values)
}
