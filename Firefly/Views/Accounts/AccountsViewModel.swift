import Foundation
import SwiftUI

enum AccountsModelError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
}

@MainActor
class AccountsViewModel: ObservableObject {
    @Published var accounts: Accounts?
    @Published var isLoading = false
    @Published var currentPage = 1
    @Published var hasMorePages = true
    @AppStorage("amountHidden") var amountHidden = false

    func fetchAccounts(loadMore: Bool = false) async {
        if loadMore {
            currentPage += 1
        } else {
            currentPage = 1
        }
        if !loadMore {
            isLoading = true
        }

        do {
            var newAccounts: Accounts

            if loadMore {
                if (accounts?.links?.next) != nil {
                    newAccounts = try await getAccountsFromURL((accounts?.links?.next)!)
                    accounts?.data?.append(contentsOf: newAccounts.data ?? [])
                    accounts?.links = newAccounts.links
                    accounts?.meta = newAccounts.meta
                }
            } else {
                accounts = try await getAccounts(page: 1)
            }

            if accounts?.meta?.pagination?.currentPage
                == accounts?.meta?.pagination?.totalPages {
                hasMorePages = false
            }
        } catch {
            print("Error fetching accounts: \(error)")
        }

        if !loadMore {
            isLoading = false
        }
    }

    func getAccounts(
        limit: Int = 20,
        page: Int,
        type: String = "asset"
    ) async throws -> Accounts {
        var request = try RequestBuilder(apiURL: ApiPaths.accounts)
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

    func toggleAmountVisibility() {
        amountHidden.toggle()
    }
}

// extension AccountsViewModel {
//    static func mock() -> AccountsViewModel {
//        let viewModel = AccountsViewModel()
//
//        let mockAccounts = Accounts(data: [
//        createMockAccou
//        ], meta: <#T##AccountsMeta?#>, links: <#T##AccountsLinks?#>)
//    }
// }
