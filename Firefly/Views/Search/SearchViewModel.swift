//
//  SearchViewModel.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2025/05/11.
//

import Foundation

class SearchViewModel: ObservableObject {
  @Published var searchText: String = ""
  @Published var searchDebouncedText: String = ""
  @Published var searchResults: Transactions?
  @Published var isLoading: Bool = false
  @Published var errorMessage: String?

  init() {
    setupSearchTextDebounce()
  }

  func setupSearchTextDebounce() {
    searchDebouncedText = self.searchText
    $searchText
      .debounce(for: .seconds(0.75), scheduler: RunLoop.main)
      .assign(to: &$searchDebouncedText)

  }

  func search() {
    errorMessage = nil

    if searchDebouncedText.isEmpty {
      searchResults = nil
      return
    }

    isLoading = true

    Task {
      do {
        try await performSearch()
      } catch {
        await MainActor.run {
          self.errorMessage = "Search failed: \(error.localizedDescription)"
          self.isLoading = false
        }
      }
    }
  }

  @MainActor
  func performSearch() async throws {
    var request = try RequestBuilder(apiURL: apiPaths.searchTransactions)
    request.url?.append(queryItems: [
      URLQueryItem(name: "query", value: String(searchDebouncedText))
    ])

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
      throw TransactionsModelError.invalidResponse
    }

    do {
      let decoder = JSONDecoder()
      let result = try decoder.decode(Transactions.self, from: data)

      self.searchResults = result
      self.isLoading = false
      #if DEBUG
        print("Search Results: \(String(describing: self.searchResults))")
      #endif
    }

  }
}
