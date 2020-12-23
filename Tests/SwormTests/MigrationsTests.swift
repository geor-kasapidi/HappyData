import CoreData
import Foundation
import Sworm
import XCTest

@available(OSX 10.15, *)
final class MigrationsTests: XCTestCase {
    func testProgressiveMigrations() {
        let bundle = Bundle.module

        let storeInfo = SQLiteStoreDescription(
            name: "MigratableStore",
            url: NSPersistentContainer.defaultDirectoryURL(), // not important here
            modelName: "MigratableDataModel",
            modelVersions: ["V0", "V1", "V2", "V3"],
            mappingModels: ["V0V1", "V1V2", nil]
        )

        // all together

        do {
            try TestTool.testMigration(
                store: storeInfo,
                bundle: bundle,
                preAction: {
                    print("FIRST STEP")
                    let db = PersistentContainer($0)
                    do {
                        try db.readWrite { _, writer in
                            try writer.insert(MigratableModels.A(id: 1, name: "foo"))
                            try writer.insert(MigratableModels.A(id: 2, name: "bar"))
                        }
                    } catch {
                        XCTFail(error.localizedDescription)
                        return
                    }
                },
                postAction: {
                    print("LAST STEP")
                    let db = PersistentContainer($0)
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
            try TestTool.testMigrationStepByStep(
                store: storeInfo,
                bundle: bundle,
                actions: [
                    0: {
                        print("STEP 0")

                        let db = PersistentContainer($0)
                        do {
                            try db.readWrite { _, writer in
                                try writer.insert(MigratableModels.A(id: 1, name: "foo"))
                                try writer.insert(MigratableModels.A(id: 2, name: "bar"))
                            }
                        } catch {
                            XCTFail(error.localizedDescription)
                            return
                        }
                    },
                    1: {
                        print("STEP 1")

                        let db = PersistentContainer($0)
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
                    },
                    2: {
                        print("STEP 2")

                        let db = PersistentContainer($0)
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
                    },
                    3: {
                        print("STEP 3")

                        let db = PersistentContainer($0)
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
                    },
                ]
            )
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
