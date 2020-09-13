import Foundation
import CoreData

extension NSManagedObject {
    subscript(primitiveKey key: String) -> Any? {
        get {
            self.primitiveValue(forKey: key)
        }
        set {
            self.willChangeValue(forKey: key)
            self.setPrimitiveValue(newValue, forKey: key)
            self.didChangeValue(forKey: key)
        }
    }
}

extension NSManagedObject {
    func new(relation name: String) -> NSManagedObject {
        return .init(
            entity: self
                .entity
                .relationshipsByName[name].unsafelyUnwrapped
                .destinationEntity.unsafelyUnwrapped,
            insertInto: self.managedObjectContext.unsafelyUnwrapped
        )
    }
}

extension NSManagedObjectContext {
    func new(entity name: String) -> NSManagedObject {
        return .init(
            entity: self
                .persistentStoreCoordinator.unsafelyUnwrapped
                .managedObjectModel
                .entitiesByName[name].unsafelyUnwrapped,
            insertInto: self
        )
    }
}

extension NSManagedObjectContext {
    func save<T>(_ action: @escaping () throws -> T) throws -> T {
        return try self.execute {
            let result = try action()
            if self.hasChanges {
                try self.save()
            }
            return result
        }
    }

    func execute<T>(_ action: @escaping () throws -> T) throws -> T  {
        var result: Result<T, Error>?

        self.performAndWait {
            result = Result(catching: {
                try autoreleasepool {
                    try action()
                }
            })
            self.reset()
        }

        switch result {
        case let .success(value):
            return value
        case let .failure(error):
            throw error
        case .none:
            fatalError()
        }
    }
}
