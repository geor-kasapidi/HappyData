import CoreData
import Foundation
import Sworm
import SwormTools
import XCTest

enum TestDB {
    static func inMemoryContainer(
        store: SQLiteStoreDescription,
        action: (PersistentContainer) throws -> Void
    ) {
        do {
            let inMemoryStore = store.with(url: .devNull)
            let container = try NSPersistentContainer(store: inMemoryStore, bundle: .module)
            try container.loadPersistentStore()
            try action(.init(managedObjectContext: container.newBackgroundContext))
            try container.removePersistentStores()
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
