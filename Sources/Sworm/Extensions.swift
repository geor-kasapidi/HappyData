import CoreData

public extension NSManagedObject {
    subscript(primitiveValue key: String) -> Any? {
        get {
            self.willAccessValue(forKey: key)
            defer { self.didAccessValue(forKey: key) }
            return self.primitiveValue(forKey: key)
        }
        set {
            self.willChangeValue(forKey: key)
            self.setPrimitiveValue(newValue, forKey: key)
            self.didChangeValue(forKey: key)
        }
    }

    subscript(mutableSet key: String) -> NSMutableSet {
        self.mutableSetValue(forKey: key)
    }

    subscript(mutableOrderedSet key: String) -> NSMutableOrderedSet {
        self.mutableOrderedSetValue(forKey: key)
    }
}

public extension NSManagedObject {
    func new(relation name: String) -> NSManagedObject {
        .init(
            entity: self
                .entity
                .relationshipsByName[name].unsafelyUnwrapped
                .destinationEntity.unsafelyUnwrapped,
            insertInto: self.managedObjectContext.unsafelyUnwrapped
        )
    }
}

public extension NSManagedObjectContext {
    func new(entity name: String) -> NSManagedObject {
        .init(
            entity: self
                .persistentStoreCoordinator.unsafelyUnwrapped
                .managedObjectModel
                .entitiesByName[name].unsafelyUnwrapped,
            insertInto: self
        )
    }
}

public extension NSManagedObjectContext {
    func save<T>(cleanUpAfterExecution: Bool, _ action: @escaping () throws -> T) throws -> T {
        try self.execute(cleanUpAfterExecution: cleanUpAfterExecution) {
            let result = try action()
            if self.hasChanges {
                try self.save()
            }
            return result
        }
    }

    func execute<T>(cleanUpAfterExecution: Bool, _ action: @escaping () throws -> T) throws -> T {
        var result: Result<T, Error>?

        self.performAndWait {
            result = Result(catching: {
                try autoreleasepool {
                    try action()
                }
            })

            if cleanUpAfterExecution {
                self.reset()
            }
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

public extension NSPersistentContainer {
    func suitableContextForCurrentThread() -> NSManagedObjectContext {
        Thread.isMainThread ? self.viewContext : self.newBackgroundContext()
    }
}
