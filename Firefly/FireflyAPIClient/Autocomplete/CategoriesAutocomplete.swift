import Foundation

// MARK: - AutoCategoryElement

struct AutoCategoryElement: Codable {
    let id, name: String?
}

typealias AutoCategory = [AutoCategoryElement]

func fetchCategoriesAutocomplete() async throws -> AutoCategory {
    try await fetchAutocomplete(for: AutocompleteApiPaths.categories)
}

func createCategoriesAutocompleteArray() async throws -> [String] {
    let categories = try await fetchCategoriesAutocomplete()
    var result = ["Default"]
    result = categories.compactMap { $0.name }
    if !result.contains("Uncategorized") {
        result.insert("Uncategorized", at: 0)
    }
    return result
}
