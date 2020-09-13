import Foundation
import CoreData

public enum SQLiteMigrationError: Swift.Error {
    case badStore
    case badVersion(String)
    case noCompatibleVersionFound
    case badMappingModel(String)
}

public struct SQLiteProgressiveMigration {
    public typealias Progress = (Int, Int) -> Void

    struct Step {
        enum Source {
            case auto
            case bundle(Bundle, String)
        }

        let sourceModel: NSManagedObjectModel
        let destinationModel: NSManagedObjectModel
        let mappingModel: NSMappingModel

        init(
            sourceModel: NSManagedObjectModel,
            destinationModel: NSManagedObjectModel,
            source: Source
        ) throws {
            switch source {
            case .auto:
                self.mappingModel = try NSMappingModel.inferredMappingModel(
                    forSourceModel: sourceModel,
                    destinationModel: destinationModel
                )
            case let .bundle(bundle, name):
                guard let url = bundle.url(forResource: name, withExtension: "cdm"),
                      let mappingModel = NSMappingModel(contentsOf: url)
                else {
                    throw SQLiteMigrationError.badMappingModel(name)
                }
                self.mappingModel = mappingModel
            }
            self.sourceModel = sourceModel
            self.destinationModel = destinationModel
        }

        func migrate(from sourceURL: URL, to destinationURL: URL) throws {
            try NSMigrationManager(
                sourceModel: self.sourceModel,
                destinationModel: self.destinationModel
            ).migrateStore(
                from: sourceURL,
                sourceType: NSSQLiteStoreType,
                options: nil,
                with: self.mappingModel,
                toDestinationURL: destinationURL,
                destinationType: NSSQLiteStoreType,
                destinationOptions: nil
            )
        }
    }

    let originalStoreURL: URL
    let metadata: [String : Any]
    let currentModel: NSManagedObjectModel
    let bundle: Bundle
    let steps: [Step]

    public init?(
        originalStoreURL: URL,
        bundle: Bundle,
        modelName: String,
        modelVersions: [String],
        mappingModels: [String?]
    ) throws {
        guard let metadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(
            ofType: NSSQLiteStoreType,
            at: originalStoreURL,
            options: nil
        ) else {
            return nil
        }

        let models: [NSManagedObjectModel] = try modelVersions.map { version in
            if let model = bundle.managedObjectModel(forVersion: version, modelName: modelName) {
                return model
            }
            throw SQLiteMigrationError.badVersion(version)
        }

        guard let currentModelIndex = models.firstIndex(where: {
            $0.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        }) else {
            throw SQLiteMigrationError.noCompatibleVersionFound
        }

        let modelIndicesToMigrate = models.indices.dropFirst(currentModelIndex)

        let steps = try zip(modelIndicesToMigrate.dropLast(), modelIndicesToMigrate.dropFirst()).map {
            try Step(
                sourceModel: models[$0],
                destinationModel: models[$1],
                source: mappingModels[$0].flatMap({ .bundle(bundle, $0) }) ?? .auto
            )
        }

        guard !steps.isEmpty else {
            return nil
        }

        self.originalStoreURL = originalStoreURL
        self.metadata = metadata
        self.currentModel = models[currentModelIndex]
        self.bundle = bundle
        self.steps = steps
    }

    public var stepCount: Int {
        return self.steps.count
    }

    public func performMigration(progress: Progress?) throws {
        let storeCoordinator = NSPersistentStoreCoordinator(
            managedObjectModel: self.currentModel
        )

        try storeCoordinator.checkpointWAL(at: self.originalStoreURL)

        progress?(0, self.steps.count)

        var currentStoreURL = self.originalStoreURL

        for (index, step) in self.steps.enumerated() {
            let newStoreURL = URL(
                fileURLWithPath: NSTemporaryDirectory(),
                isDirectory: true
            ).appendingPathComponent(
                UUID().uuidString
            )

            try step.migrate(
                from: currentStoreURL,
                to: newStoreURL
            )

            if currentStoreURL != self.originalStoreURL {
                try storeCoordinator.destroySQLiteStore(at: currentStoreURL)
            }

            currentStoreURL = newStoreURL

            progress?(index + 1, self.steps.count)
        }

        try storeCoordinator.replaceSQLiteStore(
            at: self.originalStoreURL,
            with: currentStoreURL
        )

        if currentStoreURL != self.originalStoreURL {
            try storeCoordinator.destroySQLiteStore(at: currentStoreURL)
        }
    }
}

private extension NSPersistentStoreCoordinator {
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

extension Bundle {
    public func managedObjectModel(forVersion version: String, modelName: String) -> NSManagedObjectModel? {
        // momd directory contains omo/mom files
        let subdirectory = "\(modelName).momd"

        // optimized model file
        if let omoURL = self.url(
            forResource: version,
            withExtension: "omo",
            subdirectory: subdirectory
        ) {
            return NSManagedObjectModel(contentsOf: omoURL)
        }

        // standard model file
        if let momURL = self.url(
            forResource: version,
            withExtension: "mom",
            subdirectory: subdirectory
        ) {
            return NSManagedObjectModel(contentsOf: momURL)
        }

        return nil
    }
}

extension NSPersistentContainer {
    public func prepareForManualSQLiteMigration() throws -> URL {
        guard let storeDescription = self.persistentStoreDescriptions.first,
              storeDescription.type == NSSQLiteStoreType,
              let storeURL = storeDescription.url
        else {
            throw SQLiteMigrationError.badStore
        }

        storeDescription.shouldAddStoreAsynchronously = false
        storeDescription.shouldInferMappingModelAutomatically = false
        storeDescription.shouldMigrateStoreAutomatically = false

        return storeURL
    }
}
