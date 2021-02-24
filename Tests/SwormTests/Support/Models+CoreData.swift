import CoreData
import Foundation
import Sworm

extension Author: ManagedObjectConvertible {
    static let entityName: String = "Author"
    static let attributes: Set<Attribute<Author>> = [
        .init(\.id, "id"),
        .init(\.name, "name"),
    ]

    struct Relations {
        let books = ToManyRelation<Book>("books")
        let orderedBooks = ToManyOrderedRelation<Book>("orderedBooks")
    }

    static let relations = Relations()
}

extension Book: ManagedObjectConvertible {
    static let entityName: String = "Book"
    static let attributes: Set<Attribute<Book>> = [
        .init(\.id, "id"),
        .init(\.name, "name"),
        .init(\.date, "date"),
    ]

    struct Relations {
        let bookCover = ToOneRelation<BookCover>("cover")
        let authors = ToManyRelation<Author>("authors")
    }

    static let relations = Relations()
}

extension BookCover: ManagedObjectConvertible {
    static let entityName: String = "BookCover"
    static let attributes: Set<Attribute<BookCover>> = [
        .init(\.id, "id"),
        .init(\.imageData, "imageData"),
    ]

    struct Relations {
        let book = ToOneRelation<Book>("book")
        let foo = ToOneRelation<Foo>("foo")
    }

    static let relations = Relations()
}

extension Foo: ManagedObjectConvertible {
    static let entityName: String = "Foo"
    static let attributes: Set<Attribute<Foo>> = [
        .init(\.id, "id"),
    ]

    struct Relations {
        let book = ToOneRelation<Book>("book")
    }

    static let relations = Relations()
}
