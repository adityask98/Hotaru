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

  let accountID: String

  init(accountID: String) {
    self.accountID = accountID
  }

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

  func fetchTransactions(loadMore: Bool = false) async {

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

//Get initial transactions
func getTransactionsForAccount(_ id: String, limit: Int = 10, type: String = "all", page: Int = 1)
  async throws -> Transactions
{
  let url = apiPaths.accountTransactions(id)
  var request = try RequestBuilder(apiURL: url)
  request.url?.append(queryItems: [
    URLQueryItem(name: "limit", value: String(limit)),
    URLQueryItem(name: "type", value: String(type)),
    URLQueryItem(name: "page", value: String(page)),

  ])

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

  func getTransactionsFromURL(_ urlString: String) async throws -> Transactions {
    let request = try RequestBuilder(apiURL: urlString, ignoreBaseURL: true)

    return try await performRequest(request)
  }

  func performRequest(_ request: URLRequest) async throws -> Transactions {
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
}
