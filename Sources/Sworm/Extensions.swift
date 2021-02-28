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
    func perform<T>(cleanUpAfterExecution: Bool, _ action: @escaping () throws -> T) throws -> T {
        var result: Result<T, Error>?

        self.performAndWait {
            result = Result(catching: {
                let value = try action()
                if self.hasChanges {
                    try self.save()
                }
                return value
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
