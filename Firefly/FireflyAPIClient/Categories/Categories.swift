import Foundation

struct AddCategory: Codable {
    let name: String
    let notes: String?
}

enum AddCategoryError: Error {
    case invalidResponse
    case invalidData
}

func addCategory(params: AddCategory) async throws {
    var request = try RequestBuilder(apiURL: PostApiPaths.addCategory, httpMethod: "POST")

    let encoder = JSONEncoder()
    let data = try encoder.encode(params)
    request.httpBody = data
    // print(request.url?.absoluteString)

    let (_, response) = try await URLSession.shared.data(for: request)
    print(response)

    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw AddCategoryError.invalidResponse
    }
}

// MARK: - Categories

struct Categories: Codable {
    let data: [CategoriesDatum]?
    let meta: CategoriesMeta?
    let links: CategoriesLinks?
}

// MARK: - CategoriesDatum

struct CategoriesDatum: Codable {
    let type, id: String?
    let attributes: CategoriesAttributes?
    let links: CategoriesDatumLinks?
}

// MARK: - CategoriesAttributes

struct CategoriesAttributes: Codable {
    let createdAt, updatedAt, name: String?
    let notes: String?
    let spent, earned: [CategoriesEarned]?
    let nativeCurrencyID: String?
    let nativeCurrencyCode: String?
    let nativeCurrencySymbol: String?
    let nativeCurrencyDecimalPlaces: Int?

    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case name, notes, spent, earned
        case nativeCurrencyID = "native_currency_id"
        case nativeCurrencyCode = "native_currency_code"
        case nativeCurrencySymbol = "native_currency_symbol"
        case nativeCurrencyDecimalPlaces = "native_currency_decimal_places"
    }
}

// MARK: - CategoriesEarned

struct CategoriesEarned: Codable {
    let currencyID: String?
    let currencyCode, currencySymbol: String?
    let currencyDecimalPlaces: Int?
    let sum: String?

    enum CodingKeys: String, CodingKey {
        case currencyID = "currency_id"
        case currencyCode = "currency_code"
        case currencySymbol = "currency_symbol"
        case currencyDecimalPlaces = "currency_decimal_places"
        case sum
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let stringValue = try? container.decode(String.self, forKey: .currencyID) {
            currencyID = stringValue
        } else if let intValue = try? container.decode(Int.self, forKey: .currencyID) {
            currencyID = String(intValue)
        } else {
            currencyID = nil
        }

        currencyCode = try container.decodeIfPresent(String.self, forKey: .currencyCode)
        currencySymbol = try container.decodeIfPresent(String.self, forKey: .currencySymbol)
        currencyDecimalPlaces = try container.decodeIfPresent(Int.self, forKey: .currencyDecimalPlaces)
        sum = try container.decodeIfPresent(String.self, forKey: .sum)
    }
}

// MARK: - CategoriesDatumLinks

struct CategoriesDatumLinks: Codable {
    let the0: CategoriesThe0?
    let linksSelf: String?

    enum CodingKeys: String, CodingKey {
        case the0 = "0"
        case linksSelf = "self"
    }
}

// MARK: - CategoriesThe0

struct CategoriesThe0: Codable {
    let rel, uri: String?
}

// MARK: - CategoriesLinks

struct CategoriesLinks: Codable {
    let linksSelf, first, last: String?

    enum CodingKeys: String, CodingKey {
        case linksSelf = "self"
        case first, last
    }
}

// MARK: - CategoriesMeta

struct CategoriesMeta: Codable {
    let pagination: CategoriesPagination?
}

// MARK: - CategoriesPagination

struct CategoriesPagination: Codable {
    let total, count, perPage, currentPage: Int?
    let totalPages: Int?

    enum CodingKeys: String, CodingKey {
        case total, count
        case perPage = "per_page"
        case currentPage = "current_page"
        case totalPages = "total_pages"
    }
}
