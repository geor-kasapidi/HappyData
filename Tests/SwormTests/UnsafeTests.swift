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

            try db.readWrite(action: { _, writer in
                try writer.insert(book)
            })

            let managedObject = try db.readOnly(action: { reader in
                try reader.fetch(Book.all) {
                    $0 // do not use managed object wrapper outside read/write closure
                }
            }).first

            _ = try? managedObject?.decode() // bad access here
        }
    }

    func _testBadAccess2() {
        TestDB.withTemporaryContainer { db in
            try db.readWrite(action: { _, writer in
                try writer.insert(Author.self) {
                    $0.encode(Author(id: .init()))
                    $0[\.books].add(.init())
                }
            })

            let managedObjects = try db.readOnly(action: { reader in
                try reader.fetchOne(Author.all) {
                    $0[\.books]
                }
            })!

            managedObjects.forEach {
                print($0)
            }
        }
    }

    func _testBadAccess3() {
        TestDB.withTemporaryContainer { db in
            var managedObjects: MutableManagedObjectSet<Book>!

            try db.readWrite(action: { _, writer in
                try writer.insert(Author.self) {
                    $0.encode(Author(id: .init()))
                    $0[\.books].add(.init())
                    managedObjects = $0[\.books]
                }
            })

            managedObjects.forEach {
                print($0)
            }
        }
    }
}
