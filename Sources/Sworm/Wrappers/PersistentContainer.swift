import CoreData

public final class PersistentContainer {
    private let managedObjectContext: () throws -> NSManagedObjectContext
    private let logError: ((Swift.Error) -> Void)?
    private let cleanUpContextAfterExecution: Bool

    public init(
        managedObjectContext: @escaping () throws -> NSManagedObjectContext,
        logError: ((Swift.Error) -> Void)? = nil,
        cleanUpContextAfterExecution: Bool = true
    ) {
        self.managedObjectContext = managedObjectContext
        self.logError = logError
        self.cleanUpContextAfterExecution = cleanUpContextAfterExecution
    }

    @discardableResult
    public func perform<T>(action: @escaping (ManagedObjectContext) throws -> T) throws -> T {
        do {
            let instance = try self.managedObjectContext()

            return try instance.perform(
                cleanUpAfterExecution: self.cleanUpContextAfterExecution
            ) {
                try action(ManagedObjectContext(instance))
            }
        } catch {
            self.logError?(error)

            throw error
        }
    }
}
