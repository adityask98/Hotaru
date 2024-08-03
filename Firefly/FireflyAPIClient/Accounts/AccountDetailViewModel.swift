//
//  AccountDetailViewModel.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/29.
//

import Foundation

func fetchAccountDetail(_ accountID: String) async throws -> Accounts {
    let request = try RequestBuilder(apiURL: apiPaths.account(accountID))
    let (data, response) = try await URLSession.shared.data(for: request)

    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw UserModelError.invalidResponse
    }
    //print(String(data))

    do {
        let decoder = JSONDecoder()
        let result = try decoder.decode(Accounts.self, from: data)
        print(result)
        return result
    }
}

func getTransactionsForAccount(_ id: String) async throws -> Transactions {
    let url = apiPaths.accountTransactions(id)
    let request = try RequestBuilder(apiURL: url)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw TransactionsModelError.invalidResponse
    }

    do {
        let decoder = JSONDecoder()
        let result = try decoder.decode(Transactions.self, from: data)

        return result
    } catch {
        print(error)
        throw TransactionsModelError.invalidData
    }
}
