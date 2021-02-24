import Sworm

extension MigratableModels.A: ManagedObjectConvertible {
    static let entityName: String = "A"

    static let attributes: Set<Attribute<MigratableModels.A>> = [
        .init(\.id, "id"),
        .init(\.name, "name"),
    ]

    static let relations: Void = ()
}

extension MigratableModels.B: ManagedObjectConvertible {
    static let entityName: String = "B"

    static let attributes: Set<Attribute<MigratableModels.B>> = [
        .init(\.identifier, "identifier"),
        .init(\.text, "text"),
    ]

    static let relations: Void = ()
}

extension MigratableModels.C: ManagedObjectConvertible {
    static let entityName: String = "C"

    static let attributes: Set<Attribute<MigratableModels.C>> = [
        .init(\.foo, "foo"),
    ]

    static let relations: Void = ()
}
