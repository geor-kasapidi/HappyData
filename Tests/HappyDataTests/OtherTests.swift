import Foundation
import XCTest
@testable import HappyData

@available(OSX 10.15, *)
final class OtherTests: XCTestCase {
    func testSimpleQuery() {
        let predicate: Predicate = \BookRef.name == "" && \Book.name != "" && "xxx"

        XCTAssert(predicate.predicateDescriptor.query == "((text == %@) AND (name != %@)) AND (xxx)")
    }

    func testWritableKeyPathEquality() {
        let a: WritableKeyPath<Book, UUID?> = \.id
        let b: WritableKeyPath<Book, String> = \.name
        let c: WritableKeyPath<Book, Date?> = \.date

        let a1: PartialKeyPath<Book> = a
        let b1: PartialKeyPath<Book> = b
        let c1: PartialKeyPath<Book> = c

        XCTAssert(Book.attribute(a1).name == "id")
        XCTAssert(Book.attribute(b1).name == "name")
        XCTAssert(Book.attribute(c1).name == "date")
    }

    func testReferenceWritableKeyPathEquality() {
        let a: ReferenceWritableKeyPath<BookRef, UUID> = \.id
        let b: ReferenceWritableKeyPath<BookRef, String> = \.name

        let a1: PartialKeyPath<BookRef> = a
        let b1: PartialKeyPath<BookRef> = b

        XCTAssert(BookRef.attribute(a1).name == "id")
        XCTAssert(BookRef.attribute(b1).name == "text")
    }
}
