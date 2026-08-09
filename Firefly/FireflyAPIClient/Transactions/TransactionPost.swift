import Foundation

enum TransactionPostError: Error {
    case invalidResponse
}

/// Creates a transaction.
///
/// `latitude`/`longitude` are sent on a best-effort basis: the 6.6.6 spec doesn't define them on
/// `TransactionSplitStore`, so the server is expected to ignore them, but any server that does honour
/// them gets a real location instead of only the notes marker. If transaction creation ever starts
/// failing with a 422, these two are the first thing to drop.
func postTransaction(
    description: String, amount: String, date: Date, category: String, type: String,
    sourceAccount: (id: String, name: String), destinationAccount: (id: String, name: String),
    notes: String, budgetID: String? = nil, latitude: String? = nil, longitude: String? = nil
) async throws {
    let transaction = PostTransaction(
        errorIfDuplicateHash: true, applyRules: true, fireWebhooks: true,
        transactions: [
            PostTransactionElement(
                type: convertTransactionType(type: type),
                date: CachedFormatters.iso8601.string(from: date),
                amount: amount,
                description: description,
                budgetID: budgetID,
                categoryName: category,
                sourceID: sourceAccount.id,
                sourceName: sourceAccount.name,
                destinationID: destinationAccount.id,
                destinationName: destinationAccount.name,
                notes: notes,
                latitude: latitude,
                longitude: longitude
            ),
        ]
    )

    var request = try RequestBuilder(apiURL: PostApiPaths.addTransactions, httpMethod: "POST")

    let encoder = JSONEncoder()
    let data = try encoder.encode(transaction)
    request.httpBody = data
    let (_, response) = try await AppNetworking.session.data(for: request)
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw TransactionPostError.invalidResponse
    }
}

func editTransaction(transactionData: PostTransaction, transactionID: String) async throws {
    var request = try RequestBuilder(
        apiURL: PutApiPaths.editTransaction(transactionID), httpMethod: "PUT"
    )
    let encoder = JSONEncoder()
    let data = try encoder.encode(transactionData)
    request.httpBody = data
    let (_, response) = try await AppNetworking.session.data(for: request)
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
        throw TransactionPostError.invalidResponse
    }
}

func deleteTransaction(transactionID: String) async throws {
    let request = try RequestBuilder(
        apiURL: ApiPaths.transaction(transactionID), httpMethod: "DELETE"
    )
    let (_, response) = try await AppNetworking.session.data(for: request)
    guard let response = response as? HTTPURLResponse, response.statusCode == 204 else {
        throw TransactionPostError.invalidResponse
    }
}

func convertTransactionType(type: String) -> String {
    switch type {
    case "Expenses":
        return "withdrawal"

    case "Income":
        return "deposit"

    case "Transfer":
        return "transfer"

    default:
        return "withdrawal"
    }
}
