//
//  CurrenciesAutocomplete.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/08/09.
//

import Foundation

struct AutoCurrencyElement: Codable {
  let id, name, code, symbol: String?
  let decimalPlaces: Int?

  enum CodingKeys: String, CodingKey {
    case id, name, code, symbol
    case decimalPlaces = "decimal_places"
  }
}

typealias AutoCurrency = [AutoCurrencyElement]

func fetchCurrencyAutocomplete() async throws -> AutoCurrency {
  try await fetchAutocomplete(for: autocompleteApiPaths.currencies)
}
