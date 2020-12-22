import CoreData
import Foundation
import Sworm
import XCTest

@available(OSX 10.15, *)
final class CRUDTests: XCTestCase {
    func testIsNotReady() {
        do {
            try TestTool.withTemporary(store: TestDB.info) { testStore in
                let container = try NSPersistentContainer(store: testStore, bundle: .module)
                let pc = PersistentContainer(container, isReady: { false })
                do {
                    try pc.readWrite { _, writer in
                        try writer.insert(Book(
                            id: .init(),
                            name: "A",
                            date: Date()
                        ))
                    }
                } catch {
                    XCTAssert(error is ActionError)
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
                try db.readWrite(action: { _, writer in
                    try writer.insert(book1)
                })
            }
            // FETCH
            do {
                let books = try db.readOnly(action: { reader in
                    try reader.fetch(Book.all)
                })

                XCTAssert(books.count == 1)
                XCTAssert(books[0] == book1)
            }
            // UPDATE
            do {
                try db.readWrite(action: { _, writer in
                    try writer.update(Book.all) {
                        $0.encode(book2)
                    }
                })
            }
            // FETCH
            do {
                let books = try db.readOnly(action: { reader in
                    try reader.fetch(Book.all)
                })

                XCTAssert(books.count == 1)
                XCTAssert(books[0] == book2)
            }
            // DELETE
            do {
                try db.readWrite(action: { _, writer in
                    try writer.delete(Book.all)
                })
            }
            // COUNT
            do {
                let booksCount = try db.readOnly(action: { reader in
                    try reader.count(of: Book.all)
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
                try db.readWrite(action: { _, writer in
                    try writer.insert(Book.self) {
                        $0.encode(book1)
                        $0.set(\.bookCover, value: cover)
                        $0[\.bookCover]?.set(\.foo, value: foo)
                    }
                })
            }
            // FETCH
            do {
                let booksWithCoversWithFoos = try db.readOnly(action: { reader in
                    try reader.fetch(Book.all) {
                        (
                            try $0.decode(),
                            try $0[\.bookCover]?.decode(),
                            try $0[\.bookCover]?[\.foo]?.decode()
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
                try db.readWrite(action: { _, writer in
                    try writer.update(Book.all) {
                        $0[\.bookCover]?.set(\.book, value: book2)
                        $0[\.bookCover]?.set(\.foo, object: nil)
                    }
                })
            }
            // FETCH
            do {
                let booksWithCoversWithFoos = try db.readOnly(action: { reader in
                    try reader.fetch(Book.all) {
                        (
                            try $0.decode(),
                            try $0[\.bookCover]?.decode(),
                            try $0[\.bookCover]?[\.foo]?.decode()
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
                    try db.readWrite(action: { _, writer in
                        try writer.insert(book)
                    })
                }
                // INSERT (fail)
                do {
                    try db.readWrite(action: { _, writer in
                        try writer.insert(book)
                    })
                } catch {
                    hasError = true
                }
            }

            XCTAssert(hasError)
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
                    try db.readWrite(action: { _, writer in
                        for _ in 1 ... 10 {
                            try writer.insert(book)
                        }
                    })
                } catch {
                    hasError = true
                }

                XCTAssert(hasError)

                // FETCH
                let books = try db.readOnly(action: { reader in
                    try reader.fetch(Book.all)
                })

                XCTAssert(books.isEmpty)
            }
        }

        func testRequestSortLimit() {
            TestDB.withTemporaryContainer { db in
                // INSERT
                try db.readWrite(action: { _, writer in
                    for i in (1 ... 10).reversed() {
                        try writer.insert(
                            Book(
                                id: .init(),
                                name: "\(i)",
                                date: i % 2 == 0 ? Date.distantPast : Date.distantFuture
                            )
                        )
                    }
                })

                // FETCH
                let bookNames = try db.readOnly(action: { reader in
                    try reader.fetch(
                        Book
                            .all
                            .sort(asc: \.date)
                            .sort(asc: \.name)
                            .limit(8)
                            .offset(1),
                        attribute: \.name
                    )
                })

                XCTAssert(bookNames == ["2", "4", "6", "8", "1", "3", "5", "7"])
            }
        }

        func testRequestPredicate() {
            TestDB.withTemporaryContainer { db in
                // INSERT
                try db.readWrite(action: { _, writer in
                    for i in (1 ... 10).reversed() {
                        try writer.insert(
                            Book(
                                id: i % 2 == 0 ? .init() : nil,
                                name: "\(i)",
                                date: i % 2 == 0 ? Date.distantPast : Date.distantFuture
                            )
                        )
                    }
                })

                // FETCH
                let bookWithoutIDs = try db.readOnly(action: { reader in
                    try reader.fetch(
                        Book
                            .all
                            .where(\Book.id == nil)
                            .sort(asc: \.name),
                        attribute: \.name
                    )
                })

                XCTAssert(bookWithoutIDs == ["1", "3", "5", "7", "9"])

                let bookWithIDs = try db.readOnly(action: { reader in
                    try reader.fetch(
                        Book
                            .all
                            .where(\Book.id != nil)
                            .sort(asc: \.name),
                        attribute: \.name
                    )
                })

                XCTAssert(bookWithIDs == ["10", "2", "4", "6", "8"])

                let bookWithFutureDates = try db.readOnly(action: { reader in
                    try reader.fetch(
                        Book
                            .all
                            .where(\Book.date > Date())
                            .sort(asc: \.name),
                        attribute: \.name
                    )
                })

                XCTAssert(bookWithFutureDates == ["1", "3", "5", "7", "9"])

                let bookWithFutureDatesAndExcludedIDs = try db.readOnly(action: { reader in
                    try reader.fetch(
                        Book
                            .all
                            .where(\Book.date > Date() && !(\Book.name === ["3", "5"]))
                            .sort(asc: \.name),
                        attribute: \.name
                    )
                })

                XCTAssert(bookWithFutureDatesAndExcludedIDs == ["1", "7", "9"])
            }
        }

        func testAttributeTypes() {
            TestDB.withTemporaryContainer { db in
                let testCases: [FullHouse] = [
                    FullHouse(
                        x1: true,
                        x2: 10,
                        x3: 20,
                        x4: 30,
                        x5: 10,
                        x6: 20,
                        x7: Date(),
                        x8: "foo",
                        x9: .init(.init(id: 10, name: "bar")),
                        x10: URL(string: "google.com"),
                        x11: .init(),
                        x12: 1000,
                        x13: .rty
                    ),
                    FullHouse(),
                    FullHouse(
                        x2: 10,
                        x4: 30,
                        x6: 20,
                        x8: "foo",
                        x10: URL(string: "google.com"),
                        x12: 1000
                    ),
                    FullHouse(
                        x1: true,
                        x3: 20,
                        x5: 10,
                        x7: Date(),
                        x9: .init(.init(id: 10, name: "bar")),
                        x11: .init(),
                        x13: .qwe
                    ),
                ]

                try testCases.forEach { x in
                    // INSERT
                    try db.readWrite { _, writer in
                        try writer.delete(FullHouse.all)
                        try writer.insert(x)
                    }

                    // FETCH
                    let result = try db.readOnly { reader in
                        try reader.fetch(FullHouse.all)
                    }

                    XCTAssert(result.count == 1)
                    XCTAssert(result[0] == x)
                }
            }
        }

        func testCustomAttributeRequest() {
            TestDB.withTemporaryContainer { db in
                let xx: [FullHouse] = [
                    FullHouse(
                        x2: 11,
                        x13: .rty
                    ),
                    FullHouse(
                        x2: 10,
                        x13: .qwe
                    ),
                ]

                // INSERT
                try db.readWrite { _, writer in
                    try writer.batchDelete(FullHouse.all)
                    try xx.forEach {
                        try writer.insert($0)
                    }
                }

                // FETCH
                let result = try db.readOnly { reader in
                    try reader.fetch(FullHouse.all.where(\FullHouse.x13 == .qwe), attribute: \.x2)
                }

                XCTAssert(result.count == 1)
                XCTAssert(result[0] == 10)
            }
        }

        func testTextPredicates() {
            TestDB.withTemporaryContainer { db in
                let xx: [FullHouse] = [
                    FullHouse(
                        x8: "AbCd"
                    ),
                    FullHouse(
                        x8: "aBcD"
                    ),
                ]

                // INSERT
                try db.readWrite { _, writer in
                    try writer.batchDelete(FullHouse.all)
                    try xx.forEach {
                        try writer.insert($0)
                    }
                }

                // FETCH
                do {
                    let result: [String?] = try db.readOnly { reader in
                        try reader.fetch(FullHouse.all.where(Query.contains(\FullHouse.x8, "b")), attribute: \.x8)
                    }

                    XCTAssert(result.count == 2)
                }

                // FETCH
                do {
                    let result: [String?] = try db.readOnly { reader in
                        try reader.fetch(FullHouse.all.where(Query.contains(\FullHouse.x8, "b", caseInsensitive: false)), attribute: \.x8)
                    }

                    XCTAssert(result.count == 1)
                }

                // FETCH
                do {
                    let result: [String?] = try db.readOnly { reader in
                        try reader.fetch(FullHouse.all.where(Query.beginsWith(\FullHouse.x8, "ab")), attribute: \.x8)
                    }

                    XCTAssert(result.count == 2)
                }

                // FETCH
                do {
                    let result: [String?] = try db.readOnly { reader in
                        try reader.fetch(FullHouse.all.where(Query.endsWith(\FullHouse.x8, "cd")), attribute: \.x8)
                    }

                    XCTAssert(result.count == 2)
                }
            }
        }

        func testMultiThreadReadWrite() {
            TestDB.withTemporaryContainer { db in

                let group = DispatchGroup()

                (1 ... 10).forEach { (x: Int16) in
                    group.enter()
                    DispatchQueue.global().async {
                        do {
                            try db.readWrite { _, writer in
                                try writer.insert(FullHouse(x2: x))
                            }
                        } catch {}
                        group.leave()
                    }
                }

                group.wait()

                let items = try db.readOnly { reader in
                    try reader.fetch(FullHouse.all.sort(asc: \.x2), attribute: \.x2)
                }

                XCTAssert(items == Array(1 ... 10))
            }
        }

        func testEncodeDecodeSingleAttribute() {
            TestDB.withTemporaryContainer { db in
                try db.readWrite { _, writer in
                    try writer.batchDelete(FullHouse.all)
                    try writer.insert(FullHouse())
                }

                let a = try db.readOnly { reader in
                    try reader.fetchOne(FullHouse.all, attribute: \.x2)
                }

                XCTAssert(a == nil)

                try db.readWrite { _, writer in
                    try writer.update(FullHouse.all) {
                        $0.encode(attribute: \.x2, 16)
                    }
                }

                let b = try db.readOnly { reader in
                    try reader.fetchOne(FullHouse.all) {
                        try $0.decode(attribute: \.x2)
                    }
                }

                XCTAssert(b == 16)
            }
        }

        func testToManyRelations() {
            TestDB.withTemporaryContainer { db in
                let authorID = UUID()

                do {
                    try db.readWrite { _, writer in
                        try writer.insert(Author.self) {
                            $0.encode(
                                .init(
                                    id: authorID,
                                    name: "pushkin"
                                )
                            )
                            $0[\.books].add(Book(name: "1"))
                            $0[\.books].add(Book(name: "2"))
                            $0[\.books].add(Book(name: "3"))
                        }
                    }
                }

                do {
                    let bookNames = try db.readOnly { reader in
                        try reader.fetchOne(Author.all) {
                            try $0[\.books].map { try $0.decode(attribute: \.name) }.sorted()
                        }
                    }

                    XCTAssert(bookNames == ["1", "2", "3"])
                }

                do {
                    try db.readWrite { _, writer in
                        try writer.update(Author.all) { mo in
                            try mo[\.books].filter {
                                try $0.decode(attribute: \.name) == "2"
                            }.forEach {
                                mo[\.books].remove($0)
                                writer.delete($0)
                            }
                        }
                    }
                }

                do {
                    let bookNames = try db.readOnly { reader in
                        try reader.fetchOne(Author.all) {
                            try $0[\.books].map { try $0.decode(attribute: \.name) }.sorted()
                        }
                    }

                    XCTAssert(bookNames == ["1", "3"])

                    let allBookNames = try db.readOnly { reader in
                        try reader.fetch(Book.all, attribute: \.name).sorted()
                    }

                    XCTAssert(allBookNames == ["1", "3"])
                }
            }
        }

        func testReferenceSemantic() {
            TestDB.withTemporaryContainer { db in
                let bookRef = BookRef()
                bookRef.name = "xxx"

                try db.readWrite { _, writer in
                    try writer.insert(bookRef)
                }

                let fetchedRef = try db.readOnly { reader in
                    try reader.fetchOne(BookRef.all)
                }

                XCTAssert(fetchedRef == bookRef)

                let fetchedRefName = try db.readOnly { reader in
                    try reader.fetchOne(BookRef.all, attribute: \.name)
                }

                XCTAssert(fetchedRefName == "xxx")
            }
        }

        func testOrderedRelations() {
            TestDB.withTemporaryContainer { db in
                let authorID = UUID()

                do {
                    try db.readWrite { _, writer in
                        try writer.insert(Author.self) {
                            $0.encode(
                                .init(
                                    id: authorID,
                                    name: "pushkin"
                                )
                            )
                            $0[\.orderedBooks].add(Book(name: "4"))
                            $0[\.orderedBooks].add(Book(name: "3"))
                            $0[\.orderedBooks].add(Book(name: "2"))
                        }
                    }
                }

                do {
                    let bookNames = try db.readOnly { reader in
                        try reader.fetchOne(Author.all) {
                            try $0[\.orderedBooks].map { try $0.decode(attribute: \.name) }
                        }
                    }

                    XCTAssert(bookNames == ["4", "3", "2"])
                }

                let coverID = UUID()

                do {
                    try db.readWrite { _, writer in
                        try writer.update(Author.all) { mo in
                            for var x in mo[\.orderedBooks] {
                                x.set(\.bookCover, value: .init(id: coverID, imageData: .init(repeating: 0, count: 10)))
                            }

                            try mo[\.orderedBooks].filter {
                                try $0.decode(attribute: \.name) == "3"
                            }.forEach {
                                mo[\.orderedBooks].remove($0)
                                writer.delete($0)
                            }
                        }
                    }
                }

                do {
                    let books = try db.readOnly { reader in
                        try reader.fetchOne(Author.all) {
                            try $0[\.orderedBooks].map {
                                (
                                    try $0.decode(),
                                    try ($0[\.bookCover]?.decode(attribute: \.id))
                                )
                            }
                        }
                    }

                    XCTAssert(books?.map(\.0.name) == ["4", "2"])
                    XCTAssert(books?.map(\.1) == [coverID, coverID])

                    let allBookNames = try db.readOnly { reader in
                        try reader.fetch(Book.all, attribute: \.name).sorted()
                    }

                    XCTAssert(allBookNames == ["2", "4"])
                }
            }
        }
    }
}
