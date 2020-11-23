import CoreData.NSManagedObject

public struct Attribute<PlainObject: ManagedObjectConvertible>: Hashable {
    let name: String
    let keyPath: PartialKeyPath<PlainObject>

    let encode: (PlainObject, NSManagedObject) -> Void
    let decode: (inout PlainObject, NSManagedObject) throws -> Void

    // MARK: - Equatable & Hashable

    public func hash(into hasher: inout Hasher) {
        self.keyPath.hash(into: &hasher)
    }

    public static func == (lhs: Attribute<PlainObject>, rhs: Attribute<PlainObject>) -> Bool {
        lhs.keyPath == rhs.keyPath
    }

    // MARK: - Value types

    public init<Attribute: SupportedAttributeType>(
        _ keyPath: WritableKeyPath<PlainObject, Attribute>,
        _ name: String
    ) {
        self.name = name
        self.keyPath = keyPath
        self.encode = { plainObject, managedObject in
            managedObject[primitiveValue: name] = plainObject[keyPath: keyPath].encodePrimitiveValue()
        }
        self.decode = { plainObject, managedObject in
            do {
                plainObject[keyPath: keyPath] = try Attribute.decodeAny(managedObject[primitiveValue: name])
            } catch {
                throw AttributeError.badAttribute(
                    .init(
                        name: name,
                        entity: managedObject.entity.name ?? "",
                        originalError: error
                    )
                )
            }
        }
    }

    public init<Attribute: SupportedAttributeType>(
        _ keyPath: WritableKeyPath<PlainObject, Attribute?>,
        _ name: String
    ) {
        self.name = name
        self.keyPath = keyPath
        self.encode = { plainObject, managedObject in
            managedObject[primitiveValue: name] = plainObject[keyPath: keyPath]?.encodePrimitiveValue()
        }
        self.decode = { plainObject, managedObject in
            do {
                plainObject[keyPath: keyPath] = try Attribute?.decodeAny(managedObject[primitiveValue: name])
            } catch {
                throw AttributeError.badAttribute(
                    .init(
                        name: name,
                        entity: managedObject.entity.name ?? "",
                        originalError: error
                    )
                )
            }
        }
    }

    // MARK: - Reference types

    public init<Attribute: SupportedAttributeType>(
        _ keyPath: ReferenceWritableKeyPath<PlainObject, Attribute>,
        _ name: String
    ) {
        self.name = name
        self.keyPath = keyPath
        self.encode = { plainObject, managedObject in
            managedObject[primitiveValue: name] = plainObject[keyPath: keyPath].encodePrimitiveValue()
        }
        self.decode = { plainObject, managedObject in
            do {
                plainObject[keyPath: keyPath] = try Attribute.decodeAny(managedObject[primitiveValue: name])
            } catch {
                throw AttributeError.badAttribute(
                    .init(
                        name: name,
                        entity: managedObject.entity.name ?? "",
                        originalError: error
                    )
                )
            }
        }
    }

    public init<Attribute: SupportedAttributeType>(
        _ keyPath: ReferenceWritableKeyPath<PlainObject, Attribute?>,
        _ name: String
    ) {
        self.name = name
        self.keyPath = keyPath
        self.encode = { plainObject, managedObject in
            managedObject[primitiveValue: name] = plainObject[keyPath: keyPath]?.encodePrimitiveValue()
        }
        self.decode = { plainObject, managedObject in
            do {
                plainObject[keyPath: keyPath] = try Attribute?.decodeAny(managedObject[primitiveValue: name])
            } catch {
                throw AttributeError.badAttribute(
                    .init(
                        name: name,
                        entity: managedObject.entity.name ?? "",
                        originalError: error
                    )
                )
            }
        }
    }
}

extension ManagedObjectConvertible {
    static func attribute(_ keyPath: PartialKeyPath<Self>) -> Attribute<Self> {
        self.attributes.first(where: { $0.keyPath == keyPath }).unsafelyUnwrapped
    }

    @discardableResult
    func encodeAttributes(to managedObject: NSManagedObject) -> NSManagedObject {
        Self.attributes.forEach {
            $0.encode(self, managedObject)
        }
        return managedObject
    }

    init(from managedObject: NSManagedObject) throws {
        self.init()
        try Self.attributes.forEach {
            try $0.decode(&self, managedObject)
        }
    }
}
