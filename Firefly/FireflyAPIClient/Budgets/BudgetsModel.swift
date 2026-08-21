import Foundation

// MARK: - Budgets

struct Budgets: Codable {
    let data: [BudgetsDatum]?
}

// MARK: - BudgetsDatum

struct BudgetsDatum: Codable {
    let type, id: String?
    let attributes: BudgetsAttributes?
}

// MARK: - BudgetsAttributes

struct BudgetsAttributes: Codable {
    let name: String?
    let active: Bool?
    let order: Int?
    let currencySymbol: String?
    let currencyDecimalPlaces: Int?

    enum CodingKeys: String, CodingKey {
        case name, active, order
        case currencySymbol = "currency_symbol"
        case currencyDecimalPlaces = "currency_decimal_places"
    }
}

// MARK: - BudgetLimits

struct BudgetLimits: Codable {
    let data: [BudgetLimitsDatum]?
}

// MARK: - BudgetLimitsDatum

struct BudgetLimitsDatum: Codable {
    let type, id: String?
    let attributes: BudgetLimitsAttributes?
}

// MARK: - BudgetLimitsAttributes

struct BudgetLimitsAttributes: Codable {
    let start, end, budgetID: String?
    let amount: String?
    let currencyCode, currencySymbol: String?
    let currencyDecimalPlaces: Int?
    /// Amount(s) already spent against this limit, one entry per currency used.
    let spent: [BudgetSpentEntry]?

    enum CodingKeys: String, CodingKey {
        case start, end, amount, spent
        case budgetID = "budget_id"
        case currencyCode = "currency_code"
        case currencySymbol = "currency_symbol"
        case currencyDecimalPlaces = "currency_decimal_places"
    }
}

// MARK: - BudgetSpentEntry

struct BudgetSpentEntry: Codable {
    let currencyID, currencyCode, currencySymbol, sum: String?
    let currencyDecimalPlaces: Int?

    enum CodingKeys: String, CodingKey {
        case sum
        case currencyID = "currency_id"
        case currencyCode = "currency_code"
        case currencySymbol = "currency_symbol"
        case currencyDecimalPlaces = "currency_decimal_places"
    }
}

// MARK: - BudgetProgress

/// A budget's spending against its limit for the selected period, ready to render.
struct BudgetProgress: Identifiable {
    let id: String
    let name: String
    /// The budgeted amount, always positive.
    let limit: Decimal
    /// How much has been spent against it, always positive.
    let spent: Decimal
    let currencySymbol: String?
    let currencyDecimalPlaces: Int?

    /// Spend as a share of the limit, clamped to 0...1 for the progress bar.
    var fraction: Double {
        guard limit > 0 else { return 0 }
        return min(max((spent / limit).doubleValue, 0), 1)
    }

    var isOverBudget: Bool {
        spent > limit
    }

    /// What's left of the limit; negative once the budget is blown.
    var remaining: Decimal {
        limit - spent
    }
}

private extension Decimal {
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}
