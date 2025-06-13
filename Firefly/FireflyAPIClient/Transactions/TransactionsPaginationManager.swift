//
//  TransactionsPaginationManager.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2025/06/08.
//

import Foundation

protocol TransactionsPaginationProtocol: ObservableObject {
  var transactions: Transactions? { get set }
  var isLoading: Bool { get set }
  var currentPage: Int { get set }
  var hasMorePages: Bool { get set }

  func fetchTransactions(loadMore: Bool) async
  func resetPagination()
}

protocol TransactionsAPIProvider {
  func getTransactions(page: Int) async throws -> Transactions
  func getTransactionsFromURL(_ urlString: String) async throws -> Transactions
}

@MainActor
class TransactionsPaginationManager: ObservableObject {
  @Published var transactions: Transactions?
  @Published var isLoading: Bool = false
  @Published var currentPage: Int = 1
  @Published var hasMorePages: Bool = true

  private let apiProvider: TransactionsAPIProvider

  init(apiProvider: TransactionsAPIProvider) {
    self.apiProvider = apiProvider
  }

  func fetchTransactions(loadMore: Bool = false) async {
    if loadMore {
      currentPage += 1
    } else {
      currentPage = 1
    }

    if !loadMore {
      self.isLoading = true
    }

    do {
      let newTransactions: Transactions

      if loadMore {
        if let nextURL = self.transactions?.links?.next {
          newTransactions = try await apiProvider.getTransactionsFromURL(nextURL)
          self.transactions?.data?.append(contentsOf: newTransactions.data ?? [])
          self.transactions?.links = newTransactions.links
          self.transactions?.meta = newTransactions.meta
        } else {
          // No more pages available
          self.hasMorePages = false
          if !loadMore {
            self.isLoading = false
          }
          return
        }
      } else {
        self.transactions = try await apiProvider.getTransactions(page: 1)
        self.hasMorePages = true
      }

      if self.transactions?.meta?.pagination?.currentPage
        == self.transactions?.meta?.pagination?.totalPages
      {
        self.hasMorePages = false
      }
    } catch {
      print("Error fetching transactions: \(error)")
    }

    if !loadMore {
      self.isLoading = false
    }
  }

  func resetPagination() {
    currentPage = 1
    hasMorePages = true
    transactions = nil
  }
}

// Default implementation for common functionality
extension TransactionsAPIProvider {
  func performRequest(_ request: URLRequest) async throws -> Transactions {
    let (data, response) = try await URLSession.shared.data(for: request)

    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
      throw TransactionsModelError.invalidResponse
    }
    print(response)
    do {
      let decoder = JSONDecoder()
      let result = try decoder.decode(Transactions.self, from: data)
      return result
    } catch {
      print(error)
      throw TransactionsModelError.invalidData
    }
  }

  func getTransactionsFromURL(_ urlString: String) async throws -> Transactions {
    let request = try RequestBuilder(apiURL: urlString, ignoreBaseURL: true)
    return try await performRequest(request)
  }
}
