import Foundation

@MainActor
final class AccountDetailViewModel: ObservableObject {
    @Published var account: AccountsDatum?
    @Published var isLoading = false
    @Published var transactions: Transactions?
    @Published var transactionsIsLoading = false
    @Published var hasMorePages = true
    @Published var transactionsErrorMessage: String?

    private let paginationManager: TransactionsPaginationManager

    let accountID: String

    init(accountID: String) {
        self.accountID = accountID
        paginationManager = TransactionsPaginationManager(
            apiProvider: AccountTransactionsAPIProvider(accountId: accountID)
        )

        paginationManager.$transactions.assign(to: &$transactions)
        paginationManager.$isLoading.assign(to: &$transactionsIsLoading)
        paginationManager.$hasMorePages.assign(to: &$hasMorePages)
        paginationManager.$errorMessage.assign(to: &$transactionsErrorMessage)
    }

    func fetchTransactions(loadMore: Bool = false) async {
        await paginationManager.fetchTransactions(loadMore: loadMore)
    }

    func fetchAccount(accountID: String) async {
        isLoading = true
        do {
            account = try await getAccount(id: accountID)
        } catch {
            AppLog.networkError("Failed to fetch account", error)
        }
        isLoading = false
    }

    func getAccount(id: String) async throws -> AccountsDatum {
        let url = ApiPaths.accounts + "/\(id)"
        let request = try RequestBuilder(apiURL: url)
        let (data, response) = try await AppNetworking.session.data(for: request)

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw AccountsModelError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(AccountsDatum.self, from: data)
        } catch {
            AppLog.networkError("Failed to decode account", error)
            throw AccountsModelError.invalidData
        }
    }

    //  func fetchTransactions(loadMore: Bool = false) async {
    //
    //  }
}

func fetchAccountDetail(_ accountID: String) async throws -> Accounts {
    let request = try RequestBuilder(apiURL: ApiPaths.account(accountID))
    let (data, response) = try await AppNetworking.session.data(for: request)

    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw UserModelError.invalidResponse
    }
    // print(String(data))

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(Accounts.self, from: data)
    }
}

func fetchAccountDetailNew(_ accountID: String) async throws -> AccountsDatum {
    let request = try RequestBuilder(apiURL: ApiPaths.account(accountID))
    let (data, response) = try await AppNetworking.session.data(for: request)

    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw UserModelError.invalidResponse
    }

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(AccountsDatum.self, from: data)
    }
}
