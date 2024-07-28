//
//  TransactionDetailViewModel.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/28.
//

import Foundation

@MainActor
final class TransactionDetailViewModel: ObservableObject {
    @Published var transaction: TransactionsDatum?
    @Published var isLoading: Bool = false

    func fetchTransaction(_ transactionID: String) async {
        self.isLoading = true
        do {
            self.transaction = try await getTransaction(transactionID: transactionID)
        } catch {
            print(error)
        }
    }

    func getTransaction(transactionID: String) async throws -> TransactionsDatum {
        var request = try RequestBuilder(apiURL: apiPaths.transaction(transactionID))
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw TransactionsModelError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(TransactionsDatum.self, from: data)
            return result
        } catch {
            print(error)
            throw TransactionsModelError.invalidData
        }
    }
}
