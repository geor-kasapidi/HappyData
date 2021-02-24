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
