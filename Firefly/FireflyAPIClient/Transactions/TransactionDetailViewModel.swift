//
//  TransactionDetailViewModel.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/28.
//

import Foundation

struct TransactionDetailDatum: Codable {
    var data: TransactionsDatum?
}

@MainActor
final class TransactionDetailViewModel: ObservableObject {
    @Published var transaction: TransactionDetailDatum?
    @Published var isLoading: Bool = false

    func fetchTransaction(transactionID: String) async {
        self.isLoading = true
        do {
            print(transactionID)
            self.transaction = try await getTransaction(transactionID: transactionID)
            //print (self.transaction)
        } catch {
            print(error)
        }
    }

    func getTransaction(transactionID: String) async throws -> TransactionDetailDatum {
        let request = try RequestBuilder(apiURL: apiPaths.transaction(transactionID))
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw TransactionsModelError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(TransactionDetailDatum.self, from: data)
//            if let str = String(data: data, encoding: .utf8) {
//                print("Successfully decoded: \(str)")
//            }
            //print(result)
            return result
        } catch {
            print(error)
            throw TransactionsModelError.invalidData
        }
    }
}
