import Foundation

// MARK: - CategoriesInsightElement

struct CategoriesInsightElement: Codable {
    let id, name, difference: String?
    let differenceFloat: Int?
    let currencyID, currencyCode: String?

    enum CodingKeys: String, CodingKey {
        case id, name, difference
        case differenceFloat = "difference_float"
        case currencyID = "currency_id"
        case currencyCode = "currency_code"
    }
}

typealias CategoriesInsight = [CategoriesInsightElement]

func fetchCategoriesExpenseInsights(
    startDate: String,
    endDate: String
) async throws -> CategoriesInsight {
    var request = try RequestBuilder(apiURL: InsightsApiPaths.expenseCategories)
    request.url?.append(queryItems: [
        URLQueryItem(name: "start", value: startDate),
        URLQueryItem(name: "end", value: endDate),
    ])

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw InsightsError.categories
    }

    do {
        let decoder = JSONDecoder()
        let result = try decoder.decode(CategoriesInsight.self, from: data)
        return result
    } catch {
        print(error)
        throw InsightsError.categories
    }
}
