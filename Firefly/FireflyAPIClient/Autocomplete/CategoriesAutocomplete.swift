//
//  Autocomplete.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/05.
//

import Foundation

// MARK: - AutoCategoryElement
struct AutoCategoryElement: Codable {
    let id, name: String?
}

typealias AutoCategory = [AutoCategoryElement]

func fetchCategoriesAutocomplete() async throws -> AutoCategory {
    try await fetchAutocomplete(for: autocompleteApiPaths.categories)
}
