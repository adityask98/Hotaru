import Foundation

enum TransactionPostError: Error {
    case invalidResponse
}

func postTransaction(
    description: String, amount: String, date: Date, category: String, type: String,
    sourceAccount: (id: String, name: String), destinationAccount: (id: String, name: String),
    notes: String
) async throws {
    let transaction = PostTransaction(
        errorIfDuplicateHash: true, applyRules: true, fireWebhooks: true,
        transactions: [
            PostTransactionElement(
                type: convertTransactionType(type: type),
                date: ISO8601DateFormatter().string(from: date),
                amount: amount,
                description: description,
                categoryName: category,
                sourceID: sourceAccount.id,
                sourceName: sourceAccount.name,
                destinationID: destinationAccount.id,
                destinationName: destinationAccount.name,
                notes: notes
            ),
        ]
    )

    var request = try RequestBuilder(apiURL: PostApiPaths.addTransactions, httpMethod: "POST")

    let encoder = JSONEncoder()
    let data = try encoder.encode(transaction)
    request.httpBody = data
    let (responseData, response) = try await URLSession.shared.data(for: request)
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
    let (responseData, response) = try await URLSession.shared.data(for: request)
    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
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
