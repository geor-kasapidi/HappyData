enum MigratableModels {
    struct A {
        var id: Int = 0
        var name: String = ""
    }

    struct B: Comparable {
        static func < (lhs: MigratableModels.B, rhs: MigratableModels.B) -> Bool {
            lhs.identifier < rhs.identifier
        }

        var identifier: Double = 0
        var text: String = ""
    }

    struct C: Comparable {
        static func < (lhs: MigratableModels.C, rhs: MigratableModels.C) -> Bool {
            lhs.foo < rhs.foo
        }

        var foo: String = ""
    }
}
