import CoreData
import Foundation
import Sworm

extension NSPersistentContainer {
    static func dropFiles() {
        try? FileManager.default.removeItem(at: self.defaultDirectoryURL())
    }
}

enum TestDB {
    static let shared = PersistentContainer(
        Self.makePersistentContainer(name: "DataModel")
    )

    @available(OSX 10.15, *)
    static func cleanUp() throws {
        try self.shared.readWrite { _, writer in
            try writer.batchDelete(Foo.all)
            try writer.batchDelete(BookCover.all)
            try writer.batchDelete(Book.all)
            try writer.batchDelete(Author.all)
        }
    }

    private static func makePersistentContainer<T: NSPersistentContainer>(name: String) -> T {
        T.dropFiles()

        Thread.sleep(forTimeInterval: 1)

        let instance = T(
            name: name,
            managedObjectModel: Bundle.module.managedObjectModel(forVersion: name, modelName: name).unsafelyUnwrapped
        )

        instance.loadPersistentStores { _, _ in }

        return instance
    }
}
