import CoreData.NSPersistentContainer
import Foundation.NSURL

public enum StoreError: Swift.Error {
    case badVersion(String)
    case noCompatibleVersionFound
    case badMappingModel(String)
}

public struct StoreInfo {
    public init(name: String, url: URL, modelName: String, modelVersions: [String], mappingModels: [String?]) {
        assert(!(modelVersions.count - mappingModels.count > 1))

        self.name = name
        self.url = url
        self.modelName = modelName
        self.modelVersions = modelVersions
        self.mappingModels = mappingModels
    }

    public let name: String
    public let url: URL
    public let modelName: String
    public let modelVersions: [String]
    public let mappingModels: [String?]

    public func with(maxVersion: Int) -> StoreInfo {
        .init(
            name: self.name,
            url: self.url,
            modelName: self.modelName,
            modelVersions: Array(self.modelVersions[0 ... maxVersion]),
            mappingModels: self.mappingModels
        )
    }
}

public extension NSPersistentContainer {
    convenience init(store: StoreInfo, bundle: Bundle) throws {
        guard let version = store.modelVersions.last else {
            throw StoreError.noCompatibleVersionFound
        }

        guard let model = bundle.managedObjectModel(forVersion: version, modelName: store.modelName) else {
            throw StoreError.badVersion(version)
        }

        self.init(name: store.name, managedObjectModel: model)

        self.persistentStoreDescriptions = [.init(store: store)]
    }
}

public extension NSPersistentStoreDescription {
    convenience init(store: StoreInfo) {
        self.init(url: store.url)

        self.type = NSSQLiteStoreType
        self.shouldAddStoreAsynchronously = false
        self.shouldInferMappingModelAutomatically = false
        self.shouldMigrateStoreAutomatically = false
    }
}
