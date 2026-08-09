import Foundation

// MARK: - CategoriesInsightElement

struct CategoriesInsightElement: Codable {
    let id, name, difference: String?
    let differenceFloat: Double?
    let currencyID, currencyCode: String?

    enum CodingKeys: String, CodingKey {
        case id, name, difference
        case differenceFloat = "difference_float"
        case currencyID = "currency_id"
        case currencyCode = "currency_code"
    }
}

typealias CategoriesInsight = [CategoriesInsightElement]

/// Shares category-insight fetches between views so multiple charts on one
/// screen (e.g. the Home bar chart and donut) issue a single request per
/// date range instead of one each. Successful results stay cached until
/// `invalidate()` is called (pull-to-refresh); failures are not cached.
@MainActor
final class CategoriesInsightStore: ObservableObject {
    private var inFlight: [String: Task<CategoriesInsight, Error>] = [:]

    func insights(startDate: String, endDate: String) async throws -> CategoriesInsight {
        let key = "\(startDate)|\(endDate)"
        if let task = inFlight[key] {
            return try await task.value
        }
        let task = Task {
            try await fetchCategoriesExpenseInsights(startDate: startDate, endDate: endDate)
        }
        inFlight[key] = task
        do {
            return try await task.value
        } catch {
            inFlight[key] = nil
            throw error
        }
    }

    /// Drops cached results so the next request hits the server
    func invalidate() {
        inFlight.removeAll()
    }
}

func fetchCategoriesExpenseInsights(
    startDate: String,
    endDate: String
) async throws -> CategoriesInsight {
    var request = try RequestBuilder(apiURL: InsightsApiPaths.expenseCategories)
    request.url?.append(queryItems: [
        URLQueryItem(name: "start", value: startDate),
        URLQueryItem(name: "end", value: endDate),
    ])

    let (data, response) = try await AppNetworking.session.data(for: request)
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw InsightsError.categories
    }

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(CategoriesInsight.self, from: data)
    } catch {
        AppLog.networkError("Failed to decode category insights", error)
        throw InsightsError.categories
    }
}
