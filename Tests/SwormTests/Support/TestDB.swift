import CoreData
import Foundation
import Sworm
import SwormTools
import XCTest

enum TestDB {
    static let info = SQLiteStoreDescription(
        name: "DataModel",
        url: NSPersistentContainer.defaultDirectoryURL(),
        modelName: "DataModel",
        modelVersions: ["DataModel"]
    )

    static func withTemporaryContainer(_ action: (PersistentContainer) throws -> Void) {
        do {
            try TestTool.withTemporary(store: self.info) { testStore in
                let container = try NSPersistentContainer(store: testStore, bundle: .module)
                try container.loadPersistentStore()
                try action(.init(container))
                try container.removePersistentStores()
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
