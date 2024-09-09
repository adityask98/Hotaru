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
    @Published var errorMessage: String = ""

    func fetchTransaction(transactionID: String) async {
        self.isLoading = true
        do {
            self.transaction = try await getTransaction(transactionID: transactionID)
        } catch {
            print(error)
        }
    }

    func refreshTransaction(transactionID: String) async {
        self.isLoading = true
        await fetchTransaction(transactionID: transactionID)
        self.isLoading = false
    }

    func deleteTransaction(transactionID: String) async throws {
        let request = try RequestBuilder(
            apiURL: apiPaths.transaction("test"), httpMethod: "DELETE")
        let (data, response) = try await URLSession.shared.data(for: request)
        printResponse(data)

        guard let response = response as? HTTPURLResponse, response.statusCode == 204 else {
            let commonError = try ErrorDecoder(data)
            errorMessage = commonError.message ?? "No message"
            print(errorMessage)
            throw TransactionsModelError.invalidResponse
        }
        print(response)
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
