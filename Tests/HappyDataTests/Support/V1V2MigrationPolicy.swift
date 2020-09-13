import Foundation
import CoreData

@objc(V1V2MigrationPolicy)
final class V1V2MigrationPolicy: NSEntityMigrationPolicy {
    @objc
    func multiplyByTen(_ value: NSNumber) -> NSNumber {
        return NSNumber(value: value.doubleValue * 10)
    }
}
