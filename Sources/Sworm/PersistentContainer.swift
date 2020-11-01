import CoreData
import Foundation

public final class PersistentContainer {
    public enum Queue {
        case `private`
        case main
        case automatic
    }

    private let instance: NSPersistentContainer

    public init(_ instance: NSPersistentContainer) {
        self.instance = instance
    }

    private func perform<T>(on queue: Queue, _ action: (NSManagedObjectContext) throws -> T) throws -> T {
        switch queue {
        case .main,
             .automatic where Thread.isMainThread:
            return try action(self.instance.viewContext)
        case .private,
             .automatic:
            return try action(self.instance.newBackgroundContext())
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
