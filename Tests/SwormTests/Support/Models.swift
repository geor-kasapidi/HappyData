import Foundation
import Sworm

struct Author: Hashable {
    var id: UUID?
    var name: String = ""
}

struct Book: Hashable {
    var id: UUID?
    var name: String = ""
    var date: Date?
}

struct BookCover: Hashable {
    var id: UUID?
    var imageData: Data?
}

struct Foo: Hashable {
    var id: Int16 = 0
}

struct FullHouseMeta: Equatable, Codable {
    var id: Int
    var name: String
}

struct FullHouse: Equatable {
    enum RawFoo: String {
        case qwe
        case rty
    }

    var x1: Bool?
    var x2: Int16?
    var x3: Int32?
    var x4: Int64?
    var x5: Double?
    var x6: Float?
    var x7: Date?
    var x8: String?
    var x9: JSON<FullHouseMeta>?
    var x10: URL?
    var x11: UUID?
    var x12: Decimal?
    var x13: RawFoo?
}

final class BookRef: Equatable {
    static func == (lhs: BookRef, rhs: BookRef) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }

    var id: UUID = .init()
    var name: String = ""
}

enum MigratableModels {
    struct A {
        var id: Int = 0
        var name: String = ""
    }

    struct B: Comparable {
        static func < (lhs: MigratableModels.B, rhs: MigratableModels.B) -> Bool {
            lhs.identifier < rhs.identifier
        }

        var identifier: Double = 0
        var text: String = ""
    }

    struct C: Comparable {
        static func < (lhs: MigratableModels.C, rhs: MigratableModels.C) -> Bool {
            lhs.foo < rhs.foo
        }

        var foo: String = ""
    }
}
