//
//  TransactionsView.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/06/15.
//

import SwiftUI

struct TransactionsView: View {
    @State private var transactions = TransactionsViewModel()
    var body: some View {
        VStack {
            Text(transactions.transactions?.data?[0].type ?? "Loading")
        }
        .task {
            await transactions.fetchTransactions()
        }
    }
}

#Preview {
    TransactionsView()
}
