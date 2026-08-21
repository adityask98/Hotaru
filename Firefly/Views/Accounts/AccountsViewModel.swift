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
    @Published var errorMessage: String?
    @AppStorage("amountHidden") var amountHidden = false
    private var fetchTask: Task<Void, Never>?

    func fetchAccounts(loadMore: Bool = false) async {
        // Pull-to-refresh can invoke this concurrently with the initial onAppear
        // load (or fire more than once for a single gesture); cancel any prior
        // in-flight fetch so only the latest one lands.
        fetchTask?.cancel()
        let task = Task { [weak self] in
            guard let self else { return }
            await self.performFetch(loadMore: loadMore)
        }
        fetchTask = task
        await task.value
    }

    private func performFetch(loadMore: Bool) async {
        errorMessage = nil
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
            if Task.isCancelled { return }
            errorMessage = "Couldn't load accounts."
            AppLog.networkError("Failed to fetch accounts", error)
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
        try await fetchAccountsPage(limit: limit, page: page, type: type)
    }

    func getAccountsFromURL(_ urlString: String) async throws -> Accounts {
        let request = try RequestBuilder(apiURL: urlString, ignoreBaseURL: true)

        return try await performRequest(request)
    }

    private func performRequest(_ request: URLRequest) async throws -> Accounts {
        let (data, response) = try await AppNetworking.session.data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw AccountsModelError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(Accounts.self, from: data)
        } catch {
            AppLog.networkError("Failed to decode accounts", error)
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
