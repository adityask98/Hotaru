import Foundation

// MARK: - AutoAccount

struct AutoAccount: Codable {
    let id, name, nameWithBalance, type: String?
    let currencyID, currencyName, currencyCode, currencySymbol: String?
    let currencyDecimalPlaces: Int?

    enum CodingKeys: String, CodingKey {
        case id, name
        case nameWithBalance = "name_with_balance"
        case type
        case currencyID = "currency_id"
        case currencyName = "currency_name"
        case currencyCode = "currency_code"
        case currencySymbol = "currency_symbol"
        case currencyDecimalPlaces = "currency_decimal_places"
    }
}

typealias AutoAccounts = [AutoAccount]

/// The endpoint caps results at a small server default unless `limit` is given,
/// which would silently hide accounts in the selector.
private let accountsAutocompleteLimit = 1_000

func fetchAccountsAutocomplete() async throws -> AutoAccounts {
    try await fetchAutocomplete(
        for: "\(AutocompleteApiPaths.accounts)?limit=\(accountsAutocompleteLimit)"
    )
}
