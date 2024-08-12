//
//  TransactionsAutocomplete.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/08/12.
//

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
    try await fetchAutocomplete(for: autocompleteApiPaths.transactions)
}
