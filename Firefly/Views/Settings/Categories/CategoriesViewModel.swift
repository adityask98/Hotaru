//
//  CategoriesViewModel.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2025/06/12.
//

import Foundation

enum CategoriesModelError: Error {
  case invalidURL
  case invalidResponse
  case invalidData
}

@MainActor
class CategoriesViewModel: ObservableObject {
  @Published var categories: Categories?
  @Published var isLoading: Bool = false

  func fetchCategories() {
    isLoading = true
    Task { @MainActor in
      do {
        categories = try await getCategories()
        isLoading = false
      } catch {
        print(error)
        isLoading = false
      }
    }
  }

  func getCategories() async throws -> Categories {
    var request = try RequestBuilder(apiURL: apiPaths.categories)
    request.url?.append(
      queryItems: [
        URLQueryItem(
          name: "start",
          value: formatDateToYYYYMMDD(currentMonthFirstDate())
        ),
        URLQueryItem(name: "end", value: formatDateToYYYYMMDD(currentMonthLastDate())),
      ]
    )

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
      throw CategoriesModelError.invalidResponse
    }

    do {
      let decoder = JSONDecoder()
      let result = try decoder.decode(Categories.self, from: data)

      return result
    } catch {
      print(error)
      throw CategoriesModelError.invalidData
    }
  }
}
