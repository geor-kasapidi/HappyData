import CoreData
import Foundation
import Sworm
import SwormTools
import XCTest

@available(OSX 10.15, *)
final class CRUDTests: XCTestCase {
    func testIsNotReady() {
        struct NotReadyError: Swift.Error {}

        do {
            try TestTool.withTemporary(store: TestDB.info) { _ in
                let pc = PersistentContainer(
                    managedObjectContext: {
                        throw NotReadyError()
                    },
                    logError: { error in
                        XCTAssert(error is NotReadyError)
                    }
                )
                do {
                    try pc.perform { context in
                        context.insert(Book(
                            id: .init(),
                            name: "A",
                            date: Date()
                        ))
                    }
                } catch {
                    XCTAssert(error is NotReadyError)
                }
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testSingleEntityNoRelationsReadWrite() {
        TestDB.withTemporaryContainer { db in
            let book1 = Book(
                id: .init(),
                name: "A",
                date: Date()
            )

            let book2 = Book(
                id: .init(),
                name: "B",
                date: Date()
            )

            // INSERT
            do {
                try db.perform(action: { context in
                    context.insert(book1)
                })
            }
            // FETCH
            do {
                let books = try db.perform(action: { context in
                    try context.fetch(Book.all).map({ try $0.decode() })
                })

                XCTAssert(books.count == 1)
                XCTAssert(books[0] == book1)
            }
            // UPDATE
            do {
                try db.perform(action: { context in
                    try context.fetch(Book.all).forEach {
                        $0.encode(book2)
                    }
                })
            }
            // FETCH
            do {
                let books = try db.perform(action: { context in
                    try context.fetch(Book.all).map({ try $0.decode() })
                })

                XCTAssert(books.count == 1)
                XCTAssert(books[0] == book2)
            }
            // DELETE
            do {
                try db.perform(action: { context in
                    try context.delete(Book.all)
                })
            }
            // COUNT
            do {
                let booksCount = try db.perform(action: { context in
                    try context.count(of: Book.all)
                })

                XCTAssert(booksCount == 0)
            }
        }
    }

    func testSingleEntityWithRelationsReadWrite() {
        TestDB.withTemporaryContainer { db in
            let book1 = Book(
                id: .init(),
                name: "A",
                date: Date()
            )

            let book2 = Book(
                id: .init(),
                name: "B",
                date: Date()
            )

            let cover = BookCover(
                id: .init(),
                imageData: .init(repeating: 0, count: 10)
            )

            let foo = Foo(id: 11)

            // INSERT
            do {
                try db.perform(action: { context in
                    let bookObject = context.insert(book1)
                    bookObject.bookCover = context.insert(cover)
                    bookObject.bookCover?.foo = context.insert(foo)
                })
            }
            // FETCH
            do {
                let booksWithCoversWithFoos = try db.perform(action: { context in
                    try context.fetch(Book.all).map {
                        (
                            try $0.decode(),
                            try $0.bookCover?.decode(),
                            try $0.bookCover?.foo?.decode()
                        )
                    }
                })

                XCTAssert(booksWithCoversWithFoos.count == 1)
                XCTAssert(booksWithCoversWithFoos[0].0 == book1)
                XCTAssert(booksWithCoversWithFoos[0].1 == cover)
                XCTAssert(booksWithCoversWithFoos[0].2 == foo)
            }
            // UPDATE
            do {
                try db.perform(action: { context in
                    try context.fetch(Book.all).forEach {
                        $0.bookCover?.book?.encode(book2)
                        $0.bookCover?.foo = nil
                    }
                })
            }
            // FETCH
            do {
                let booksWithCoversWithFoos = try db.perform(action: { context in
                    try context.fetch(Book.all).map {
                        (
                            try $0.decode(),
                            try $0.bookCover?.decode(),
                            try $0.bookCover?.foo?.decode()
                        )
                    }
                })

                XCTAssert(booksWithCoversWithFoos.count == 1)
                XCTAssert(booksWithCoversWithFoos[0].0 == book2)
                XCTAssert(booksWithCoversWithFoos[0].1 == cover)
                XCTAssert(booksWithCoversWithFoos[0].2 == nil)
            }
        }
    }

    func testNotUniqueInsertFail() {
        TestDB.withTemporaryContainer { db in
            let book = Book(
                id: .init(),
                name: "A",
                date: Date()
            )

            var hasError: Bool = false

            do {
                // INSERT (success)
                do {
                    try db.perform(action: { context in
                        context.insert(book)
                    })
                }
                // INSERT (fail)
                do {
                    try db.perform(action: { context in
                        context.insert(book)
                    })
                } catch {
                    hasError = true
                }
            }

            XCTAssert(hasError)
        }
    }

    func testNotUniqueInsertFetch() {
        TestDB.withTemporaryContainer { db in
            let book = Book(
                id: .init(),
                name: "A",
                date: Date()
            )

            var hasError: Bool = false

            // INSERT
            do {
                try db.perform(action: { context in
                    for _ in 1 ... 10 {
                        context.insert(book)
                    }
                })
            } catch {
                hasError = true
            }

            XCTAssert(hasError)

            // FETCH
            let books = try db.perform(action: { context in
                try context.fetch(Book.all)
            })

            XCTAssert(books.isEmpty)
        }
    }

    func testRequestSortLimit() {
        TestDB.withTemporaryContainer { db in
            // INSERT
            try db.perform(action: { context in
                for i in (1 ... 10).reversed() {
                    context.insert(
                        Book(
                            id: .init(),
                            name: "\(i)",
                            date: i % 2 == 0 ? Date.distantPast : Date.distantFuture
                        )
                    )
                }
            })

            // FETCH
            let bookNames = try db.perform(action: { context in
                try context.fetch(
                    Book
                        .all
                        .sort(\.date)
                        .sort(\.name)
                        .limit(8)
                        .offset(1),
                    \.name
                )
            })

            XCTAssert(bookNames == ["2", "4", "6", "8", "1", "3", "5", "7"])
        }
    }

    func testRequestPredicate() {
        TestDB.withTemporaryContainer { db in
            // INSERT
            try db.perform(action: { context in
                for i in (1 ... 10).reversed() {
                    context.insert(
                        Book(
                            id: i % 2 == 0 ? .init() : nil,
                            name: "\(i)",
                            date: i % 2 == 0 ? Date.distantPast : Date.distantFuture
                        )
                    )
                }
            })

            // FETCH
            let bookWithoutIDs = try db.perform(action: { context in
                try context.fetch(
                    Book
                        .all
                        .where(\Book.id == nil)
                        .sort(\.name),
                    \.name
                )
            })

            XCTAssert(bookWithoutIDs == ["1", "3", "5", "7", "9"])

            let bookWithIDs = try db.perform(action: { context in
                try context.fetch(
                    Book
                        .all
                        .where(\Book.id != nil)
                        .sort(\.name),
                    \.name
                )
            })

            XCTAssert(bookWithIDs == ["10", "2", "4", "6", "8"])

            let bookWithFutureDates = try db.perform(action: { context in
                try context.fetch(
                    Book
                        .all
                        .where(\Book.date > Date())
                        .sort(\.name),
                    \.name
                )
            })

            XCTAssert(bookWithFutureDates == ["1", "3", "5", "7", "9"])

            let bookWithFutureDatesAndExcludedIDs = try db.perform(action: { context in
                try context.fetch(
                    Book
                        .all
                        .where(\Book.date > Date() && !(\Book.name === ["3", "5"]))
                        .sort(\.name),
                    \.name
                )
            })

            XCTAssert(bookWithFutureDatesAndExcludedIDs == ["1", "7", "9"])
        }
    }

    func testToManyRelations() {
        TestDB.withTemporaryContainer { db in
            let authorID = UUID()

            do {
                try db.perform { context in
                    let authorObject = context.insert(Author(
                        id: authorID,
                        name: "pushkin"
                    ))

                    ["1", "2", "3"].forEach {
                        authorObject.books.add(context.insert(Book(name: $0)))
                    }
                }
            }

            do {
                let bookNames = try db.perform { context in
                    try context.fetchOne(Author.all).map {
                        try $0.books
                            .map { try $0.decode(\.name) }
                            .sorted()
                    }
                }

                XCTAssert(bookNames == ["1", "2", "3"])
            }

            do {
                try db.perform { context in
                    try context.fetch(Author.all).forEach { mo in
                        try mo.books
                            .filter {
                                try $0.decode(\.name) == "2"
                            }
                            .forEach {
                                mo.books.remove($0)
                                context.delete($0)
                            }
                    }
                }
            }

            do {
                let bookNames = try db.perform { context in
                    try context.fetchOne(Author.all).map {
                        try $0.books
                            .map { try $0.decode(\.name) }
                            .sorted()
                    }
                }

                XCTAssert(bookNames == ["1", "3"])

                let allBookNames = try db.perform { context in
                    try context.fetch(Book.all, \.name).sorted()
                }

                XCTAssert(allBookNames == ["1", "3"])
            }
        }
    }

    func testOrderedRelations() {
        TestDB.withTemporaryContainer { db in
            let authorID = UUID()

            do {
                try db.perform { context in
                    let authorObject = context.insert(Author(
                        id: authorID,
                        name: "pushkin"
                    ))

                    (2 ... 4)
                        .reversed()
                        .map({ Book(name: String($0)) })
                        .forEach {
                            authorObject.orderedBooks.add(context.insert($0))
                        }
                }
            }

            do {
                let bookNames = try db.perform { context in
                    try context.fetchOne(Author.all).map {
                        try $0.orderedBooks
                            .map { try $0.decode(\.name) }
                    }
                }

                XCTAssert(bookNames == ["4", "3", "2"])
            }

            let coverID = UUID()

            do {
                try db.perform { context in
                    try context.fetch(Author.all).forEach { mo in
                        for x in mo.orderedBooks {
                            x.bookCover = context.insert(.init(
                                id: coverID,
                                imageData: .init(repeating: 0, count: 10)
                            ))
                        }

                        try mo.orderedBooks
                            .filter {
                                try $0.decode(\.name) == "3"
                            }
                            .forEach {
                                mo.orderedBooks.remove($0)
                                context.delete($0)
                            }
                    }
                }
            }

            do {
                let books = try db.perform { context in
                    try context.fetchOne(Author.all).map {
                        try $0.orderedBooks.map {
                            (
                                try $0.decode(),
                                try ($0.bookCover?.decode(\.id))
                            )
                        }
                    }
                }

                XCTAssert(books?.map(\.0.name) == ["4", "2"])
                XCTAssert(books?.map(\.1) == [coverID, coverID])

                let allBookNames = try db.perform { context in
                    try context.fetch(Book.all, \.name).sorted()
                }

                XCTAssert(allBookNames == ["2", "4"])
            }
        }
    }
}
