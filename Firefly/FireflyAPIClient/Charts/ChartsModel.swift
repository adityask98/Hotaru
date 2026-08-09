import Foundation

enum ChartsError: Error {
    case decodeError
    case common
}

// MARK: - ChartOverviewElement

struct ChartOverviewElement: Codable {
    let label, currencyID, currencyCode, currencySymbol: String?
    let currencyDecimalPlaces: Int?
    let startDate, endDate, type: String?
    let yAxisID: Int?
    let entries: [String: String]?

    enum CodingKeys: String, CodingKey {
        case label
        case currencyID = "currency_id"
        case currencyCode = "currency_code"
        case currencySymbol = "currency_symbol"
        case currencyDecimalPlaces = "currency_decimal_places"
        case startDate = "start_date"
        case endDate = "end_date"
        case type, yAxisID, entries
    }
}

typealias ChartOverview = [ChartOverviewElement]

/// Shares account-balance chart fetches so pull-to-refresh and period changes
/// don't pile up duplicate in-flight requests. Successful results stay cached
/// until `invalidate()` is called; failures are not cached.
@MainActor
final class ChartOverviewStore: ObservableObject {
    private var inFlight: [String: Task<ChartOverview, Error>] = [:]

    func overview(
        startDate: String,
        endDate: String,
        period: String? = nil,
        preselected: String? = nil
    ) async throws -> ChartOverview {
        let key = "\(startDate)|\(endDate)|\(period ?? "")|\(preselected ?? "")"
        if let task = inFlight[key] {
            return try await task.value
        }
        let task = Task {
            try await fetchChartOverview(
                startDate: startDate,
                endDate: endDate,
                period: period,
                preselected: preselected
            )
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

func fetchChartOverview(
    startDate: String,
    endDate: String,
    period: String? = nil,
    preselected: String? = nil
) async throws -> ChartOverview {
    var request = try RequestBuilder(apiURL: ChartsApiPaths.overview)
    var queryItems = [
        URLQueryItem(name: "start", value: startDate),
        URLQueryItem(name: "end", value: endDate),
    ]
    if let period {
        queryItems.append(URLQueryItem(name: "period", value: period))
    }
    if let preselected {
        queryItems.append(URLQueryItem(name: "preselected", value: preselected))
    }
    request.url?.append(queryItems: queryItems)

    let (data, response) = try await AppNetworking.session.data(for: request)
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw ChartsError.common
    }

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(ChartOverview.self, from: data)
    } catch {
        AppLog.networkError("Failed to decode chart overview", error)
        throw ChartsError.decodeError
    }
}
