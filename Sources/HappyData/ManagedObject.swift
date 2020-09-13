import Foundation
import CoreData

public struct ManagedObject<PlainObject: ManagedObjectConvertible> {
    unowned let instance: NSManagedObject

    /// use at your own risk
    public init(_ instance: NSManagedObject) {
        self.instance = instance
    }

    // MARK: - Full object

    public func decode() throws -> PlainObject {
        return try .init(from: self.instance)
    }

    // MARK: - Single attribute

    public func decode<Attribute: SupportedAttributeType>(
        attribute keyPath: KeyPath<PlainObject, Attribute>
    ) throws -> Attribute {
        return try Attribute.decodePrimitive(
            value: self.instance[primitiveKey: PlainObject.attribute(keyPath).name]
        )
    }

    // MARK: - To one relation

    public subscript<Destination: ManagedObjectConvertible>(
        _ keyPath: KeyPath<PlainObject.Relations, ToOneRelation<Destination>>
    ) -> ManagedObject<Destination>? {
        let destination = PlainObject.relations[keyPath: keyPath]

        return (self.instance[primitiveKey: destination.name] as? NSManagedObject).flatMap {
            .init($0)
        }
    }

    // MARK: - To many relation

    public subscript<Destination: ManagedObjectConvertible>(
        _ keyPath: KeyPath<PlainObject.Relations, ToManyRelation<Destination>>
    ) -> ManagedObjectSet<Destination> {
        let destination = PlainObject.relations[keyPath: keyPath]

        return .init(
            newIterator: {
                self.instance.mutableSetValue(forKey: destination.name).makeIterator()
            }
        )
    }

    public subscript<Destination: ManagedObjectConvertible>(
        _ keyPath: KeyPath<PlainObject.Relations, ToManyOrderedRelation<Destination>>
    ) -> ManagedObjectSet<Destination> {
        let destination = PlainObject.relations[keyPath: keyPath]

        return .init(
            newIterator: {
                self.instance.mutableOrderedSetValue(forKey: destination.name).makeIterator()
            }
        )
    }
}

public struct MutableManagedObject<PlainObject: ManagedObjectConvertible> {
    unowned let instance: NSManagedObject

    /// use at your own risk
    public init(_ instance: NSManagedObject) {
        self.instance = instance
    }

    // MARK: - Full object

    public func decode() throws -> PlainObject {
        return try .init(from: self.instance)
    }

    public mutating func encode(_ value: PlainObject) {
        value.encodeAttributes(to: self.instance)
    }

    // MARK: - Single attribute

    public func decode<Attribute: SupportedAttributeType>(
        attribute keyPath: KeyPath<PlainObject, Attribute>
    ) throws -> Attribute {
        return try Attribute.decodePrimitive(
            value: self.instance[primitiveKey: PlainObject.attribute(keyPath).name]
        )
    }

    public mutating func encode<Attribute: SupportedAttributeType>(
        attribute keyPath: KeyPath<PlainObject, Attribute>,
        _ value: Attribute
    ) {
        self.instance[primitiveKey: PlainObject.attribute(keyPath).name] = value.encodePrimitive()
    }

    // MARK: - To one relation

    public subscript<Destination: ManagedObjectConvertible>(
        _ keyPath: KeyPath<PlainObject.Relations, ToOneRelation<Destination>>
    ) -> MutableManagedObject<Destination>? {
        get {
            let destination = PlainObject.relations[keyPath: keyPath]

            return (self.instance[primitiveKey: destination.name] as? NSManagedObject).flatMap {
                .init($0)
            }
        }
        set {
            let destination = PlainObject.relations[keyPath: keyPath]

            self.instance[primitiveKey: destination.name] = newValue?.instance
        }
    }

    public mutating func set<Destination: ManagedObjectConvertible>(
        _ keyPath: KeyPath<PlainObject.Relations, ToOneRelation<Destination>>,
        object: ManagedObject<Destination>?
    ) {
        let destination = PlainObject.relations[keyPath: keyPath]

        self.instance[primitiveKey: destination.name] = object?.instance
    }

    public mutating func set<Destination: ManagedObjectConvertible>(
        _ keyPath: KeyPath<PlainObject.Relations, ToOneRelation<Destination>>,
        value: Destination?
    ) {
        let destination = PlainObject.relations[keyPath: keyPath]

        self.instance[primitiveKey: destination.name] = value?.encodeAttributes(
            to: self.instance[primitiveKey: destination.name] as? NSManagedObject ??
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
                    self.instance.mutableSetValue(forKey: destination.name).makeIterator()
                },
                removeObject: {
                    self.instance.mutableSetValue(forKey: destination.name).remove($0)
                },
                addObject: {
                    self.instance.mutableSetValue(forKey: destination.name).add($0)
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
                    self.instance.mutableOrderedSetValue(forKey: destination.name).makeIterator()
                },
                removeObject: {
                    self.instance.mutableOrderedSetValue(forKey: destination.name).remove($0)
                },
                addObject: {
                    self.instance.mutableOrderedSetValue(forKey: destination.name).add($0)
                }
            )
        }
        set {}
    }
}
