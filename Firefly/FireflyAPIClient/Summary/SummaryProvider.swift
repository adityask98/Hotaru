import Foundation

enum SummaryError: Error {
    case invalidResponse
    case decodeError
}

/// Fetches `/v1/summary/basic` — the same pre-computed, multi-currency figures the
/// official Firefly III web dashboard is built on (spent, earned, net worth,
/// left to spend, bills paid/unpaid) for a date range.
func fetchBasicSummary(startDate: String, endDate: String) async throws -> BasicSummary {
    var request = try RequestBuilder(apiURL: SummaryApiPaths.basic)
    request.url?.append(queryItems: [
        URLQueryItem(name: "start", value: startDate),
        URLQueryItem(name: "end", value: endDate),
    ])

    let (data, response) = try await AppNetworking.session.data(for: request)
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw SummaryError.invalidResponse
    }

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(BasicSummary.self, from: data)
    } catch {
        AppLog.networkError("Failed to decode basic summary", error)
        throw SummaryError.decodeError
    }
}
