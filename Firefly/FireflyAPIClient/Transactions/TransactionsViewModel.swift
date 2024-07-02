//
//  TransactionModel.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/06/14.
//

import Foundation

final class TransactionsViewModel: ObservableObject {
    @Published var transactions: Transactions?
    @Published var isLoading: Bool = false
    private let user: UserModel

    init() {
        self.user = UserModel()
        Task {
            await fetchTransactions()
        }
    }

    func fetchTransactions() async {
        isLoading = true
        do {
            try await user.getUser()
            if let userId = user.user?.data?.id {
                try await getTransactions(userId)
            } else {
                print("User ID is missing")
            }
        } catch {
            print("Error fetching transactions: \(error)")
        }
        isLoading = false
    }

    func getTransactions(
        _ id: String, limit: Int = 50, type: String = "expense",
        end: String = formatDateToYYYYMMDD()
    ) async throws {
        var request = try RequestBuilder(apiURL: apiPaths.accountTransactions())
        print(id)
        request.url?.append(queryItems: [
            URLQueryItem(name: "type", value: type),
            URLQueryItem(name: "limit", value: String(limit)),
            //            URLQueryItem(name: "start", value: "2024-07-01"),
            //URLQueryItem(name: "end", value: end),
        ])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw UserModelError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            print("DECODING")
            let result = try decoder.decode(Transactions.self, from: data)
            print(result)

            self.transactions = result
        } catch {
            print(error)
            throw UserModelError.invalidData
        }
    }
}
