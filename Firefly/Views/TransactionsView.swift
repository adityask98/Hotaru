//
//  TransactionsView.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/06/15.
//

import SwiftUI

struct TransactionsView: View {
    @StateObject private var transactions = TransactionsViewModel()
    @State var addSheetShown = false

    //used for preview args
    init(transactions: TransactionsViewModel = TransactionsViewModel()) {
        _transactions = StateObject(wrappedValue: transactions)
    }

    var body: some View {
        NavigationStack {
            VStack {
                if transactions.isLoading {
                    Text("Loading")
                } else {
                    List {
                        ForEach(transactions.transactions?.data ?? [], id: \.id) {
                            transactionData in
                            if let transaction = transactionData.attributes?.transactions?.first {
                                TransactionsRow(transaction: transaction)
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparator(.hidden)
                            }
                        }
                        if transactions.hasMorePages {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .onAppear {
                                Task {
                                    await transactions.fetchTransactions(loadMore: true)
                                }
                            }
                        }
                    }

                    .listStyle(PlainListStyle())
                    .background(Color.clear)

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
            .navigationTitle("Transactions")
            .toolbar {
                Button(action: {
                    addSheetShown = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .padding(6)
                        .fontWeight(.heavy)
                }
            }

        }
        .sheet(
            isPresented: $addSheetShown,
            content: {
                Text("Add transaction")
            })
    }

}

struct TransactionsRow: View {
    var transaction: TransactionsTransaction
    var body: some View {
        VStack {
            HStack {
                Image(systemName: transactionTypeIcon(transaction.type ?? "unknown"))
                    .foregroundStyle(transactionTypeColor(transaction.type ?? "unknown"))
                    .frame(width: 60, height: 60)
                    .font(.system(size: 30))

                VStack(alignment: .leading) {
                    Text(transaction.description ?? "Unkown Description")
                        .font(.headline)
                    //                    Text(formatDate(transaction.date))
                    //                        .font(.largeTitle)
                    //                        //.foregroundStyle(.gray)
                    Text(formatAmount(transaction.amount, symbol: transaction.currencySymbol))
                        .font(.largeTitle)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Spacer()
                    if transaction.sourceName != nil {
                        Text(transaction.sourceName ?? "Source Error")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }

                    //                    Text(formatAmount(transaction.amount, symbol: transaction.currencySymbol))
                    //                        .font(.headline)
                    Text(formatDate(transaction.date))
                        .foregroundStyle(.gray)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)  // Add padding inside the HStack
        }
        .background(Color.white)  // Add a background color if needed
        .cornerRadius(16)  // Round the corners
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray, lineWidth: 1)  // Add a border
        )
        .padding(.horizontal)  // Add horizontal padding to the entire row
        .padding(.vertical, 8)
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

        let calendar = Calendar.current
        let now = Date()

        if calendar.isDate(date, equalTo: now, toGranularity: .day) {
            return "Today"
        }

        if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"  // Full name of the day
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
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

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsView(transactions: TransactionsViewModel.mock())
    }
}
