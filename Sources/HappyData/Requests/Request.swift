import Foundation
import CoreData

extension ManagedObjectConvertible {
    public static var all: Request<Self> { .all }
}

typealias PageDescriptor = (limit: Int, offset: Int)

public struct Request<PlainObject: ManagedObjectConvertible> {
    typealias SortDescriptor = (keyPath: PartialKeyPath<PlainObject>, asc: Bool)

    let predicateDescriptor: PredicateDescriptor?
    let pageDescriptor: PageDescriptor?
    let sortDescriptors: [SortDescriptor]

    public static var all: Self {
        .init(
            predicateDescriptor: nil,
            pageDescriptor: nil,
            sortDescriptors: []
        )
    }

    public func `where`(raw query: String, _ args: Any...) -> Request<PlainObject> {
        .init(
            predicateDescriptor: .init(query: query, args: args),
            pageDescriptor: self.pageDescriptor,
            sortDescriptors: self.sortDescriptors
        )
    }

    public func `where`(_ predicate: Predicate) -> Request<PlainObject> {
        .init(
            predicateDescriptor: predicate.predicateDescriptor,
            pageDescriptor: self.pageDescriptor,
            sortDescriptors: self.sortDescriptors
        )
    }

    public func limit(_ limit: Int, offset: Int = 0) -> Request<PlainObject> {
        .init(
            predicateDescriptor: self.predicateDescriptor,
            pageDescriptor: (limit, offset),
            sortDescriptors: self.sortDescriptors
        )
    }

    public func sort<Attribute: SupportedAttributeType>(
        asc keyPath: KeyPath<PlainObject, Attribute>
    ) -> Request<PlainObject> {
        .init(
            predicateDescriptor: self.predicateDescriptor,
            pageDescriptor: self.pageDescriptor,
            sortDescriptors: self.sortDescriptors + [(keyPath, true)]
        )
    }

    public func sort<Attribute: SupportedAttributeType>(
        desc keyPath: KeyPath<PlainObject, Attribute>
    ) -> Request<PlainObject> {
        .init(
            predicateDescriptor: self.predicateDescriptor,
            pageDescriptor: self.pageDescriptor,
            sortDescriptors: self.sortDescriptors + [(keyPath, false)]
        )
    }
}

extension Request {
    func makeFetchRequest<ResultType: NSFetchRequestResult>(
        ofType resultType: (ResultType.Type, NSFetchRequestResultType),
        attributesToFetch: Set<Attribute<PlainObject>>? = nil
    ) -> NSFetchRequest<ResultType> {
        let propertiesToFetch = (attributesToFetch ?? PlainObject.attributes).map(\.name)

        let fetchRequest = NSFetchRequest<ResultType>(entityName: PlainObject.entityName)
        fetchRequest.resultType = resultType.1
        fetchRequest.propertiesToFetch = propertiesToFetch
        fetchRequest.includesPropertyValues = !propertiesToFetch.isEmpty

        self.predicateDescriptor.flatMap {
            fetchRequest.predicate = NSPredicate(
                format: $0.query,
                argumentArray: $0.args
            )
        }
        self.pageDescriptor.flatMap {
            fetchRequest.fetchLimit = $0.limit
            fetchRequest.fetchOffset = $0.offset
        }
        if !self.sortDescriptors.isEmpty {
            fetchRequest.sortDescriptors = self.sortDescriptors.map {
                NSSortDescriptor(
                    key: PlainObject.attribute($0.keyPath).name,
                    ascending: $0.asc
                )
            }
        }

        return fetchRequest
    }
}
