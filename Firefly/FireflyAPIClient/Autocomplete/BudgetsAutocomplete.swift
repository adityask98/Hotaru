//
//  BudgetsAutocomplete.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/12.
//

import Foundation

struct AutoBudgetElement: Codable {
    let id, name: String?
}

typealias AutoBudget = [AutoBudgetElement]

func fetchBudgetsAutocomplete() async throws -> AutoBudget {
    try await fetchAutocomplete(for: autocompleteApiPaths.budgets)
}
