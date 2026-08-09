import Foundation

enum CategoriesModelError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
}

@MainActor
class CategoriesViewModel: ObservableObject {
    @Published var categories: Categories?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchCategories() async {
        isLoading = true
        errorMessage = nil
        do {
            categories = try await getCategories()
        } catch {
            errorMessage = "Couldn't load categories."
            AppLog.networkError("Failed to fetch categories", error)
        }
        isLoading = false
    }

    func getCategories() async throws -> Categories {
        var request = try RequestBuilder(apiURL: ApiPaths.categories)
        request.url?.append(
            queryItems: [
                URLQueryItem(
                    name: "start",
                    value: formatDateToYYYYMMDD(currentMonthFirstDate())
                ),
                URLQueryItem(name: "end", value: formatDateToYYYYMMDD(currentMonthLastDate())),
            ]
        )

        let (data, response) = try await AppNetworking.session.data(for: request)

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw CategoriesModelError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(Categories.self, from: data)
        } catch {
            AppLog.networkError("Failed to decode categories", error)
            throw CategoriesModelError.invalidData
        }
    }
}
