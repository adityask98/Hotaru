import Foundation

struct AutoTransactionElement: Codable {
    let id, name, transactionGroupId, description: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case transactionGroupId = "transaction_group_id"
    }
}

typealias AutoTransactions = [AutoTransactionElement]

func fetchTransactionAutocomplete() async throws -> AutoTransactions {
    try await fetchAutocomplete(for: AutocompleteApiPaths.transactions)
}
