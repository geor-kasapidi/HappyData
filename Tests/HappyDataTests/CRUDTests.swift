import Foundation
import XCTest
import HappyData

@available(OSX 10.15, *)
final class CRUDTests: XCTestCase {
    func testSingleEntityNoRelationsReadWrite() {
        XCTAssertNoThrow(try TestDB.cleanUp())

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

        do {
            // INSERT
            do {
                try TestDB.shared.readWrite(action: { _, writer in
                    try writer.insert(book1)
                })
            }
            // FETCH
            do {
                let books = try TestDB.shared.readOnly(action: { reader in
                    try reader.fetch(Book.all)
                })

                XCTAssert(books.count == 1)
                XCTAssert(books[0] == book1)
            }
            // UPDATE
            do {
                try TestDB.shared.readWrite(action: { _, writer in
                    try writer.update(Book.all) {
                        $0.encode(book2)
                    }
                })
            }
            // FETCH
            do {
                let books = try TestDB.shared.readOnly(action: { reader in
                    try reader.fetch(Book.all)
                })

                XCTAssert(books.count == 1)
                XCTAssert(books[0] == book2)
            }
            // DELETE
            do {
                try TestDB.shared.readWrite(action: { _, writer in
                    try writer.delete(Book.all)
                })
            }
            // COUNT
            do {
                let booksCount = try TestDB.shared.readOnly(action: { reader in
                    try reader.count(of: Book.all)
                })

                XCTAssert(booksCount == 0)
            }
        } catch {
            XCTAssert(false, error.localizedDescription)
        }
    }

