import Foundation

/// Fetches a page of accounts, defaulting to the user's own asset accounts.
/// Shared by the Accounts tab and the Home dashboard's accounts strip.
func fetchAccountsPage(
    limit: Int = 20,
    page: Int = 1,
    type: String = "asset"
) async throws -> Accounts {
    var request = try RequestBuilder(apiURL: ApiPaths.accounts)
    request.url?.append(queryItems: [
        URLQueryItem(name: "page", value: String(page)),
        URLQueryItem(name: "limit", value: String(limit)),
        URLQueryItem(name: "type", value: type),
    ])

    let (data, response) = try await AppNetworking.session.data(for: request)

    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw AccountsModelError.invalidResponse
    }

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(Accounts.self, from: data)
    } catch {
        AppLog.networkError("Failed to decode accounts", error)
        throw AccountsModelError.invalidData
    }
}

// MARK: - Accounts

struct Accounts: Codable {
    var data: [AccountsDatum]?
    var meta: AccountsMeta?
    var links: AccountsLinks?
}

// MARK: - AccountsDatum

struct AccountsDatum: Codable {
    let type, id: String?
    let attributes: AccountsAttributes?
    let links: AccountsDatumLinks?
}

// MARK: - AccountsAttributes

struct AccountsAttributes: Codable {
    let createdAt, updatedAt: String?
    let active: Bool?
    let order: Int?
    let name, type: String?
    let accountRole: String?
    let currencyID, currencyCode, currencySymbol: String?
    let currencyDecimalPlaces: Int?
    let currentBalance, currentBalanceDate: String?
    let notes, monthlyPaymentDate, creditCardType, accountNumber: String?
    let iban, bic: String?
    let virtualBalance, openingBalance: String?
    let openingBalanceDate, liabilityType, liabilityDirection, interest: String?
    let interestPeriod, currentDebt: String?
    let includeNetWorth: Bool?
    let longitude, latitude: Double?
    let zoomLevel: Int?

    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case active, order, name, type
        case accountRole = "account_role"
        case currencyID = "currency_id"
        case currencyCode = "currency_code"
        case currencySymbol = "currency_symbol"
        case currencyDecimalPlaces = "currency_decimal_places"
        case currentBalance = "current_balance"
        case currentBalanceDate = "current_balance_date"
        case notes
        case monthlyPaymentDate = "monthly_payment_date"
        case creditCardType = "credit_card_type"
        case accountNumber = "account_number"
        case iban, bic
        case virtualBalance = "virtual_balance"
        case openingBalance = "opening_balance"
        case openingBalanceDate = "opening_balance_date"
        case liabilityType = "liability_type"
        case liabilityDirection = "liability_direction"
        case interest
        case interestPeriod = "interest_period"
        case currentDebt = "current_debt"
        case includeNetWorth = "include_net_worth"
        case longitude, latitude
        case zoomLevel = "zoom_level"
    }
}

// MARK: - AccountsDatumLinks

struct AccountsDatumLinks: Codable {
    let the0: AccountsThe0?
    let linksSelf: String?

    enum CodingKeys: String, CodingKey {
        case the0 = "0"
        case linksSelf = "self"
    }
}

// MARK: - AccountsThe0

struct AccountsThe0: Codable {
    let rel, uri: String?
}

// MARK: - AccountsLinks

struct AccountsLinks: Codable {
    let linksSelf, first, next, last: String?

    enum CodingKeys: String, CodingKey {
        case linksSelf = "self"
        case first, next, last
    }
}

// MARK: - AccountsMeta

struct AccountsMeta: Codable {
    let pagination: AccountsPagination?
}

// MARK: - AccountsPagination

struct AccountsPagination: Codable {
    let total, count, perPage, currentPage: Int?
    let totalPages: Int?

    enum CodingKeys: String, CodingKey {
        case total, count
        case perPage = "per_page"
        case currentPage = "current_page"
        case totalPages = "total_pages"
    }
}
