import Foundation

enum ChartsError: Error {
    case decodeError
    case categories
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

func fetchChartOverview() async throws -> ChartOverview {
    let request = try RequestBuilder(apiURL: ChartsApiPaths.overview)

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw ChartsError.categories
    }

    do {
        let decoder = JSONDecoder()
        let result = try decoder.decode(ChartOverview.self, from: data)
        print(result)
        return result
    } catch {
        print(error)
        throw ChartsError.decodeError
    }
}
