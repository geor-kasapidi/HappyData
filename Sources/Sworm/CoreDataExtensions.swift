import CoreData

public extension Bundle {
    func managedObjectModel(forVersion version: String, modelName: String) -> NSManagedObjectModel? {
        self.mom(version, modelName, true) ?? self.mom(version, modelName, false)
    }

    private func mom(_ v: String, _ d: String, _ o: Bool) -> NSManagedObjectModel? {
        self.url(forResource: v, withExtension: o ? "omo" : "mom", subdirectory: "\(d).momd").flatMap {
            NSManagedObjectModel(contentsOf: $0)
        }
    }
}

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
    func save<T>(_ action: @escaping () throws -> T) throws -> T {
        try self.execute {
            let result = try action()
            if self.hasChanges {
                try self.save()
            }
            return result
        }
    }

    func execute<T>(_ action: @escaping () throws -> T) throws -> T {
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
            throw DBError.actionWasNotPerformed
        }
    }
}

public extension NSPersistentContainer {
    convenience init(store: SQLiteStoreDescription, bundle: Bundle) throws {
        guard let version = store.modelVersions.last else {
            throw DBError.noCompatibleModelVersionFound
        }

        guard let model = bundle.managedObjectModel(forVersion: version, modelName: store.modelName) else {
            throw DBError.badModelVersion(version)
        }

        self.init(name: store.name, managedObjectModel: model)

        self.persistentStoreDescriptions = [.init(store: store)]
    }

    func loadPersistentStore() throws {
        assert(self.persistentStoreDescriptions.count == 1)

        var loadError: Swift.Error?
        self.loadPersistentStores { _, error in
            loadError = error
        }
        try loadError.flatMap { throw $0 }
    }

    func removePersistentStores() throws {
        try self.persistentStoreCoordinator.removePersistentStores()
    }
}

public extension NSPersistentStoreDescription {
    convenience init(store: SQLiteStoreDescription) {
        self.init(url: store.url)

        self.type = NSSQLiteStoreType
        self.shouldAddStoreAsynchronously = false
        self.shouldInferMappingModelAutomatically = false
        self.shouldMigrateStoreAutomatically = false
    }
}

// MARK: - Internal

extension NSPersistentStoreCoordinator {
    func removePersistentStores() throws {
        try self.persistentStores.forEach {
            try self.remove($0)
        }
    }

    /// https://developer.apple.com/library/archive/qa/qa1809/_index.html
    /// https://sqlite.org/wal.html
    func checkpointWAL(at url: URL) throws {
        try self.remove(try self.addPersistentStore(
            ofType: NSSQLiteStoreType,
            configurationName: nil,
            at: url,
            options: [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
        ))
    }

    func replaceSQLiteStore(
        at destinationURL: URL,
        with sourceURL: URL
    ) throws {
        try self.replacePersistentStore(
            at: destinationURL,
            destinationOptions: nil,
            withPersistentStoreFrom: sourceURL,
            sourceOptions: nil,
            ofType: NSSQLiteStoreType
        )
    }

    func destroySQLiteStore(at url: URL) throws {
        try self.destroyPersistentStore(
            at: url,
            ofType: NSSQLiteStoreType,
            options: nil
        )
    }
}
