import CoreData
import Foundation

public struct PersistentWriter {
    private unowned let instance: NSManagedObjectContext

    public init(_ instance: NSManagedObjectContext) {
        self.instance = instance
    }

    public func insert<PlainObject: ManagedObjectConvertible>(
        _: PlainObject.Type,
        _ closure: @escaping (inout MutableManagedObject<PlainObject>) -> Void
    ) throws {
        var managedObject = MutableManagedObject<PlainObject>(
            instance: self.instance.new(entity: PlainObject.entityName)
        )
        closure(&managedObject)
    }

    public func insert<PlainObject: ManagedObjectConvertible>(_ value: PlainObject) throws {
        try self.insert(PlainObject.self) {
            $0.encode(value)
        }
    }

    @discardableResult
    public func update<PlainObject: ManagedObjectConvertible, Result>(
        _ request: Request<PlainObject>,
        _ closure: @escaping (inout MutableManagedObject<PlainObject>) throws -> Result
    ) throws -> [Result] {
        let fetchRequest = request.makeFetchRequest(
            ofType: (NSManagedObject.self, .managedObjectResultType)
        )
        let managedObjects = try self.instance.fetch(fetchRequest)
        return try managedObjects.map {
            var managedObject = MutableManagedObject<PlainObject>(instance: $0)
            return try closure(&managedObject)
        }
    }

    public func delete<PlainObject: ManagedObjectConvertible>(
        _ managedObject: ManagedObject<PlainObject>
    ) {
        self.instance.delete(managedObject.instance)
    }

    public func delete<PlainObject: ManagedObjectConvertible>(
        _ managedObject: MutableManagedObject<PlainObject>
    ) {
        self.instance.delete(managedObject.instance)
    }

    public func delete<PlainObject: ManagedObjectConvertible>(
        _ request: Request<PlainObject>
    ) throws {
        let fetchRequest = request.makeFetchRequest(
            ofType: (NSManagedObject.self, .managedObjectResultType),
            attributesToFetch: []
        )
        try self.instance.fetch(fetchRequest).forEach {
            self.instance.delete($0)
        }
    }

    @discardableResult
    public func batchDelete<PlainObject: ManagedObjectConvertible>(
        _ request: Request<PlainObject>
    ) throws -> Int {
        let fetchRequest = request.makeFetchRequest(
            ofType: (NSFetchRequestResult.self, .managedObjectIDResultType),
            attributesToFetch: []
        )

        let batchRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        batchRequest.resultType = .resultTypeCount

        let batchResult = try self.instance.execute(batchRequest) as! NSBatchDeleteResult
        return (batchResult.result as! NSNumber).intValue
    }
}

public struct PersistentReader {
    private unowned let instance: NSManagedObjectContext

    public init(_ instance: NSManagedObjectContext) {
        self.instance = instance
    }

    @discardableResult
    public func count<PlainObject: ManagedObjectConvertible>(
        of request: Request<PlainObject>
    ) throws -> Int {
        let fetchRequest = request.makeFetchRequest(
            ofType: (NSNumber.self, .countResultType),
            attributesToFetch: []
        )
        return try self.instance.count(for: fetchRequest)
    }

    @discardableResult
    public func fetch<PlainObject: ManagedObjectConvertible, Result>(
        _ request: Request<PlainObject>,
        _ closure: @escaping (ManagedObject<PlainObject>) throws -> Result
    ) throws -> [Result] {
        let fetchRequest = request.makeFetchRequest(
            ofType: (NSManagedObject.self, .managedObjectResultType)
        )
        return try self.instance.fetch(fetchRequest).map {
            try closure(.init(instance: $0))
        }
    }

    @discardableResult
    public func fetch<PlainObject: ManagedObjectConvertible>(
        _ request: Request<PlainObject>
    ) throws -> [PlainObject] {
        try self.fetch(request) {
            try $0.decode()
        }
    }

    @discardableResult
    public func fetch<PlainObject: ManagedObjectConvertible, Attribute: SupportedAttributeType>(
        _ request: Request<PlainObject>,
        attribute keyPath: KeyPath<PlainObject, Attribute>
    ) throws -> [Attribute] {
        let attribute = PlainObject.attribute(keyPath)
        let fetchRequest = request.makeFetchRequest(
            ofType: (NSDictionary.self, .dictionaryResultType),
            attributesToFetch: [attribute]
        )

        return try self.instance.fetch(fetchRequest).map {
            try Attribute.decodeAny($0[attribute.name])
        }
    }

    @discardableResult
    public func fetch<PlainObject: ManagedObjectConvertible, Attribute: SupportedAttributeType>(
        _ request: Request<PlainObject>,
        attribute keyPath: KeyPath<PlainObject, Attribute?>
    ) throws -> [Attribute?] {
        let attribute = PlainObject.attribute(keyPath)
        let fetchRequest = request.makeFetchRequest(
            ofType: (NSDictionary.self, .dictionaryResultType),
            attributesToFetch: [attribute]
        )

        return try self.instance.fetch(fetchRequest).map {
            try Attribute?.decodeAny($0[attribute.name])
        }
    }

    @discardableResult
    public func fetchOne<PlainObject: ManagedObjectConvertible, Result>(
        _ request: Request<PlainObject>,
        _ closure: @escaping (ManagedObject<PlainObject>) throws -> Result?
    ) throws -> Result? {
        try self.fetch(request.limit(1), closure).first ?? nil
    }

    @discardableResult
    public func fetchOne<PlainObject: ManagedObjectConvertible>(
        _ request: Request<PlainObject>
    ) throws -> PlainObject? {
        try self.fetch(request.limit(1)).first
    }

    @discardableResult
    public func fetchOne<PlainObject: ManagedObjectConvertible, Attribute: SupportedAttributeType>(
        _ request: Request<PlainObject>,
        attribute keyPath: KeyPath<PlainObject, Attribute>
    ) throws -> Attribute? {
        try self.fetch(request.limit(1), attribute: keyPath).first
    }

    @discardableResult
    public func fetchOne<PlainObject: ManagedObjectConvertible, Attribute: SupportedAttributeType>(
        _ request: Request<PlainObject>,
        attribute keyPath: KeyPath<PlainObject, Attribute?>
    ) throws -> Attribute? {
        try self.fetch(request.limit(1), attribute: keyPath).first ?? nil
    }
}
