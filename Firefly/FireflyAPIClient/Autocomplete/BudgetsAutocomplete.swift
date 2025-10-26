import Foundation

struct AutoBudgetElement: Codable {
    let id, name: String?
}

typealias AutoBudget = [AutoBudgetElement]

func fetchBudgetsAutocomplete() async throws -> AutoBudget {
    try await fetchAutocomplete(for: AutocompleteApiPaths.budgets)
}