    func testSingleEntityWithRelationsReadWrite() {
        XCTAssertNoThrow(try TestDB.cleanUp())

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

        do {
            // INSERT
            do {
                try TestDB.shared.readWrite(action: { _, writer in
                    try writer.insert(Book.self) {
                        $0.encode(book1)
                        $0.set(\.bookCover, value: cover)
                        $0[\.bookCover]?.set(\.foo, value: foo)
                    }
                })
            }
            // FETCH
            do {
                let booksWithCoversWithFoos = try TestDB.shared.readOnly(action: { reader in
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
                try TestDB.shared.readWrite(action: { _, writer in
                    try writer.update(Book.all) {
                        $0[\.bookCover]?.set(\.book, value: book2)
                        $0[\.bookCover]?.set(\.foo, object: nil)
                    }
                })
            }
            // FETCH
            do {
                let booksWithCoversWithFoos = try TestDB.shared.readOnly(action: { reader in
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
        } catch {
            XCTAssert(false, error.localizedDescription)
        }
    }

    func testNotUniqueInsertFail() {
        XCTAssertNoThrow(try TestDB.cleanUp())

        let book = Book(
            id: .init(),
            name: "A",
            date: Date()
        )

        var hasError: Bool = false

        do {
            // INSERT (success)
            do {
                try TestDB.shared.readWrite(action: { _, writer in
                    try writer.insert(book)
                })
            }
            // INSERT (fail)
            do {
                try TestDB.shared.readWrite(action: { _, writer in
                    try writer.insert(book)
                })
            }
        } catch {
            hasError = true
        }

        XCTAssert(hasError)
    }

    func testNotUniqueInsertFetch() {
        XCTAssertNoThrow(try TestDB.cleanUp())

        let book = Book(
            id: .init(),
            name: "A",
            date: Date()
        )

        var hasError: Bool = false

        // INSERT
        do {
            try TestDB.shared.readWrite(action: { _, writer in
                for _ in 1...10 {
                    try writer.insert(book)
                }
            })
        } catch {
            hasError = true
        }

        XCTAssert(hasError)

        // FETCH
        do {
            let books = try TestDB.shared.readOnly(action: { reader in
                try reader.fetch(Book.all)
            })

            XCTAssert(books.isEmpty)
        } catch {}
    }

    func testRequestSortLimit() {
        XCTAssertNoThrow(try TestDB.cleanUp())

        // INSERT
        do {
            try TestDB.shared.readWrite(action: { _, writer in
                for i in (1...10).reversed() {
                    try writer.insert(
                        Book(
                            id: .init(),
                            name: "\(i)",
                            date: i % 2 == 0 ? Date.distantPast : Date.distantFuture
                        )
                    )
                }
            })
        } catch {
            XCTFail(error.localizedDescription)
        }

        // FETCH
        do {
            let bookNames = try TestDB.shared.readOnly(action: { reader in
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
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testRequestPredicate() {
        XCTAssertNoThrow(try TestDB.cleanUp())

        // INSERT
        do {
            try TestDB.shared.readWrite(action: { _, writer in
                for i in (1...10).reversed() {
                    try writer.insert(
                        Book(
                            id: i % 2 == 0 ? .init() : nil,
                            name: "\(i)",
                            date: i % 2 == 0 ? Date.distantPast : Date.distantFuture
                        )
                    )
                }
            })
        } catch {
            XCTFail(error.localizedDescription)
        }

        // FETCH
        do {
            let bookWithoutIDs = try TestDB.shared.readOnly(action: { reader in
                try reader.fetch(
                    Book
                        .all
                        .where(\Book.id == nil)
                        .sort(asc: \.name),
                    attribute: \.name
                )
            })

            XCTAssert(bookWithoutIDs == ["1", "3", "5", "7", "9"])

            let bookWithIDs = try TestDB.shared.readOnly(action: { reader in
                try reader.fetch(
                    Book
                        .all
                        .where(\Book.id != nil)
                        .sort(asc: \.name),
                    attribute: \.name
                )
            })

            XCTAssert(bookWithIDs == ["10", "2", "4", "6", "8"])

            let bookWithFutureDates = try TestDB.shared.readOnly(action: { reader in
                try reader.fetch(
                    Book
                        .all
                        .where(\Book.date > Date())
                        .sort(asc: \.name),
                    attribute: \.name
                )
            })

            XCTAssert(bookWithFutureDates == ["1", "3", "5", "7", "9"])

            let bookWithFutureDatesAndExcludedIDs = try TestDB.shared.readOnly(action: { reader in
                try reader.fetch(
                    Book
                        .all
                        .where(\Book.date > Date() && !(\Book.name === ["3", "5"]))
                        .sort(asc: \.name),
                    attribute: \.name
                )
            })

            XCTAssert(bookWithFutureDatesAndExcludedIDs == ["1", "7", "9"])
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testAttributeTypes() {
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

        testCases.forEach { x in
            // INSERT
            do {
                try TestDB.shared.readWrite { _, writer in
                    try writer.delete(FullHouse.all)
                    try writer.insert(x)
                }
            } catch {
                XCTFail(error.localizedDescription)
            }

            // FETCH
            do {
                let result = try TestDB.shared.readOnly { reader in
                    try reader.fetch(FullHouse.all)
                }

                XCTAssert(result.count == 1)
                XCTAssert(result[0] == x)
            } catch {
                XCTFail(error.localizedDescription)
            }
        }
    }

    func testCustomAttributeRequest() {
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
        do {
            try TestDB.shared.readWrite { _, writer in
                try writer.batchDelete(FullHouse.all)
                try xx.forEach {
                    try writer.insert($0)
                }

            }
        } catch {
            XCTFail(error.localizedDescription)
        }

        // FETCH
        do {
            let result = try TestDB.shared.readOnly { reader in
                try reader.fetch(FullHouse.all.where(\FullHouse.x13 == .qwe), attribute: \.x2)
            }

            XCTAssert(result.count == 1)
            XCTAssert(result[0] == 10)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testTextPredicates() {
        let xx: [FullHouse] = [
            FullHouse(
                x8: "AbCd"
            ),
            FullHouse(
                x8: "aBcD"
            ),
        ]

        // INSERT
        do {
            try TestDB.shared.readWrite { _, writer in
                try writer.batchDelete(FullHouse.all)
                try xx.forEach {
                    try writer.insert($0)
                }

            }
        } catch {
            XCTFail(error.localizedDescription)
        }

        // FETCH
        do {
            let result: [String?] = try TestDB.shared.readOnly { reader in
                try reader.fetch(FullHouse.all.where(Query.contains(\FullHouse.x8, "b")), attribute: \.x8)
            }

            XCTAssert(result.count == 2)
        } catch {
            XCTFail(error.localizedDescription)
        }

        // FETCH
        do {
            let result: [String?] = try TestDB.shared.readOnly { reader in
                try reader.fetch(FullHouse.all.where(Query.contains(\FullHouse.x8, "b", caseInsensitive: false)), attribute: \.x8)
            }

            XCTAssert(result.count == 1)
        } catch {
            XCTFail(error.localizedDescription)
        }

        // FETCH
        do {
            let result: [String?] = try TestDB.shared.readOnly { reader in
                try reader.fetch(FullHouse.all.where(Query.beginsWith(\FullHouse.x8, "ab")), attribute: \.x8)
            }

            XCTAssert(result.count == 2)
        } catch {
            XCTFail(error.localizedDescription)
        }

        // FETCH
        do {
            let result: [String?] = try TestDB.shared.readOnly { reader in
                try reader.fetch(FullHouse.all.where(Query.endsWith(\FullHouse.x8, "cd")), attribute: \.x8)
            }

            XCTAssert(result.count == 2)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testMultiThreadReadWrite() {
        XCTAssertNoThrow(try TestDB.shared.readWrite { _, writer in
            try writer.batchDelete(FullHouse.all)
        })

        let group = DispatchGroup()

        (1...10).forEach { (x: Int16) in
            group.enter()
            DispatchQueue.global().async {
                do {
                    try TestDB.shared.readWrite { _, writer in
                        try writer.insert(FullHouse(x2: x))
                    }
                } catch {}
                group.leave()
            }
        }

        group.wait()

        do {
            let items = try TestDB.shared.readOnly { reader in
                try reader.fetch(FullHouse.all.sort(asc: \.x2), attribute: \.x2)
            }

            XCTAssert(items == Array(1...10))
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testEncodeDecodeSingleAttribute() {
        do {
            try TestDB.shared.readWrite { _, writer in
                try writer.batchDelete(FullHouse.all)
                try writer.insert(FullHouse())
            }

            let a = try TestDB.shared.readOnly { reader in
                try reader.fetchOne(FullHouse.all, attribute: \.x2)
            }?.flatMap({ $0 })

            XCTAssert(a == nil)

            try TestDB.shared.readWrite { _, writer in
                try writer.update(FullHouse.all) {
                    $0.encode(attribute: \.x2, 16)
                }
            }

            let b = try TestDB.shared.readOnly { reader in
                try reader.fetchOne(FullHouse.all) {
                    try $0.decode(attribute: \.x2)
                }
            }?.flatMap({ $0 })

            XCTAssert(b == 16)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testToManyRelations() {
        XCTAssertNoThrow(try TestDB.cleanUp())

        do {
            let authorID = UUID()

            do {
                try TestDB.shared.readWrite { _, writer in
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
                let bookNames = try TestDB.shared.readOnly { reader in
                    try reader.fetchOne(Author.all) {
                        try $0[\.books].map({ try $0.decode(attribute: \.name) }).sorted()
                    }
                }

                XCTAssert(bookNames == ["1", "2", "3"])
            }

            do {
                try TestDB.shared.readWrite { _, writer in
                    try writer.update(Author.all) { mo in
                        try mo[\.books].filter({
                            try $0.decode(attribute: \.name) == "2"
                        }).forEach({
                            mo[\.books].remove($0)
                            writer.delete($0)
                        })
                    }
                }
            }

            do {
                let bookNames = try TestDB.shared.readOnly { reader in
                    try reader.fetchOne(Author.all) {
                        try $0[\.books].map({ try $0.decode(attribute: \.name) }).sorted()
                    }
                }

                XCTAssert(bookNames == ["1", "3"])

                let allBookNames = try TestDB.shared.readOnly { reader in
                    try reader.fetch(Book.all, attribute: \.name).sorted()
                }

                XCTAssert(allBookNames == ["1", "3"])
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testReferenceSemantic() {
        do {
            let bookRef = BookRef()
            bookRef.name = "xxx"

            try TestDB.shared.readWrite { _, writer in
                try writer.insert(bookRef)
            }

            let fetchedRef = try TestDB.shared.readOnly { reader in
                try reader.fetchOne(BookRef.all)
            }

            XCTAssert(fetchedRef == bookRef)
        } catch {
            XCTFail(error.localizedDescription)
        }

        do {
            let fetchedRefName = try TestDB.shared.readOnly { reader in
                try reader.fetchOne(BookRef.all, attribute: \.name)
            }

            XCTAssert(fetchedRefName == "xxx")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testOrderedRelations() {
        XCTAssertNoThrow(try TestDB.cleanUp())

        do {
            let authorID = UUID()

            do {
                try TestDB.shared.readWrite { _, writer in
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
                let bookNames = try TestDB.shared.readOnly { reader in
                    try reader.fetchOne(Author.all) {
                        try $0[\.orderedBooks].map({ try $0.decode(attribute: \.name) })
                    }
                }

                XCTAssert(bookNames == ["4", "3", "2"])
            }

            let coverID = UUID()

            do {
                try TestDB.shared.readWrite { _, writer in
                    try writer.update(Author.all) { mo in
                        for var x in mo[\.orderedBooks] {
                            x.set(\.bookCover, value: .init(id: coverID, imageData:.init(repeating: 0, count: 10)))
                        }

                        try mo[\.orderedBooks].filter({
                            try $0.decode(attribute: \.name) == "3"
                        }).forEach({
                            mo[\.orderedBooks].remove($0)
                            writer.delete($0)
                        })
                    }
                }
            }

            do {
                let books = try TestDB.shared.readOnly { reader in
                    try reader.fetchOne(Author.all) {
                        try $0[\.orderedBooks].map({
                            (
                                try $0.decode(),
                                try ($0[\.bookCover]?.decode(attribute: \.id))
                            )
                        })
                    }
                }

                XCTAssert(books?.map({ $0.0.name }) == ["4", "2"])
                XCTAssert(books?.map({ $0.1 }) == [coverID, coverID])

                let allBookNames = try TestDB.shared.readOnly { reader in
                    try reader.fetch(Book.all, attribute: \.name).sorted()
                }

                XCTAssert(allBookNames == ["2", "4"])
            }
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
}
