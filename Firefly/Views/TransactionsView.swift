//
//  TransactionsView.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/06/15.
//

import SwiftUI

struct TransactionsView: View {
    @StateObject private var transactions = TransactionsViewModel()

    var body: some View {
        VStack {
            if transactions.isLoading {
                Text("Loading")
            } else {
                List {
                    ForEach(transactions.transactions?.data ?? [], id: \.id) { transactionData in
                        if let transaction = transactionData.attributes?.transactions?.first {
                            TransactionsRow(transaction: transaction)
                        }
                    }
                }
            }

        }
        .onAppear {
            if transactions.transactions == nil {
                Task {
                    await transactions.fetchTransactions()
                }
            }
        }
        .refreshable {
            await transactions.fetchTransactions()
        }
    }
    
}

struct TransactionsRow: View {
    var transaction: TransactionsTransaction
    var body: some View {
        VStack {
            HStack {
                Image(systemName: transactionTypeIcon(transaction.type ?? "unknown"))
                    .foregroundStyle(transactionTypeColor(transaction.type ?? "unknown"))
                Spacer()
                VStack(alignment: .leading) {
                    Text(transaction.description ?? "Unkown Description")
                        .font(.headline)
                    Text(formatDate(transaction.date))
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                Spacer()
                VStack {
                    Text(formatAmount(transaction.amount, symbol: transaction.currencySymbol))
                        .font(.headline)
                    if transaction.sourceName != nil {
                        Text(transaction.sourceName ?? "Source Error")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                }
            }
            .padding()  // Add padding inside the HStack
        }
        .background(Color.white)  // Add a background color if needed
        .cornerRadius(16)  // Round the corners
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray, lineWidth: 1)  // Add a border
        )
        .padding(.horizontal)  // Add horizontal padding to the entire row
    }

    private func transactionTypeIcon(_ type: String) -> String {
        switch type {
        case "withdrawal":
            return "arrowshape.down.circle.fill"
        case "transfer":
            return "arrow.left.arrow.right.circle.fill"
        case "deposit":
            return "arrowshape.up.circle.fill"
        default:
            return "circle.badge.questionmark.fill"
        }
    }

    private func transactionTypeColor(_ type: String) -> Color {
        switch type {
        case "withdrawal":
            return .red
        case "deposit":
            return .green
        case "transfer":
            return .blue
        default:
            return .gray
        }
    }

    private func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString,
            let date = ISO8601DateFormatter().date(from: dateString)
        else {
            return "Unknown Date"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatAmount(_ amountString: String?, symbol: String?) -> String {
        guard let amountString = amountString,
            let amount = Double(amountString)
        else {
            return "Unknown Amount"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = symbol ?? "¥"
        return formatter.string(from: NSNumber(value: amount)) ?? "Unknown Amount"
    }
}

//#Preview {
//    TransactionsView()
//}
