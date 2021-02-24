import CoreData

public final class PersistentContainer {
    private let managedObjectContext: () throws -> NSManagedObjectContext
    private let logError: ((Swift.Error) -> Void)?

    public init(
        managedObjectContext: @escaping () throws -> NSManagedObjectContext,
        logError: ((Swift.Error) -> Void)? = nil
    ) {
        self.managedObjectContext = managedObjectContext
        self.logError = logError
    }

    @discardableResult
    public func perform<T>(action: @escaping (ManagedObjectContext) throws -> T) throws -> T {
        do {
            let instance = try self.managedObjectContext()

            return try instance.perform(cleanUpAfterExecution: true) {
                try action(ManagedObjectContext(instance))
            }
        } catch {
            self.logError?(error)

            throw error
        }
    }
}
