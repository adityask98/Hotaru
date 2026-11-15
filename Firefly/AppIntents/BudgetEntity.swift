import AppIntents

struct BudgetEntity: AppEntity {
    let id: String
    let name: String

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Budget"
    static let defaultQuery = BudgetEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    init?(_ budget: AutoBudgetElement) {
        guard let id = budget.id, let name = budget.name else { return nil }
        self.id = id
        self.name = name
    }
}

struct BudgetEntityQuery: EntityStringQuery {
    func entities(for identifiers: [BudgetEntity.ID]) async throws -> [BudgetEntity] {
        let wanted = Set(identifiers)
        return try await allBudgets().filter { wanted.contains($0.id) }
    }

    func suggestedEntities() async throws -> [BudgetEntity] {
        try await allBudgets()
    }

    func entities(matching string: String) async throws -> [BudgetEntity] {
        try await allBudgets().filter { $0.name.localizedStandardContains(string) }
    }

    private func allBudgets() async throws -> [BudgetEntity] {
        do {
            return try await fetchBudgetsAutocomplete().compactMap(BudgetEntity.init)
        } catch {
            throw AddTransactionIntentError.userFacing(error)
        }
    }
}
