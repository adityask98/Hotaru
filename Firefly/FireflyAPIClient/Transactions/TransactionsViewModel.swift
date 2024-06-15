//
//  TransactionModel.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/06/14.
//

import Foundation

final class TransactionsViewModel: ObservableObject {
    @Published var transactions: Transactions?
    private let user: UserModel

    init() {
        self.user = UserModel()
        Task {
            await fetchTransactions()
        }
    }

    func fetchTransactions() async {
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
    }

    func getTransactions(_ id: String) async throws {
        let request = try RequestBuilder(apiURL: apiPaths.accountTransactions(id: id))
        print(id)

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


//typeMismatch(Swift.Double, Swift.DecodingError.Context(codingPath: [CodingKeys(stringValue: "data", intValue: nil), _JSONKey(stringValue: "Index 0", intValue: 0), CodingKeys(stringValue: "attributes", intValue: nil), CodingKeys(stringValue: "created_at", intValue: nil)], debugDescription: "Expected to decode Double but found a string instead.", underlyingError: nil))
//typeMismatch(Swift.Double, Swift.DecodingError.Context(codingPath: [CodingKeys(stringValue: "data", intValue: nil), _JSONKey(stringValue: "Index 0", intValue: 0), CodingKeys(stringValue: "attributes", intValue: nil), CodingKeys(stringValue: "created_at", intValue: nil)], debugDescription: "Expected to decode Double but found a string instead.", underlyingError: nil))
