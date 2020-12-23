public enum DBError: Swift.Error, Equatable {
    case actionsProhibited
    case actionWasNotPerformed
    case noCompatibleModelVersionFound
    case badModelVersion(String)
    case badMappingModel(String)
}
