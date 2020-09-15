import Foundation
import CoreData

public struct ManagedObjectSet<PlainObject: ManagedObjectConvertible>: Sequence {
    public struct Iterator: IteratorProtocol {
        var iterator: NSFastEnumerationIterator

        public mutating func next() -> ManagedObject<PlainObject>? {
            return (self.iterator.next() as? NSManagedObject).flatMap {
                .init(instance: $0)
            }
        }
    }

    let newIterator: () -> NSFastEnumerationIterator

    public func makeIterator() -> Iterator {
        return .init(iterator: self.newIterator())
    }
}

public struct MutableManagedObjectSet<PlainObject: ManagedObjectConvertible>: Sequence {
    public struct Iterator: IteratorProtocol {
        var iterator: NSFastEnumerationIterator

        public mutating func next() -> MutableManagedObject<PlainObject>? {
            return (self.iterator.next() as? NSManagedObject).flatMap {
                .init(instance: $0)
            }
        }
    }

    let newObject: () -> NSManagedObject
    let newIterator: () -> NSFastEnumerationIterator
    let removeObject: (NSManagedObject) -> Void
    let addObject: (NSManagedObject) -> Void

    public func makeIterator() -> Iterator {
        return .init(iterator: self.newIterator())
    }

    public mutating func remove(_ value: ManagedObject<PlainObject>) {
        self.removeObject(value.instance)
    }

    public mutating func remove(_ value: MutableManagedObject<PlainObject>) {
        self.removeObject(value.instance)
    }

    public mutating func add(_ value: ManagedObject<PlainObject>) {
        self.addObject(value.instance)
    }

    public mutating func add(_ value: MutableManagedObject<PlainObject>) {
        self.addObject(value.instance)
    }

    public mutating func add(_ value: PlainObject) {
        self.addObject(value.encodeAttributes(to: self.newObject()))
    }
}
