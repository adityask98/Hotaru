import Foundation

enum CurrenciesError: Error {
    case invalidResponse
    case decodeError
}

// MARK: - CurrencySingle

struct CurrencySingle: Codable {
    let data: CurrencyDatum?
}

// MARK: - CurrencyDatum

struct CurrencyDatum: Codable {
    let type, id: String?
    let attributes: CurrencyAttributes?
}

// MARK: - CurrencyAttributes

struct CurrencyAttributes: Codable {
    let enabled, primary: Bool?
    let code, name, symbol: String?
    let decimalPlaces: Int?

    enum CodingKeys: String, CodingKey {
        case enabled, primary, code, name, symbol
        case decimalPlaces = "decimal_places"
    }
}

/// Fetches the administration's primary currency, used to decide which of the
/// summary's per-currency figures leads the dashboard.
///
/// Firefly III renamed this endpoint from `/currencies/default` to
/// `/currencies/primary` in 6.3; the older path is tried when the newer one 404s
/// so the app keeps working against older self-hosted instances. Callers should
/// treat a failure here as non-fatal — the dashboard falls back to the busiest
/// currency in the summary.
func fetchPrimaryCurrency() async throws -> CurrencyAttributes? {
    do {
        return try await fetchCurrency(at: CurrenciesApiPaths.primary)
    } catch CurrenciesError.invalidResponse {
        return try await fetchCurrency(at: CurrenciesApiPaths.legacyDefault)
    }
}

private func fetchCurrency(at path: String) async throws -> CurrencyAttributes? {
    let request = try RequestBuilder(apiURL: path)

    let (data, response) = try await AppNetworking.session.data(for: request)
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw CurrenciesError.invalidResponse
    }

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(CurrencySingle.self, from: data).data?.attributes
    } catch {
        AppLog.networkError("Failed to decode primary currency", error)
        throw CurrenciesError.decodeError
    }
}
