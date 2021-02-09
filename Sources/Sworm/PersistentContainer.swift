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

    @inline(__always)
    private func perform<T>(_ action: (NSManagedObjectContext) throws -> T) throws -> T {
        do {
            let moc = try self.managedObjectContext()

            return try action(moc)
        } catch {
            self.logError?(error)

            throw error
        }
    }

    @discardableResult
    public func readOnly<T>(
        action: @escaping (PersistentReader) throws -> T
    ) throws -> T {
        try self.perform { context in
            try context.execute(cleanUpAfterExecution: true) {
                try action(.init(context))
            }
        }
    }

    @discardableResult
    public func readWrite<T>(action: @escaping (PersistentReader, PersistentWriter) throws -> T) throws -> T {
        try self.perform { context in
            try context.save(cleanUpAfterExecution: true) {
                try action(.init(context), .init(context))
            }
        }
    }
}
