//
//  AccountDetail.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/12.
//

import SwiftUI

struct AccountDetail: View {

    var account: AccountsDatum
    var accountTransactions: Transactions = Transactions()
    var body: some View {

        ScrollView {
            VStack {
                Text("Current balance")
                Text(
                    formatAmount(
                        account.attributes?.currentBalance,
                        symbol: account.attributes?.currencySymbol)
                )
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 1)
            }
            .padding(.top, 40)
            .padding(.bottom)
            HStack {
                Text("Recent Transactions")
                    .fontWeight(.bold)
                    .font(.title2)
                Spacer()
            }.padding()
            AccountTransactionsView(accountID: account.id!)

        }.onAppear {
            if accountTransactions == nil {
                Task {
                    do {
                        let result = try await getTransactionsForAccount(account.id!)
                    }

                }
            }
        }

        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(account.attributes?.name ?? "Unknown").font(.headline)
                    Text("Asset Account")
                }
            }
        }
    }
}

struct AccountTransactionsView: View {
    var accountID: String
    @State private var transactions: Transactions? = nil
    @State private var isLoading = false

    var body: some View {
        NavigationStack {

            VStack {
                //Text("Transactions: \(transactions?.data?.count ?? 0)")
                if transactions?.data?.count != 0 {
                    ForEach(transactions?.data ?? [], id: \.id) { transactionData in
                        TransactionsRow(transaction: transactionData)
                    }

                }

            }
            .onAppear {
                if transactions == nil {
                    Task {
                        do {
                            isLoading = true
                            transactions = try await fetchAccountTransactions(accountID)
                            //print(transactions)
                            isLoading = false

                        }
                    }
                }
            }
        }

    }
    func fetchAccountTransactions(_ accountID: String) async throws -> Transactions {
        var request = try RequestBuilder(apiURL: apiPaths.accountTransactions(accountID))
        request.url?.append(queryItems: [
            URLQueryItem(name: "limit", value: "10")
        ])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw UserModelError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(Transactions.self, from: data)
            print(result)
            return result
        }
    }
}
//
////#Preview {
////    AccountDetail()
////}
