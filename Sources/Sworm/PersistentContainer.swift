import CoreData

public protocol ManagedObjectContextProvider {
    var viewContext: NSManagedObjectContext { get }

    func newBackgroundContext() -> NSManagedObjectContext
}

extension NSPersistentContainer: ManagedObjectContextProvider {}

public final class PersistentContainer {
    public enum Error: Swift.Error {
        case notReady
    }

    public enum Queue {
        case `private`
        case main
        case automatic
    }

    private let managedObjectContextProvider: ManagedObjectContextProvider

    private let isReady: () -> Bool

    public init(
        _ managedObjectContextProvider: ManagedObjectContextProvider,
        isReady: @escaping () -> Bool = { true }
    ) {
        self.managedObjectContextProvider = managedObjectContextProvider
        self.isReady = isReady
    }

    private func perform<T>(on queue: Queue, _ action: (NSManagedObjectContext) throws -> T) throws -> T {
        guard self.isReady() else { throw Error.notReady }

        switch queue {
        case .main,
             .automatic where Thread.isMainThread:
            return try action(self.managedObjectContextProvider.viewContext)
        case .private,
             .automatic:
            return try action(self.managedObjectContextProvider.newBackgroundContext())
        }
    }

    @discardableResult
    public func readOnly<T>(
        queue: Queue = .automatic,
        action: @escaping (PersistentReader) throws -> T
    ) throws -> T {
        try self.perform(on: queue) { context in
            try context.execute {
                try action(.init(context))
            }
        }
    }

    @discardableResult
    public func readWrite<T>(
        queue: Queue = .automatic,
        action: @escaping (PersistentReader, PersistentWriter) throws -> T
    ) throws -> T {
        try self.perform(on: queue) { context in
            try context.save {
                try action(.init(context), .init(context))
            }
        }
    }
}
