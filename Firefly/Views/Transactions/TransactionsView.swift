//
//  TransactionsView.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/06/15.
//

import SwiftUI

enum TransactionsFilterType: String {
    case all = "All"
    case withdrawal = "Withdrawal"
    case deposit = "Deposit"
    case expense = "Expense"
    case transfer = "Transfer"
}

@MainActor
struct TransactionsView: View {
    @StateObject private var transactions = TransactionsViewModel()
    @State private var filterType: TransactionsFilterType = .all
    @State var addSheetShown = false
    @State private var filterExpanded = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                filterSection
                    .padding()

                if transactions.isLoading {
                    Spacer()
                    HStack(alignment: .center) {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(transactions.transactions?.data ?? [], id: \.id) {
                            transactionData in
                            if let transaction = transactionData.attributes?.transactions?.first {
                                ZStack {
                                    NavigationLink(
                                        destination: TransactionDetail(transaction: transaction)
                                    ) { EmptyView() }
                                    .opacity(0.0).buttonStyle(PlainButtonStyle())
                                    TransactionsRow(transaction: transaction)
                                }
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)

                            }
                        }

                        if transactions.hasMorePages {
                            Button(action: {
                                Task {
                                    await transactions.fetchTransactions(loadMore: true)
                                }
                            }) {
                                Text("Load More")
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .listRowSeparator(.hidden)
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.clear)
                }
            }
            .background(Color.clear)
            .onAppear {
                if transactions.transactions == nil {
                    Task {
                        await transactions.fetchTransactions()
                    }
                }
            }
            .refreshable {
                applyDateFilter()
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
        .sheet(isPresented: $addSheetShown) {
            TransactionCreate().presentationDetents([.fraction(0.9)]).background(.ultraThinMaterial)
        }
    }

    private var filterSection: some View {
        VStack {
            Button(action: {
                withAnimation {
                    filterExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Filter")
                        .font(.subheadline)
                    Spacer()
                    Image(systemName: filterExpanded ? "chevron.up" : "chevron.down")
                }
                .contentShape(Rectangle())  // This ensures the entire HStack is tappable
            }
            .buttonStyle(PlainButtonStyle())  // This removes the default button styling

            if filterExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    DatePicker(
                        "Start Date", selection: $transactions.startDate, displayedComponents: .date
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                    DatePicker(
                        "End Date", selection: $transactions.endDate, displayedComponents: .date
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                    HStack {
                        Button("Apply Filter") {
                            applyDateFilter()
                        }
                        Spacer()
                        Button("Reset") {
                            transactions.resetDates()
                            applyDateFilter()
                        }
                    }
                }
                .padding(.top)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }

    private func applyDateFilter() {
        Task {
            await transactions.fetchTransactions()
        }
        withAnimation {
            filterExpanded = false
        }
    }
}

struct TransactionsRow: View {
    var transaction: TransactionsTransaction
    var showDate = true
    var showAccount = true
    var body: some View {
        VStack {
            HStack {
                Image(systemName: transactionTypeIcon(transaction.type ?? "unknown"))
                    .foregroundStyle(transactionTypeStyle(transaction.type ?? "unknown"))
                    .frame(width: 60, height: 60)
                    .font(.system(size: 30))

                VStack(alignment: .leading) {
                    Text(transaction.description ?? "Unkown Description")
                        .font(.headline)
                        .lineLimit(1)
                    Text(formatAmount(transaction.amount, symbol: transaction.currencySymbol))
                        .font(.largeTitle)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Spacer()
                    if showAccount {
                        if transaction.sourceName != nil {
                            Text(transaction.sourceName ?? "Source Error")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }
                    }
                    if showDate {
                        Text(formatDate(transaction.date))
                            .foregroundStyle(.gray)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)  // Add padding inside the HStack
        }
        .background(.ultraThinMaterial)  // Add a background color if needed
        .cornerRadius(16)  // Round the corners
        .padding(.horizontal)  // Add horizontal padding to the entire row
        .padding(.vertical, 8)
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

}

//struct TransactionsView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionsView(transactions: TransactionsViewModel.mock())
//    }
//}
