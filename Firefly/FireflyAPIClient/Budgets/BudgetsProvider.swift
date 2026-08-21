import Foundation

enum BudgetsError: Error {
    case invalidResponse
    case decodeError
}

func fetchBudgets(startDate: String, endDate: String) async throws -> Budgets {
    var request = try RequestBuilder(apiURL: BudgetsApiPaths.budgets)
    request.url?.append(queryItems: [
        URLQueryItem(name: "start", value: startDate),
        URLQueryItem(name: "end", value: endDate),
    ])

    return try await performBudgetsRequest(request, description: "budgets")
}

func fetchBudgetLimits(startDate: String, endDate: String) async throws -> BudgetLimits {
    var request = try RequestBuilder(apiURL: BudgetsApiPaths.budgetLimits)
    request.url?.append(queryItems: [
        URLQueryItem(name: "start", value: startDate),
        URLQueryItem(name: "end", value: endDate),
    ])

    return try await performBudgetsRequest(request, description: "budget limits")
}

/// Builds per-budget spend-vs-limit progress for a period.
///
/// Two calls rather than one per budget: `/budget-limits` carries the limit amount
/// and the amount already spent against it, and `/budgets` supplies the names and
/// display order. Budgets without a limit in the period are left out — there's no
/// target to show progress against.
func fetchBudgetProgress(startDate: String, endDate: String) async throws -> [BudgetProgress] {
    async let budgetsTask = fetchBudgets(startDate: startDate, endDate: endDate)
    async let limitsTask = fetchBudgetLimits(startDate: startDate, endDate: endDate)
    let (budgets, limits) = try await(budgetsTask, limitsTask)

    var budgetsByID: [String: BudgetsDatum] = [:]
    for budget in budgets.data ?? [] {
        guard let id = budget.id else { continue }
        budgetsByID[id] = budget
    }

    // A budget can have more than one limit inside the period (e.g. weekly limits
    // within a month), so accumulate them into a single bar per budget.
    var totals: [String: BudgetTotals] = [:]
    var order: [String] = []

    for limit in limits.data ?? [] {
        guard let attributes = limit.attributes,
              let budgetID = attributes.budgetID,
              let amount = Decimal(string: attributes.amount ?? "") else { continue }

        var entry = totals[budgetID] ?? BudgetTotals()
        entry.limit += abs(amount)
        entry.spent += spentTotal(for: attributes)
        if entry.symbol == nil { entry.symbol = attributes.currencySymbol }
        if entry.decimals == nil { entry.decimals = attributes.currencyDecimalPlaces }
        if totals[budgetID] == nil { order.append(budgetID) }
        totals[budgetID] = entry
    }

    return order.compactMap { budgetID -> BudgetProgress? in
        guard let entry = totals[budgetID] else { return nil }
        let attributes = budgetsByID[budgetID]?.attributes
        // Inactive budgets still return limits; they aren't worth dashboard space
        if attributes?.active == false { return nil }
        return BudgetProgress(
            id: budgetID,
            name: attributes?.name ?? "Budget",
            limit: entry.limit,
            spent: entry.spent,
            currencySymbol: entry.symbol ?? attributes?.currencySymbol,
            currencyDecimalPlaces: entry.decimals ?? attributes?.currencyDecimalPlaces
        )
    }
    .sorted { lhs, rhs in
        let lhsOrder = budgetsByID[lhs.id]?.attributes?.order ?? Int.max
        let rhsOrder = budgetsByID[rhs.id]?.attributes?.order ?? Int.max
        if lhsOrder != rhsOrder { return lhsOrder < rhsOrder }
        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }
}

/// Running totals while several limits of the same budget are folded together.
private struct BudgetTotals {
    var limit: Decimal = 0
    var spent: Decimal = 0
    var symbol: String?
    var decimals: Int?
}

/// Sums what's been spent against a limit, as a positive amount.
///
/// `spent` reports one entry per currency actually used, so entries in a currency
/// other than the limit's own would be adding apples to oranges — prefer the
/// matching currency, and only fall back to summing everything when the limit
/// doesn't say which currency it's in.
private func spentTotal(for attributes: BudgetLimitsAttributes) -> Decimal {
    let entries = attributes.spent ?? []
    let matching = attributes.currencyCode.map { code in
        entries.filter { $0.currencyCode == code }
    } ?? []
    let relevant = matching.isEmpty ? entries : matching

    return relevant.reduce(Decimal.zero) { sum, entry in
        sum + abs(Decimal(string: entry.sum ?? "") ?? 0)
    }
}

private func performBudgetsRequest<T: Decodable>(
    _ request: URLRequest,
    description: String
) async throws -> T {
    let (data, response) = try await AppNetworking.session.data(for: request)
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw BudgetsError.invalidResponse
    }

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        AppLog.networkError("Failed to decode \(description)", error)
        throw BudgetsError.decodeError
    }
}
