import Foundation

enum AutocompleteError: Error {
    case decodeError
    case categories
    case accounts
    case budgets
    case common
}

func fetchAutocomplete<T: Codable>(for path: String) async throws -> T {
    let request = try RequestBuilder(apiURL: path)

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw AutocompleteError.common
    }

    let decoder = JSONDecoder()
    return try decoder.decode(T.self, from: data)
}
