//
//  AccountsAPIClient.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2023/10/17.
//

import Foundation

enum AccountsModelError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
}

@MainActor
class AccountsViewModel: ObservableObject {
    @Published var accounts: Accounts?
    @Published var isLoading: Bool = false
    @Published var currentPage: Int = 1
    @Published var hasMorePages: Bool = true

    func fetchAccounts(loadMore: Bool = false) async {
        if loadMore {
            self.currentPage += 1
        } else {
            self.currentPage = 1
        }
        if !loadMore {
            self.isLoading = true
        }

        do {
            var newAccounts: Accounts

            if loadMore {
                if (self.accounts?.links?.next) != nil {
                    newAccounts = try await getAccountsFromURL((self.accounts?.links?.next)!)
                    self.accounts?.data?.append(contentsOf: newAccounts.data ?? [])
                    self.accounts?.links = newAccounts.links
                    self.accounts?.meta = newAccounts.meta
                }
            } else {
                self.accounts = try await getAccounts(page: 1)
            }

            if self.accounts?.meta?.pagination?.currentPage
                == self.accounts?.meta?.pagination?.totalPages
            {
                self.hasMorePages = false
            }
        } catch {
            print("Error fetching accounts: \(error)")
        }

        if !loadMore {
            self.isLoading = false
        }
    }

    func getAccounts(
        limit: Int = 20,
        page: Int,
        type: String = "asset"
    ) async throws -> Accounts {
        var request = try RequestBuilder(apiURL: apiPaths.accounts)
        request.url?.append(queryItems: [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "type", value: type),
        ])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw AccountsModelError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(Accounts.self, from: data)

            return result
        } catch {
            print(error)
            throw AccountsModelError.invalidData
        }
    }

    func getAccountsFromURL(_ urlString: String) async throws -> Accounts {
        let request = try RequestBuilder(apiURL: urlString, ignoreBaseURL: true)

        return try await performRequest(request)
    }

    private func performRequest(_ request: URLRequest) async throws -> Accounts {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw AccountsModelError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(Accounts.self, from: data)
            return result
        } catch {
            print(error)
            throw AccountsModelError.invalidData
        }
    }
}

class AccountDetailViewModel: ObservableObject {
    @Published var account: AccountsDatum?
    @Published var isLoading: Bool = false
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
//extension AccountsViewModel {
//    static func mock() -> AccountsViewModel {
//        let viewModel = AccountsViewModel()
//
//        let mockAccounts = Accounts(data: [
//        createMockAccou
//        ], meta: <#T##AccountsMeta?#>, links: <#T##AccountsLinks?#>)
//    }
//}
