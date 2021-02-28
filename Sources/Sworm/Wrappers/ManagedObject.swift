import CoreData

@dynamicMemberLookup
public final class ManagedObject<PlainObject: ManagedObjectConvertible> {
    unowned let instance: NSManagedObject

    internal init(instance: NSManagedObject) {
        self.instance = instance
    }

    // MARK: - Decode

    public func decode() throws -> PlainObject {
        try .init(from: self.instance)
    }

    public func decode<Attribute: SupportedAttributeType>(
        _ keyPath: KeyPath<PlainObject, Attribute>
    ) throws -> Attribute {
        try Attribute.decode(self.instance[
            primitiveValue: PlainObject.attribute(keyPath).name
        ])
    }

    public func decode<Attribute: SupportedAttributeType>(
        _ keyPath: KeyPath<PlainObject, Attribute?>
    ) throws -> Attribute? {
        try Attribute?.decode(self.instance[
            primitiveValue: PlainObject.attribute(keyPath).name
        ])
    }

    // MARK: - Encode

    @discardableResult
    public func encode(_ value: PlainObject) -> Self {
        value.encodeAttributes(to: self.instance)

        return self
    }

    @discardableResult
    public func encode<Attribute: SupportedAttributeType>(
        _ keyPath: KeyPath<PlainObject, Attribute>,
        _ value: Attribute
    ) -> Self {
        self.instance[primitiveValue: PlainObject.attribute(keyPath).name] = value.encodePrimitiveValue()

        return self
    }

    @discardableResult
    public func encode<Attribute: SupportedAttributeType>(
        _ keyPath: KeyPath<PlainObject, Attribute?>,
        _ value: Attribute?
    ) -> Self {
        self.instance[primitiveValue: PlainObject.attribute(keyPath).name] = value?.encodePrimitiveValue()

        return self
    }

    // MARK: - Relations

    public subscript<Destination: ManagedObjectConvertible>(
        dynamicMember keyPath: KeyPath<PlainObject.Relations, ToOneRelation<Destination>>
    ) -> ManagedObject<Destination>? {
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

    public subscript<Destination: ManagedObjectConvertible>(
        dynamicMember keyPath: KeyPath<PlainObject.Relations, ToManyRelation<Destination>>
    ) -> ManagedObjectSet<Destination> {
        let destination = PlainObject.relations[keyPath: keyPath]

        return .init(name: destination.name, instance: self.instance)
    }

    public subscript<Destination: ManagedObjectConvertible>(
        dynamicMember keyPath: KeyPath<PlainObject.Relations, ToManyOrderedRelation<Destination>>
    ) -> ManagedObjectOrderedSet<Destination> {
        let destination = PlainObject.relations[keyPath: keyPath]

        return .init(name: destination.name, instance: self.instance)
    }
}

public extension ManagedObject {
    @discardableResult
    func set<Destination: ManagedObjectConvertible>(
        _ keyPath: KeyPath<PlainObject.Relations, ToOneRelation<Destination>>,
        value: Destination,
        in context: ManagedObjectContext
    ) -> ManagedObject<Destination> {
        if let currentObject = self[dynamicMember: keyPath] {
            return currentObject.encode(value)
        }

        let newObject = context.insert(value)
        self[dynamicMember: keyPath] = newObject
        return newObject
    }
}
