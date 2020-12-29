import CoreData

public struct SQLiteStoreDescription {
    public let name: String
    public let url: URL
    public let modelName: String
    public let modelVersions: [String]
    public let mappingModels: [String?]

    public init(
        name: String,
        url: URL,
        modelName: String,
        modelVersions: [String],
        mappingModels: [String?]
    ) {
        assert(!modelVersions.isEmpty && mappingModels.count >= (modelVersions.count - 1))

        self.name = name
        self.url = url
        self.modelName = modelName
        self.modelVersions = modelVersions
        self.mappingModels = mappingModels
    }

    public func with(maxVersion: Int) -> SQLiteStoreDescription {
        .init(
            name: self.name,
            url: self.url,
            modelName: self.modelName,
            modelVersions: Array(self.modelVersions[0 ... maxVersion]),
            mappingModels: self.mappingModels
        )
    }
}
