import CoreData

public struct SQLiteStoreDescription {
    public struct ModelVersion: ExpressibleByStringLiteral {
        public let name: String
        public let mappingModelName: String?

        public init(
            name: String,
            mappingModelName: String?
        ) {
            self.name = name
            self.mappingModelName = mappingModelName
        }

        public init(stringLiteral value: String) {
            self.name = value
            self.mappingModelName = nil
        }
    }

    public let name: String
    public let url: URL
    public let modelName: String
    public let modelVersions: [ModelVersion]

    public init(
        name: String,
        url: URL,
        modelName: String,
        modelVersions: [ModelVersion]
    ) {
        assert(!modelVersions.isEmpty)

        self.name = name
        self.url = url
        self.modelName = modelName
        self.modelVersions = modelVersions
    }

    public func with(maxVersion: Int) -> SQLiteStoreDescription {
        .init(
            name: self.name,
            url: self.url,
            modelName: self.modelName,
            modelVersions: Array(self.modelVersions[0 ... maxVersion])
        )
    }
}
