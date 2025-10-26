import Foundation

// Account-specific transactions API provider
class AccountTransactionsAPIProvider: TransactionsAPIProvider {
    private let accountId: String
    private let startDate: String?
    private let endDate: String?
    private let limit: Int

    init(
        accountId: String,
        startDate: String? = nil,
        endDate: String? = nil,
        limit: Int = 10
    ) {
        self.accountId = accountId
        self.startDate = startDate
        self.endDate = endDate
        self.limit = limit
    }

    func getTransactions(page: Int) async throws -> Transactions {
        var request = try RequestBuilder(apiURL: "\(ApiPaths.accounts)/\(accountId)/transactions")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "page", value: String(page)),
        ]

        if let startDate = startDate {
            queryItems.append(URLQueryItem(name: "start", value: startDate))
        }

        if let endDate = endDate {
            queryItems.append(URLQueryItem(name: "end", value: endDate))
        }

        request.url?.append(queryItems: queryItems)

        return try await performRequest(request)
    }
}

// Category-specific transactions API provider
class CategoryTransactionsAPIProvider: TransactionsAPIProvider {
    private let categoryId: String
    private let startDate: String?
    private let endDate: String?
    private let limit: Int
    private let type: TransactionTypes?

    init(
        categoryId: String,
        startDate: String? = nil,
        endDate: String? = nil,
        limit: Int = 10,
        type: TransactionTypes? = nil
    ) {
        self.categoryId = categoryId
        self.startDate = startDate
        self.endDate = endDate
        self.limit = limit
        self.type = type
    }

    func getTransactions(page: Int) async throws -> Transactions {
        var request = try RequestBuilder(apiURL: "\(ApiPaths.categories)/\(categoryId)/transactions")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "page", value: String(page)),
        ]
        if let startDate = startDate {
            queryItems.append(URLQueryItem(name: "start", value: startDate))
        }

        if let endDate = endDate {
            queryItems.append(URLQueryItem(name: "end", value: endDate))
        }

        if let type = type {
            queryItems.append(URLQueryItem(name: "type", value: type.rawValue))
        }
        request.url?.append(queryItems: queryItems)

        return try await performRequest(request)
    }
}
