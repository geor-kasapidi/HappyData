import CoreData.NSPersistentContainer

public enum TestTool {
    public enum MigrationTestError: Swift.Error {
        case invalidStepCount(Int?, expected: Int?, store: StoreInfo)
    }

    public typealias TestAction = (NSPersistentContainer) -> Void

    public static func testMigrationStepByStep(store: StoreInfo, bundle: Bundle, actions: [Int: TestAction]) throws {
        try self.withTemporary(store: store) { testStore in
            try store.modelVersions.indices.forEach { index in
                try self.performTestAction(store: testStore.with(maxVersion: index), bundle: bundle, expectedStepCount: index > 0 ? 1 : nil) { persistentContainer in
                    actions[index]?(persistentContainer)
                }
            }
        }
    }

    public static func testMigration(store: StoreInfo, bundle: Bundle, preAction: TestAction?, postAction: TestAction?) throws {
        try self.withTemporary(store: store) { testStore in
            try self.performTestAction(store: testStore.with(maxVersion: 0), bundle: bundle, expectedStepCount: nil) { persistentContainer in
                preAction?(persistentContainer)
            }

            try self.performTestAction(store: testStore, bundle: bundle, expectedStepCount: testStore.modelVersions.count - 1) { persistentContainer in
                postAction?(persistentContainer)
            }
        }
    }

    public static func withTemporary(store: StoreInfo, action: (StoreInfo) throws -> Void) throws {
        let tmp = UUID().uuidString
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(tmp, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        let url = dir.appendingPathComponent("db", isDirectory: false).appendingPathExtension("sqlite")
        let testStore = StoreInfo(
            name: tmp,
            url: url,
            modelName: store.modelName,
            modelVersions: store.modelVersions,
            mappingModels: store.mappingModels
        )
        try action(testStore)
        try FileManager.default.removeItem(at: dir)
    }

    private static func performTestAction(
        store: StoreInfo,
        bundle: Bundle,
        expectedStepCount: Int?,
        testAction: (NSPersistentContainer) -> Void
    ) throws {
        try autoreleasepool {
            let persistentContainer = try NSPersistentContainer(store: store, bundle: bundle)
            let migration = try SQLiteProgressiveMigration(store: store, bundle: bundle)
            if expectedStepCount != migration?.stepCount {
                throw MigrationTestError.invalidStepCount(migration?.stepCount, expected: expectedStepCount, store: store)
            }
            try migration?.performMigration(progress: nil)
            try persistentContainer.loadPersistentStore()
            testAction(persistentContainer)
            try persistentContainer.removePersistentStores()
        }
    }
}