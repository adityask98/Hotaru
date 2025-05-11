//
//  AccountDetailViewModel.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/29.
//

import Foundation

@MainActor
final class AccountDetailViewModel: ObservableObject {
  @Published var account: AccountsDatum?
  @Published var isLoading: Bool = false
  @Published var transactionsIsLoading: Bool = false
  @Published var currentPage: Int = 1
  @Published var hasMorePages: Bool = true
  @Published var accountTransactions: Transactions?

  func fetchAccount(accountID: String) async {
    self.isLoading = true
    do {
      self.account = try await getAccount(id: accountID)
    } catch {
      print("error fetching account")
      print(error)
    }
    self.isLoading = false
  }

  func getAccount(id: String) async throws -> AccountsDatum {
    let url = apiPaths.accounts + "/\(id)"
    let request = try RequestBuilder(apiURL: url)
    let (data, response) = try await URLSession.shared.data(for: request)

    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
      throw AccountsModelError.invalidResponse
    }

    do {
      let decoder = JSONDecoder()
      let result = try decoder.decode(AccountsDatum.self, from: data)

      return result
    } catch {
      print(error)
      throw AccountsModelError.invalidData
    }
  }

}

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

func fetchAccountDetailNew(_ accountID: String) async throws -> AccountsDatum {
  let request = try RequestBuilder(apiURL: apiPaths.account(accountID))
  let (data, response) = try await URLSession.shared.data(for: request)

  guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
    throw UserModelError.invalidResponse
  }

  do {
    let decoder = JSONDecoder()
    let result = try decoder.decode(AccountsDatum.self, from: data)
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
