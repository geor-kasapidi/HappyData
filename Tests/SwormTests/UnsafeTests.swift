import Foundation
import Sworm
import XCTest

@available(OSX 10.15, *)
// Remove low dash to test
final class UnsafeTests: XCTestCase {
    func _testBadAccess1() {
        TestDB.withTemporaryContainer { db in
            let book = Book(
                id: .init(),
                name: "my book",
                date: Date()
            )

            try db.perform(action: { context in
                context.insert(book)
            })

            let managedObject = try db.perform(action: { context in
                try context.fetchOne(Book.all)
            })

            _ = try? managedObject?.decode() // bad access here
        }
    }

    func _testBadAccess2() {
        TestDB.withTemporaryContainer { db in
            try db.perform(action: { context in
                context
                    .insert(Author(id: .init()))
                    .books
                    .add(context.insert(Book()))
            })

            let managedObjects = try db.perform(action: { context in
                try context.fetchOne(Author.all)?.books
            })!

            managedObjects.forEach {
                print($0)
            }
        }
    }

    func _testBadAccess3() {
        TestDB.withTemporaryContainer { db in
            var managedObjects: ManagedObjectSet<Book>!

            try db.perform(action: { context in
                let authorObject = context.insert(Author(id: .init()))

                authorObject.books.add(context.insert(Book()))

                managedObjects = authorObject.books
            })

            managedObjects.forEach {
                print($0)
            }
        }
    }
}
