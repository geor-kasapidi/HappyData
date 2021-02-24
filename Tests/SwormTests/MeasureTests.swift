import Foundation
import Sworm
import XCTest

@available(OSX 10.15, *)
final class MeasureTests: XCTestCase {
    func testMeasureInsertEntitiesNoRelations() {
        TestDB.withTemporaryContainer { db in
            self.measure {
                let book = Book(
                    id: .init(),
                    name: "my book",
                    date: Date()
                )

                do {
                    try db.perform(action: { context in
                        (0 ..< 10000).forEach { _ in
                            context.insert(book)
                        }
                    })
                } catch {}
            }
        }
    }

    func testMeasureInsertEntitiesWithToOneRelations() {
        TestDB.withTemporaryContainer { db in
            let book = Book(
                id: .init(),
                name: "my book",
                date: Date()
            )

            let cover = BookCover(
                id: .init(),
                imageData: .init(repeating: 0, count: 10)
            )

            self.measure {
                do {
                    try db.perform(action: { context in
                        (0 ..< 10000).forEach { _ in
                            let bookObject = context.insert(book)
                            bookObject.bookCover = context.insert(cover)
                        }
                    })
                } catch {}
            }
        }
    }

    func testMeasureInsertEntitiesWithToManyRelations() {
        self.measure {
            TestDB.withTemporaryContainer { db in
                let count = 1000

                do {
                    try db.perform(action: { context in
                        let authorObject = context.insert(Author(id: .init(), name: "xxx"))

                        let books = authorObject.books

                        (0 ..< count).forEach { _ in
                            books.add(context.insert(.init(id: .init(), name: "yyy", date: .init())))
                        }
                    })

                    try db.perform(action: { context in
                        try context.fetch(Author.all).forEach { mo in
                            mo.books.prefix(count / 2).forEach {
                                mo.books.remove($0)
                            }
                        }
                    })

                    let x = try db.perform(action: { context in
                        try context.fetch(Author.all).map({
                            try $0.books.map {
                                try $0.decode()
                            }
                        })
                    })
                    XCTAssert(x[0].count == count / 2)
                } catch {
                    XCTFail(error.localizedDescription)
                }
            }
        }
    }
}
