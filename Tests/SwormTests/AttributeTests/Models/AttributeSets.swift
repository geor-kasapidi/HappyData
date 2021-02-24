import Foundation
import Sworm

struct PrimitiveAttributeFullSet: Equatable {
    var x1: Bool = false

    var x2: Int = .zero
    var x3: Int16 = .zero
    var x4: Int32 = .zero
    var x5: Int64 = .zero

    var x6: Float = .zero
    var x7: Double = .zero
    var x8: Decimal = .zero

    var x9: Date?
    var x10: String?
    var x11: Data?
    var x12: UUID?
    var x13: URL?
}

struct CustomAttributeSet: Equatable {
    struct CustomType: Equatable, Codable, LosslessStringConvertible {
        let x: Int
        let y: Int

        internal init(x: Int, y: Int) {
            self.x = x
            self.y = y
        }

        init?(_ description: String) {
            let parts = description.split(separator: "-")

            guard parts.count == 2,
                  let x = Int(parts[0]),
                  let y = Int(parts[1])
            else {
                return nil
            }

            self.x = x
            self.y = y
        }

        var description: String {
            "\(self.x)-\(self.y)"
        }
    }

    enum CustomEnumeration: Int {
        case x
        case y
        case z
    }

    var x1: JSON<CustomType> = .init(.init(x: 0, y: 0))
    var x2: LSC<CustomType> = .init(.init(x: 0, y: 0))
    var x3: CustomType?
    var x4: CustomType?
    var x5: CustomEnumeration = .x
    var x6: CustomEnumeration = .x
}

final class DemoAttributeSetRef: Equatable {
    static func == (lhs: DemoAttributeSetRef, rhs: DemoAttributeSetRef) -> Bool {
        lhs.x1 == rhs.x1 && lhs.x2 == rhs.x2
    }

    var x1: Int = .zero
    var x2: Int?
}
