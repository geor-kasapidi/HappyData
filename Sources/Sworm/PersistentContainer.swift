import CoreData

public final class PersistentContainer {
    private let managedObjectContext: () throws -> NSManagedObjectContext

    public init(managedObjectContext: @escaping () throws -> NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }

    @inline(__always)
    private func perform<T>(_ action: (NSManagedObjectContext) throws -> T) throws -> T {
        try action(self.managedObjectContext())
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
