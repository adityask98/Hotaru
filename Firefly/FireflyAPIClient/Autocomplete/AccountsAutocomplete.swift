//
//  AccountsAutocomplete.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/09.
//

import Foundation

// MARK: - AutoAccount
struct AutoAccount: Codable {
    let id, name, nameWithBalance, type: String?
    let currencyID, currencyName, currencyCode, currencySymbol: String?
    let currencyDecimalPlaces: Int?

    enum CodingKeys: String, CodingKey {
        case id, name
        case nameWithBalance = "name_with_balance"
        case type
        case currencyID = "currency_id"
        case currencyName = "currency_name"
        case currencyCode = "currency_code"
        case currencySymbol = "currency_symbol"
        case currencyDecimalPlaces = "currency_decimal_places"
    }
}

typealias AutoAccounts = [AutoAccount]

func fetchAccountsAutocomplete() async throws -> AutoAccounts {
    let request = try RequestBuilder(apiURL: autocompleteApiPaths.accounts)

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw AutocompleteError.categories
    }
    do {
        let decoder = JSONDecoder()
        let result = try decoder.decode(AutoAccounts.self, from: data)
        return result
    } catch {
        print(error)
        throw AutocompleteError.decodeError
    }
}
