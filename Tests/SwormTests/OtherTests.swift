import Foundation
import XCTest
#if DEBUG
    @testable import Sworm

    @available(OSX 10.15, *)
    final class OtherTests: XCTestCase {
//        func testSimpleQuery() {
//            let predicate: Predicate = \BookRef.name == "" && \Book.name != "" && "xxx"
//
//            XCTAssert(predicate.predicateDescriptor.query == "((text == %@) AND (name != %@)) AND (xxx)")
//        }
    }
#endif
