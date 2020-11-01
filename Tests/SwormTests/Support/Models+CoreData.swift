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

extension FullHouse.RawFoo: SupportedAttributeType {}

extension FullHouse: ManagedObjectConvertible {
    static let entityName: String = "FullHouse"

    static let attributes: Set<Attribute<FullHouse>> = [
        .init(\.x1, "x1"),
        .init(\.x2, "x2"),
        .init(\.x3, "x3"),
        .init(\.x4, "x4"),
        .init(\.x5, "x5"),
        .init(\.x6, "x6"),
        .init(\.x7, "x7"),
        .init(\.x8, "x8"),
        .init(\.x9, "x9"),
        .init(\.x10, "x10"),
        .init(\.x11, "x11"),
        .init(\.x12, "x12"),
        .init(\.x13, "x13"),
    ]

    static let relations: Void = ()
}

extension BookRef: ManagedObjectConvertible {
    static let entityName: String = "BookRef"

    static let attributes: Set<Attribute<BookRef>> = [
        .init(\.id, "id"),
        .init(\.name, "text"),
    ]

    static let relations: Void = ()
}

extension MigratableModels.A: ManagedObjectConvertible {
    static let entityName: String = "A"

    static let attributes: Set<Attribute<MigratableModels.A>> = [
        .init(\.id, "id"),
        .init(\.name, "name"),
    ]

    static let relations: Void = ()
}

extension MigratableModels.B: ManagedObjectConvertible {
    static let entityName: String = "B"

    static let attributes: Set<Attribute<MigratableModels.B>> = [
        .init(\.identifier, "identifier"),
        .init(\.text, "text"),
    ]

    static let relations: Void = ()
}

extension MigratableModels.C: ManagedObjectConvertible {
    static let entityName: String = "C"

    static let attributes: Set<Attribute<MigratableModels.C>> = [
        .init(\.foo, "foo"),
    ]

    static let relations: Void = ()
}
