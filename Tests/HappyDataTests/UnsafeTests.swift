import Foundation
import XCTest
import HappyData

@available(OSX 10.15, *)
// Remove low dash to test
final class UnsafeTests: XCTestCase {
    func _testBadAccess1() {
        XCTAssertNoThrow(try TestDB.cleanUp())

        let book = Book(
            id: .init(),
            name: "my book",
            date: Date()
        )

        do {
            try TestDB.shared.readWrite(action: { _, writer in
                try writer.insert(book)
            })

            let managedObject = try TestDB.shared.readOnly(action: { reader in
                try reader.fetch(Book.all) {
                    $0 // do not use managed object wrapper outside read/write closure
                }
            }).first

            _ = try? managedObject?.decode() // bad access here
        } catch {
            XCTAssert(false, error.localizedDescription)
        }
    }

    func _testBadAccess2() {
        XCTAssertNoThrow(try TestDB.cleanUp())

        do {
            try TestDB.shared.readWrite(action: { _, writer in
                try writer.insert(Author.self) {
                    $0.encode(Author(id: .init()))
                    $0[\.books].add(.init())
                }
            })

            let managedObjects = try TestDB.shared.readOnly(action: { reader in
                try reader.fetchOne(Author.all) {
                    $0[\.books]
                }
            })!

            managedObjects.forEach {
                print($0)
            }
        } catch {
            XCTAssert(false, error.localizedDescription)
        }
    }

    func _testBadAccess3() {
        XCTAssertNoThrow(try TestDB.cleanUp())

        do {
            var managedObjects: MutableManagedObjectSet<Book>!

            try TestDB.shared.readWrite(action: { _, writer in
                try writer.insert(Author.self) {
                    $0.encode(Author(id: .init()))
                    $0[\.books].add(.init())
                    managedObjects = $0[\.books]
                }
            })

            managedObjects.forEach {
                print($0)
            }
        } catch {
            XCTAssert(false, error.localizedDescription)
        }
    }
}
