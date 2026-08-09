import AppIntents

struct AccountEntity: AppEntity {
    let id: String
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Account"
    static var defaultQuery = AccountEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct AccountEntityQuery: EntityQuery {
    func entities(for identifiers: [AccountEntity.ID]) async throws -> [AccountEntity] {
        try await fetchAccountsAutocomplete()
            .compactMap { account in
                guard let id = account.id, identifiers.contains(id) else { return nil }
                return AccountEntity(id: id, name: account.name ?? "Unnamed Account")
            }
    }

    func suggestedEntities() async throws -> [AccountEntity] {
        try await fetchAccountsAutocomplete()
            .compactMap { account in
                guard let id = account.id else { return nil }
                return AccountEntity(id: id, name: account.name ?? "Unnamed Account")
            }
    }
}
