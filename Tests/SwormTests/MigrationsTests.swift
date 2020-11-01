import CoreData
import Foundation
import Sworm
import XCTest

@available(OSX 10.15, *)
final class MigrationsTests: XCTestCase {
    private func performPersistenceAction(
        model: NSManagedObjectModel,
        modelName: String,
        storeName: String,
        modelVersions: [String],
        mappingModels: [String?],
        migration: (SQLiteProgressiveMigration?) -> Void,
        action: (PersistentContainer) -> Void
    ) throws {
        try autoreleasepool {
            let container = NSPersistentContainer(
                name: storeName,
                managedObjectModel: model
            )
            let storeURL = try container.prepareForManualSQLiteMigration()
            do {
                let m = try SQLiteProgressiveMigration(
                    originalStoreURL: storeURL,
                    bundle: .module,
                    modelName: modelName,
                    modelVersions: modelVersions,
                    mappingModels: mappingModels
                )
                migration(m)
                try m.flatMap {
                    try $0.performMigration(progress: nil)
                }
            }
            container.loadPersistentStores(completionHandler: { _, _ in })
            action(PersistentContainer(container))
            try container.persistentStoreCoordinator.persistentStores.forEach {
                try container.persistentStoreCoordinator.remove($0)
            }
        }
    }

    func testProgressiveMigrations() {
        let bundle = Bundle.module

        let modelName = "MigratableDataModel"
        let storeName = "MigratableStore"
        let modelVersions = ["V0", "V1", "V2", "V3"]
        let mappingModels: [String?] = ["V0V1", "V1V2", nil]

        let models = modelVersions.compactMap {
            bundle.managedObjectModel(
                forVersion: $0,
                modelName: modelName
            )
        }

        XCTAssert(models.count == 4)

        // all together

        do {
            NSPersistentContainer.dropFiles()

            try self.performPersistenceAction(
                model: models[0],
                modelName: modelName,
                storeName: storeName,
                modelVersions: [
                    modelVersions[0],
                ],
                mappingModels: mappingModels,
                migration: { migration in
                    XCTAssert(migration == nil)
                },
                action: { db in
                    do {
                        try db.readWrite { _, writer in
                            try writer.insert(MigratableModels.A(id: 1, name: "foo"))
                            try writer.insert(MigratableModels.A(id: 2, name: "bar"))
                        }
                    } catch {
                        XCTFail(error.localizedDescription)
                        return
                    }
                }
            )

            try self.performPersistenceAction(
                model: models[3],
                modelName: modelName,
                storeName: storeName,
                modelVersions: [
                    modelVersions[0],
                    modelVersions[1],
                    modelVersions[2],
                    modelVersions[3],
                ],
                mappingModels: mappingModels,
                migration: { migration in
                    XCTAssert(migration?.stepCount == 3)
                },
                action: { db in
                    do {
                        let bs = try db.readOnly { reader in
                            try reader.fetch(MigratableModels.B.all).sorted()
                        }

                        XCTAssert(bs.count == 2)
                        XCTAssert(bs[0] == .init(identifier: 10, text: "foo"))
                        XCTAssert(bs[1] == .init(identifier: 20, text: "bar"))
                    } catch {
                        XCTFail(error.localizedDescription)
                        return
                    }

                    do {
                        try db.readWrite { _, writer in
                            try writer.insert(MigratableModels.C(foo: "foo"))
                            try writer.insert(MigratableModels.C(foo: "bar"))
                        }
                    } catch {
                        XCTFail(error.localizedDescription)
                        return
                    }

                    do {
                        let cs = try db.readOnly { reader in
                            try reader.fetch(MigratableModels.C.all).sorted()
                        }

                        XCTAssert(cs.count == 2)
                        XCTAssert(cs[0] == .init(foo: "bar"))
                        XCTAssert(cs[1] == .init(foo: "foo"))
                    } catch {
                        XCTFail(error.localizedDescription)
                        return
                    }
                }
            )
        } catch {
            XCTFail(error.localizedDescription)
        }

        // step by step

        do {
            NSPersistentContainer.dropFiles()

            try self.performPersistenceAction(
                model: models[0],
                modelName: modelName,
                storeName: storeName,
                modelVersions: [
                    modelVersions[0],
                ],
                mappingModels: mappingModels,
                migration: { migration in
                    XCTAssert(migration == nil)
                },
                action: { db in
                    do {
                        try db.readWrite { _, writer in
                            try writer.insert(MigratableModels.A(id: 1, name: "foo"))
                            try writer.insert(MigratableModels.A(id: 2, name: "bar"))
                        }
                    } catch {
                        XCTFail(error.localizedDescription)
                        return
                    }
                }
            )

            try self.performPersistenceAction(
                model: models[1],
                modelName: modelName,
                storeName: storeName,
                modelVersions: [
                    modelVersions[0],
                    modelVersions[1],
                ],
                mappingModels: mappingModels,
                migration: { migration in
                    XCTAssert(migration?.stepCount == 1)
                },
                action: { db in
                    do {
                        let bs = try db.readOnly { reader in
                            try reader.fetch(MigratableModels.B.all).sorted()
                        }

                        XCTAssert(bs.count == 2)
                        XCTAssert(bs[0] == .init(identifier: 1, text: "foo"))
                        XCTAssert(bs[1] == .init(identifier: 2, text: "bar"))
                    } catch {
                        XCTFail(error.localizedDescription)
                        return
                    }
                }
            )

            try self.performPersistenceAction(
                model: models[2],
                modelName: modelName,
                storeName: storeName,
                modelVersions: [
                    modelVersions[0],
                    modelVersions[1],
                    modelVersions[2],
                ],
                mappingModels: mappingModels,
                migration: { migration in
                    XCTAssert(migration?.stepCount == 1)
                },
                action: { db in
                    do {
                        let bs = try db.readOnly { reader in
                            try reader.fetch(MigratableModels.B.all).sorted()
                        }

                        XCTAssert(bs.count == 2)
                        XCTAssert(bs[0] == .init(identifier: 10, text: "foo"))
                        XCTAssert(bs[1] == .init(identifier: 20, text: "bar"))
                    } catch {
                        XCTFail(error.localizedDescription)
                        return
                    }
                }
            )

            try self.performPersistenceAction(
                model: models[3],
                modelName: modelName,
                storeName: storeName,
                modelVersions: [
                    modelVersions[0],
                    modelVersions[1],
                    modelVersions[2],
                    modelVersions[3],
                ],
                mappingModels: mappingModels,
                migration: { migration in
                    XCTAssert(migration?.stepCount == 1)
                },
                action: { db in
                    do {
                        try db.readWrite { _, writer in
                            try writer.insert(MigratableModels.C(foo: "foo"))
                            try writer.insert(MigratableModels.C(foo: "bar"))
                        }
                    } catch {
                        XCTFail(error.localizedDescription)
                        return
                    }

                    do {
                        let cs = try db.readOnly { reader in
                            try reader.fetch(MigratableModels.C.all).sorted()
                        }

                        XCTAssert(cs.count == 2)
                        XCTAssert(cs[0] == .init(foo: "bar"))
                        XCTAssert(cs[1] == .init(foo: "foo"))
                    } catch {
                        XCTFail(error.localizedDescription)
                        return
                    }
                }
            )
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
