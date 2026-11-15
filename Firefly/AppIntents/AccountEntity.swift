import AppIntents

struct AccountEntity: AppEntity {
    let id: String
    let name: String
    /// Only used to format the confirmation dialog; not exposed to the system.
    let currencySymbol: String?

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Account"
    static let defaultQuery = AccountEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    init(id: String, name: String, currencySymbol: String? = nil) {
        self.id = id
        self.name = name
        self.currencySymbol = currencySymbol
    }

    init?(_ account: AutoAccount) {
        guard let id = account.id else { return nil }
        self.init(id: id, name: account.name ?? "Unnamed Account", currencySymbol: account.currencySymbol)
    }
}

struct AccountEntityQuery: EntityStringQuery {
    /// Account types Firefly accepts as the source of a withdrawal. The autocomplete
    /// endpoint otherwise also returns expense/revenue/system accounts, which the
    /// server rejects as a source.
    private static let withdrawalSourceTypes: Set = ["Asset account", "Default account", "Loan", "Debt", "Mortgage"]

    /// Resolves saved ids against every account type, so a shortcut saved earlier
    /// keeps resolving even if the account isn't in the suggested list.
    func entities(for identifiers: [AccountEntity.ID]) async throws -> [AccountEntity] {
        let wanted = Set(identifiers)
        return try await fetchAccounts()
            .filter { $0.id.map(wanted.contains) ?? false }
            .compactMap(AccountEntity.init)
    }

    func suggestedEntities() async throws -> [AccountEntity] {
        try await sourceAccounts()
    }

    func entities(matching string: String) async throws -> [AccountEntity] {
        try await sourceAccounts().filter { $0.name.localizedStandardContains(string) }
    }

    private func sourceAccounts() async throws -> [AccountEntity] {
        try await fetchAccounts()
            .filter { $0.type.map(Self.withdrawalSourceTypes.contains) ?? false }
            .compactMap(AccountEntity.init)
    }

    private func fetchAccounts() async throws -> AutoAccounts {
        do {
            return try await fetchAccountsAutocomplete()
        } catch {
            throw AddTransactionIntentError.userFacing(error)
        }
    }
}
