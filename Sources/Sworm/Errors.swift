public enum ActionError: Swift.Error {
    case actionsProhibited
    case actionWasNotPerformed
}

public enum StoreError: Swift.Error {
    case badVersion(String)
    case noCompatibleVersionFound
    case badMappingModel(String)
}
