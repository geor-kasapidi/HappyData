import Foundation
import CoreData

public struct Attribute<PlainObject: ManagedObjectConvertible>: Hashable {
    let name: String
    let keyPath: PartialKeyPath<PlainObject>
    let encode: (PlainObject, NSManagedObject) -> Void
    let decode: (inout PlainObject, NSManagedObject) throws -> Void

    public init<Attribute: SupportedAttributeType>(
        _ keyPath: WritableKeyPath<PlainObject, Attribute>,
        _ name: String
    ) {
        self.name = name
        self.keyPath = keyPath
        self.encode = { plainObject, managedObject in
            managedObject[primitiveKey: name] = plainObject[keyPath: keyPath].encodePrimitive()
        }
        self.decode = { plainObject, managedObject in
            let primitiveValue = managedObject[primitiveKey: name]
            do {
                plainObject[keyPath: keyPath] = try Attribute.decodePrimitive(
                    value: primitiveValue
                )
            } catch {
                throw AttributeError.badAttribute(
                    name: name,
                    entity: managedObject.entity.name ?? "",
                    value: primitiveValue,
                    originalError: error
                )
            }
        }
    }

    public init<Attribute: SupportedAttributeType>(
        _ keyPath: ReferenceWritableKeyPath<PlainObject, Attribute>,
        _ name: String
    ) {
        self.name = name
        self.keyPath = keyPath
        self.encode = { plainObject, managedObject in
            managedObject[primitiveKey: name] = plainObject[keyPath: keyPath].encodePrimitive()
        }
        self.decode = { plainObject, managedObject in
            let primitiveValue = managedObject[primitiveKey: name]
            do {
                plainObject[keyPath: keyPath] = try Attribute.decodePrimitive(
                    value: primitiveValue
                )
            } catch {
                throw AttributeError.badAttribute(
                    name: name,
                    entity: managedObject.entity.name ?? "",
                    value: primitiveValue,
                    originalError: error
                )
            }
        }
    }

    public func hash(into hasher: inout Hasher) {
        self.keyPath.hash(into: &hasher)
    }

    public static func == (lhs: Attribute<PlainObject>, rhs: Attribute<PlainObject>) -> Bool {
        return lhs.keyPath == rhs.keyPath
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
