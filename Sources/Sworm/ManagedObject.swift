import CoreData.NSManagedObject

public struct ManagedObject<PlainObject: ManagedObjectConvertible> {
    unowned let instance: NSManagedObject

    // MARK: - Full object

    public func decode() throws -> PlainObject {
        try .init(from: self.instance)
    }

    // MARK: - Single attribute

    public func decode<Attribute: SupportedAttributeType>(
        attribute keyPath: KeyPath<PlainObject, Attribute>
    ) throws -> Attribute {
        try Attribute.decodeAny(self.instance[
            primitiveValue: PlainObject.attribute(keyPath).name
        ])
    }

    public func decode<Attribute: SupportedAttributeType>(
        attribute keyPath: KeyPath<PlainObject, Attribute?>
    ) throws -> Attribute? {
        try Attribute?.decodeAny(self.instance[
            primitiveValue: PlainObject.attribute(keyPath).name
        ])
    }

    // MARK: - To one relation

    public subscript<Destination: ManagedObjectConvertible>(
        _ keyPath: KeyPath<PlainObject.Relations, ToOneRelation<Destination>>
    ) -> ManagedObject<Destination>? {
        let destination = PlainObject.relations[keyPath: keyPath]

        return (self.instance[primitiveValue: destination.name] as? NSManagedObject).flatMap {
            .init(instance: $0)
        }
    }

    // MARK: - To many relation

    public subscript<Destination: ManagedObjectConvertible>(
        _ keyPath: KeyPath<PlainObject.Relations, ToManyRelation<Destination>>
    ) -> ManagedObjectSet<Destination> {
        let destination = PlainObject.relations[keyPath: keyPath]

        return .init(
            newIterator: {
                self.instance[mutableSet: destination.name].makeIterator()
            }
        )
    }

    public subscript<Destination: ManagedObjectConvertible>(
        _ keyPath: KeyPath<PlainObject.Relations, ToManyOrderedRelation<Destination>>
    ) -> ManagedObjectSet<Destination> {
        let destination = PlainObject.relations[keyPath: keyPath]

        return .init(
            newIterator: {
                self.instance[mutableOrderedSet: destination.name].makeIterator()
            }
        )
    }
}

public struct MutableManagedObject<PlainObject: ManagedObjectConvertible> {
    unowned let instance: NSManagedObject

    // MARK: - Full object

    public func decode() throws -> PlainObject {
        try .init(from: self.instance)
    }

    public mutating func encode(_ value: PlainObject) {
        value.encodeAttributes(to: self.instance)
    }

    // MARK: - Single attribute

    public func decode<Attribute: SupportedAttributeType>(
        attribute keyPath: KeyPath<PlainObject, Attribute>
    ) throws -> Attribute {
        try Attribute.decodeAny(self.instance[
            primitiveValue: PlainObject.attribute(keyPath).name
        ])
    }

    public func decode<Attribute: SupportedAttributeType>(
        attribute keyPath: KeyPath<PlainObject, Attribute?>
    ) throws -> Attribute? {
        try Attribute?.decodeAny(self.instance[
            primitiveValue: PlainObject.attribute(keyPath).name
        ])
    }

    public mutating func encode<Attribute: SupportedAttributeType>(
        attribute keyPath: KeyPath<PlainObject, Attribute>,
        _ value: Attribute
    ) {
        self.instance[primitiveValue: PlainObject.attribute(keyPath).name] = value.encodePrimitiveValue()
    }

    public mutating func encode<Attribute: SupportedAttributeType>(
        attribute keyPath: KeyPath<PlainObject, Attribute?>,
        _ value: Attribute?
    ) {
        self.instance[primitiveValue: PlainObject.attribute(keyPath).name] = value?.encodePrimitiveValue()
    }

    // MARK: - To one relation

    public subscript<Destination: ManagedObjectConvertible>(
        _ keyPath: KeyPath<PlainObject.Relations, ToOneRelation<Destination>>
    ) -> MutableManagedObject<Destination>? {
        get {
            let destination = PlainObject.relations[keyPath: keyPath]

            return (self.instance[primitiveValue: destination.name] as? NSManagedObject).flatMap {
                .init(instance: $0)
            }
        }
        set {
            let destination = PlainObject.relations[keyPath: keyPath]

            self.instance[primitiveValue: destination.name] = newValue?.instance
        }
    }

    public mutating func set<Destination: ManagedObjectConvertible>(
        _ keyPath: KeyPath<PlainObject.Relations, ToOneRelation<Destination>>,
        object: ManagedObject<Destination>?
    ) {
        let destination = PlainObject.relations[keyPath: keyPath]

        self.instance[primitiveValue: destination.name] = object?.instance
    }

    public mutating func set<Destination: ManagedObjectConvertible>(
        _ keyPath: KeyPath<PlainObject.Relations, ToOneRelation<Destination>>,
        value: Destination?
    ) {
        let destination = PlainObject.relations[keyPath: keyPath]

        self.instance[primitiveValue: destination.name] = value?.encodeAttributes(
            to: self.instance[primitiveValue: destination.name] as? NSManagedObject ??
                self.instance.new(relation: destination.name)
        )
    }

    // MARK: - To many relation

    public subscript<Destination: ManagedObjectConvertible>(
        _ keyPath: KeyPath<PlainObject.Relations, ToManyRelation<Destination>>
    ) -> MutableManagedObjectSet<Destination> {
        get {
            let destination = PlainObject.relations[keyPath: keyPath]

            return .init(
                newObject: {
                    self.instance.new(relation: destination.name)
                },
                newIterator: {
                    self.instance[mutableSet: destination.name].makeIterator()
                },
                removeObject: {
                    self.instance[mutableSet: destination.name].remove($0)
                },
                addObject: {
                    self.instance[mutableSet: destination.name].add($0)
                }
            )
        }
        set {}
    }

    public subscript<Destination: ManagedObjectConvertible>(
        _ keyPath: KeyPath<PlainObject.Relations, ToManyOrderedRelation<Destination>>
    ) -> MutableManagedObjectSet<Destination> {
        get {
            let destination = PlainObject.relations[keyPath: keyPath]

            return .init(
                newObject: {
                    self.instance.new(relation: destination.name)
                },
                newIterator: {
                    self.instance[mutableOrderedSet: destination.name].makeIterator()
                },
                removeObject: {
                    self.instance[mutableOrderedSet: destination.name].remove($0)
                },
                addObject: {
                    self.instance[mutableOrderedSet: destination.name].add($0)
                }
            )
        }
        set {}
    }
}
