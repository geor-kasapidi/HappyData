public enum AttributeError: Swift.Error {
    case invalidInput
    case badAttribute(name: String, entity: String, value: Any?, originalError: Swift.Error)
}
