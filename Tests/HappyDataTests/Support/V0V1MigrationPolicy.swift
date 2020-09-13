import Foundation
import CoreData

@objc(V0V1MigrationPolicy)
final class V0V1MigrationPolicy: NSEntityMigrationPolicy {
    @objc
    func changeID(_ value: NSNumber) -> NSNumber {
        return NSNumber(value: value.doubleValue)
    }
}
