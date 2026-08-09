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
    @Published var isLoading = false
    @Published var currentPage = 1
    @Published var hasMorePages = true
    @Published var errorMessage: String?

    private var apiProvider: TransactionsAPIProvider

    init(apiProvider: TransactionsAPIProvider) {
        self.apiProvider = apiProvider
    }

    /// Swaps the provider (e.g. when the main list's filter changes).
    /// The next non-loadMore fetch starts from page 1 with the new provider.
    func updateProvider(_ provider: TransactionsAPIProvider) {
        apiProvider = provider
    }

    func fetchTransactions(loadMore: Bool = false) async {
        errorMessage = nil

        if loadMore {
            guard AppSettings.paginationEnabled else {
                hasMorePages = false
                return
            }
            guard !isLoading else { return }
            guard let nextURL = transactions?.links?.next else {
                hasMorePages = false
                return
            }
            isLoading = true
            currentPage += 1
            do {
                let newTransactions = try await apiProvider.getTransactionsFromURL(nextURL)
                transactions?.data?.append(contentsOf: newTransactions.data ?? [])
                transactions?.links = newTransactions.links
                transactions?.meta = newTransactions.meta
            } catch {
                currentPage -= 1
                errorMessage = "Couldn't load more transactions."
                AppLog.networkError("Failed to fetch transactions", error)
            }
            isLoading = false
        } else {
            currentPage = 1
            isLoading = true
            do {
                transactions = try await apiProvider.getTransactions(page: 1)
                hasMorePages = true
            } catch {
                errorMessage = "Couldn't load transactions."
                AppLog.networkError("Failed to fetch transactions", error)
            }
            isLoading = false
        }

        if !AppSettings.paginationEnabled
            || transactions?.meta?.pagination?.currentPage
            == transactions?.meta?.pagination?.totalPages {
            hasMorePages = false
        }
    }

    func resetPagination() {
        currentPage = 1
        hasMorePages = true
        transactions = nil
        errorMessage = nil
    }
}

/// Default implementation for common functionality
extension TransactionsAPIProvider {
    func performRequest(_ request: URLRequest) async throws -> Transactions {
        let (data, response) = try await AppNetworking.session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode
            // If the final URL differs from the requested one, the request was
            // redirected — URLSession drops the Authorization header on cross-host/
            // cross-scheme redirects, which surfaces as a 401 even with a valid token.
            if let requestURL = request.url, requestURL != response.url {
                AppLog.network.error(
                    """
                    Redirected during fetch: \(requestURL.absoluteString, privacy: .private) -> \
                    \(response.url?.absoluteString ?? "nil", privacy: .private) (status \(statusCode ?? -1))
                    """
                )
            }
            throw TransactionsModelError.invalidResponse(statusCode: statusCode)
        }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(Transactions.self, from: data)
        } catch {
            AppLog.networkError("Failed to decode transactions", error)
            throw TransactionsModelError.invalidData
        }
    }

    func getTransactionsFromURL(_ urlString: String) async throws -> Transactions {
        let request = try RequestBuilder(apiURL: urlString, ignoreBaseURL: true)
        return try await performRequest(request)
    }
}
