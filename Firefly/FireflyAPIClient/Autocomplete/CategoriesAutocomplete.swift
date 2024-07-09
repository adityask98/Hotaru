//
//  Autocomplete.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/05.
//

import Foundation

enum AutocompleteError: Error {
    case decodeError
    case categories
    case accounts
}

// MARK: - AutoCategoryElement
struct AutoCategoryElement: Codable {
    let id, name: String?
}

typealias AutoCategory = [AutoCategoryElement]

func fetchCategoriesAutocomplete() async throws -> AutoCategory {
    let request = try RequestBuilder(apiURL: autocompleteApiPaths.categories)

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw AutocompleteError.categories
    }
    do {
        let decoder = JSONDecoder()
        let result = try decoder.decode(AutoCategory.self, from: data)
        return result
    } catch {
        print(error)
        throw AutocompleteError.decodeError
    }
}
