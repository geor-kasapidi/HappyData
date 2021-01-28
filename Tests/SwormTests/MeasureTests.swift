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
                    try db.readWrite(action: { _, writer in
                        try (0 ..< 10000).forEach { _ in
                            try writer.insert(book)
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
                    try db.readWrite(action: { _, writer in
                        try (0 ..< 10000).forEach { _ in
                            try writer.insert(Book.self) {
                                $0.encode(book)
                                $0.set(\.bookCover, value: cover)
                            }
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
                    try db.readWrite(action: { _, writer in
                        try writer.insert(Author.self) { mo in
                            mo.encode(.init(id: .init(), name: "xxx"))

                            (0 ..< count).forEach { _ in
                                mo[\.books].add(.init(id: .init(), name: "yyy", date: .init()))
                            }
                        }
                    })

                    try db.readWrite(action: { _, writer in
                        try writer.update(Author.all) { mo in
                            var books = mo[\.books]
                            books.prefix(count / 2).forEach {
                                books.remove($0)
                            }
                        }
                    })

                    let x = try db.readOnly(action: { reader in
                        try reader.fetch(Author.all) {
                            try $0[\.books].map {
                                try $0.decode()
                            }
                        }
                    })
                    XCTAssert(x[0].count == count / 2)
                } catch {
                    XCTFail(error.localizedDescription)
                }
            }
        }
    }

    func testRandomMeasure() {
        TestDB.withTemporaryContainer { db in
            self.measure {
                do {
                    try db.readWrite { _, writer in
                        try writer.batchDelete(FullHouse.all)

                        for _ in 1 ... 10000 {
                            let x = FullHouse(
                                x1: Bool.random() ? nil : .random(),
                                x2: Bool.random() ? nil : .random(in: 100 ... 200),
                                x3: Bool.random() ? nil : .random(in: 100 ... 200),
                                x4: Bool.random() ? nil : .random(in: 100 ... 200),
                                x5: Bool.random() ? nil : .random(in: 100 ... 200),
                                x6: Bool.random() ? nil : .random(in: 100 ... 200),
                                x7: Bool.random() ? nil : Date(),
                                x8: "foo",
                                x9: Bool.random() ? nil : .init(.init(id: .random(in: 100 ... 200), name: "bar")),
                                x10: Bool.random() ? nil : URL(string: "google.com"),
                                x11: Bool.random() ? nil : .init(),
                                x12: Bool.random() ? nil : Decimal(UInt64.random(in: 1000 ... 2000)),
                                x13: Bool.random() ? nil : Bool.random() ? .qwe : .rty
                            )

                            try writer.insert(x)
                        }
                    }

                    let result: [FullHouse] = try db.readOnly { reader in
                        let request = FullHouse
                            .all
                            .sort(desc: \.x2)
                            .limit(10)
                            .where(\FullHouse.x12 < 1500 && \FullHouse.x1 == true || \FullHouse.x7 != nil && \FullHouse.x5 >= Double(150) || !(\FullHouse.x6 > Float(150)))

                        return try reader.fetch(request)
                    }
                    _ = result
                } catch {}
            }
        }
    }
}
