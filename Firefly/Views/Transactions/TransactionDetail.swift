//
//  TransactionDetail.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/10.
//

import AlertToast
import SwiftUI

struct TransactionDetail: View {
    @State var transaction: TransactionsDatum
    @StateObject private var transactionData = TransactionDetailViewModel()

    //Toasts and controllers
    @Environment(\.dismiss) var dismiss
    //@Binding var shouldRefresh: Bool?

    @State private var editSheetShown = false
    @State private var isLoading = true
    @State private var toastParams: AlertToast = AlertToast(
        displayMode: .hud, type: .error(Color.red))
    @State private var showToast = false
    @State private var deleteToast = false

    var tags = ["Test1", "Test2", "Test3", "LongTag", "AnotherTag"]
    var body: some View {
        ScrollView {
            VStack {
                if isLoading {
                    LoadingSpinner()
                } else {
                    if let data = transactionData.transaction?.data {

                        TransactionDetailHeader(data: data)
                    }

                    TransactionDetailSectionHeader(title: "Details")

                    if isSplitTransaction(transaction) {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading) {
                                    Text("Total Amount").font(.title3)
                                    Text(
                                        formatAmount(
                                            calculateTransactionTotalAmount(transaction),
                                            symbol: transaction.attributes?.transactions?.first?
                                                .currencySymbol)

                                    ).font(.largeTitle).minimumScaleFactor(0.5).lineLimit(1)
                                        .foregroundStyle(
                                            transactionTypeColor(
                                                type: transaction.attributes?.transactions?.first?
                                                    .type
                                                    ?? "unknown"))
                                }
                                .padding()

                                Spacer()

                            }
                            Divider()
                            HStack(alignment: .top) {
                                VStack(alignment: .leading) {
                                    Text("Source").font(.title3)
                                    Text(
                                        transaction.attributes?.transactions?.first?.sourceName
                                            ?? "Unknown"
                                    ).font(.largeTitle)
                                        .minimumScaleFactor(0.5).lineLimit(1)
                                }
                                .padding()

                                Spacer()

                                VStack(alignment: .leading) {
                                    Text("Destination").font(.title3)
                                    Text(
                                        transaction.attributes?.transactions?.first?.destinationName
                                            ?? "Unknown"
                                    ).font(.largeTitle)
                                        .minimumScaleFactor(0.5).lineLimit(1)
                                }
                                .padding()
                            }
                            Divider()

                        }
                        .padding(.horizontal)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18.0))

                        if let transactions = transaction.attributes?.transactions {
                            ForEach(
                                Array(transactions.enumerated()), id: \.element.transactionJournalID
                            ) { index, splitTransaction in
                                //TransactionDetailSectionHeader(title: "Split Transaction #\(index + 1)")
                                TransactionDetailSectionHeader(
                                    title: splitTransaction.description ?? "Unknown",
                                    subTitle: "Split Transaction #\(index + 1)")
                                VStack(alignment: .leading, spacing: 0) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading) {
                                            Text("Amount").font(.title3)
                                            Text(
                                                formatAmount(
                                                    splitTransaction.amount ?? "Unknown",
                                                    symbol: splitTransaction.currencySymbol)

                                            ).font(.largeTitle).minimumScaleFactor(0.5).lineLimit(1)
                                                .foregroundStyle(
                                                    transactionTypeColor(
                                                        type: transaction.attributes?.transactions?
                                                            .first?.type
                                                            ?? "unknown"))
                                        }
                                        .padding()
                                        Spacer()
                                    }
                                    Divider()
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading) {
                                            Text("Category").font(.title3)
                                            Text(
                                                splitTransaction.categoryName
                                                    ?? "Unknown"
                                            ).font(.largeTitle)
                                                .minimumScaleFactor(0.5).lineLimit(
                                                    1)
                                        }
                                        .padding()

                                        Spacer()
                                        if splitTransaction.budgetName
                                            != nil
                                        {
                                            VStack(alignment: .leading) {
                                                Text("Budget").font(.title3)
                                                Text(
                                                    splitTransaction.budgetName
                                                        ?? "Unknown"
                                                ).font(.largeTitle)
                                                    .minimumScaleFactor(0.5).lineLimit(
                                                        1)
                                            }
                                            .padding()
                                        }

                                    }
                                }
                                .padding(.horizontal)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 18.0))

                            }
                        }

                    } else {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading) {
                                    Text("Amount").font(.title3)
                                    Text(
                                        formatAmount(
                                            calculateTransactionTotalAmount(transaction),
                                            symbol: transaction.attributes?.transactions?.first?
                                                .currencySymbol)

                                    ).font(.largeTitle).minimumScaleFactor(0.5).lineLimit(1)
                                        .foregroundStyle(
                                            transactionTypeColor(
                                                type: transaction.attributes?.transactions?.first?
                                                    .type
                                                    ?? "unknown"))
                                }
                                .padding()

                                Spacer()

                            }
                            Divider()
                            HStack(alignment: .top) {
                                VStack(alignment: .leading) {
                                    Text("Source").font(.title3)
                                    Text(
                                        transaction.attributes?.transactions?.first?.sourceName
                                            ?? "Unknown"
                                    ).font(.largeTitle)
                                        .minimumScaleFactor(0.5).lineLimit(1)
                                }
                                .padding()

                                Spacer()

                                VStack(alignment: .leading) {
                                    Text("Destination").font(.title3)
                                    Text(
                                        transaction.attributes?.transactions?.first?.destinationName
                                            ?? "Unknown"
                                    ).font(.largeTitle)
                                        .minimumScaleFactor(0.5).lineLimit(1)
                                }
                                .padding()
                            }
                            Divider()
                            HStack(alignment: .top) {
                                VStack(alignment: .leading) {
                                    Text("Category").font(.title3)
                                    Text(
                                        transaction.attributes?.transactions?.first?.categoryName
                                            ?? "Unknown"
                                    ).font(.largeTitle)
                                        .minimumScaleFactor(0.5).lineLimit(
                                            1)
                                }
                                .padding()

                                Spacer()
                                if transaction.attributes?.transactions?.first?.budgetName != nil {
                                    VStack(alignment: .leading) {
                                        Text("Budget").font(.title3)
                                        Text(
                                            transaction.attributes?.transactions?.first?.budgetName
                                                ?? "Unknown"
                                        ).font(.largeTitle)
                                            .minimumScaleFactor(0.5).lineLimit(
                                                1)
                                    }
                                    .padding()
                                }

                            }
                        }
                        .padding(.horizontal)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18.0))
                    }

                    if transaction.attributes?.transactions?.first?.notes != nil {
                        TransactionDetailSectionHeader(title: "Notes").padding(.bottom, -10)

                        VStack(alignment: .leading, spacing: 0) {
                            VStack(alignment: .leading) {
                                Text(
                                    transaction.attributes?.transactions?.first?.notes
                                        ?? "Something went wrong.")
                                Spacer()  // This will push the content to the top
                            }
                            .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                            .padding(.vertical)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18.0))
                    }
                    VStack {
                        MasterButton(
                            icon: "trash.fill", label: "Delete Transaction", color: Color.red,
                            fullWidth: true,
                            action: {
                                deleteToast.toggle()
                            }
                        ).padding(.vertical, 8)
                    }

                }
            }
            .sheet(
                isPresented: $editSheetShown,
                onDismiss: {
                    Task {
                        await refresh()
                    }
                },
                content: {
                    TransactionEdit(transactionData: (transactionData.transaction?.data)!)
                }
            )
            .toolbar {
                Button(action: {
                    editSheetShown = true
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .padding(6)
                        .fontWeight(.heavy)
                }.disabled(isLoading)
            }
            .onAppear {
                if transactionData.transaction == nil {
                    Task {
                        guard transaction.id != nil else {
                            print("No ID")
                            throw TransactionsModelError.invalidData
                        }
                        isLoading = true
                        await transactionData.fetchTransaction(transactionID: transaction.id!)
                        isLoading = false
                    }
                }
            }

            .padding(.horizontal, 15)
            .navigationTitle("Transaction Details")
            .toolbarTitleDisplayMode(.inline)
            .toast(isPresenting: $showToast, tapToDismiss: false) {
                toastParams
            }
            .alert("Are you sure you want to delete this transaction?", isPresented: $deleteToast) {
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await deleteTransaction()
                        }
                    }
                }
            }
        }
        .refreshable {
            await refresh()
        }

    }

    @MainActor
    private func refresh() async {
        Task(priority: .background) {
            isLoading = true
            await transactionData.refreshTransaction(transactionID: transaction.id!)
            isLoading = false
        }
    }

    private func deleteTransaction() async throws {
        Task(priority: .background) {
            do {
                try await transactionData.deleteTransaction(
                    transactionID: (transactionData.transaction?.data?.id)!)
                toastParams = AlertToast(
                    displayMode: .alert, type: .complete(Color.green),
                    title: "Transaction deleted successfully")
                showToast = true
                doThisAfter(2.0) {
                    //shouldRefresh? = true
                    dismiss()
                }
            } catch {
                toastParams = AlertToast(
                    displayMode: .alert,
                    type: .systemImage("exclamationmark.triangle.fill", Color.red),
                    title: transactionData.errorMessage)
                withAnimation {
                    showToast = true
                }
                doThisAfter(2.0) {
                    showToast = false
                }
            }
        }
    }

    private func formatDate(_ dateString: String) -> String? {

        guard let date = ISO8601DateFormatter().date(from: dateString)
        else {
            return "Unknown Date"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
struct TagView: View {
    let tag: String

    var body: some View {
        Text(tag)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.blue.opacity(0.2))
            .foregroundColor(.blue)
            .clipShape(Capsule())
    }
}

struct TransactionDetailSectionHeader: View {
    let title: String
    let subTitle: String?

    init(title: String = "Details", subTitle: String? = nil) {
        self.title = title
        self.subTitle = subTitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .fontWeight(.bold)
                .font(.title2)

            if let subTitle = subTitle {
                Text(subTitle)
                    .font(.caption)
                    .fontWeight(.light)
                    .foregroundStyle(Color.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

struct TransactionDetailHeader: View {

    let data: TransactionsDatum
    var body: some View {
        HStack {
            Image(
                systemName: transactionTypeIcon(
                    data.attributes?.transactions?
                        .first?
                        .type ?? "unknown")
            )
            .foregroundStyle(
                transactionTypeStyle(
                    data.attributes?.transactions?.first?.type ?? "unknown")
            )
            .frame(width: 80, height: 60)
            .font(.system(size: 60))

            VStack(alignment: .leading) {

                HStack {
                    Text(transactionMainTitle(data))
                    if isSplitTransaction(data) {
                        SplitBadge()
                    }
                }

                Text(
                    data.attributes?.transactions?.first?.type?.capitalized
                        ?? "Unknown"
                ).foregroundStyle(
                    transactionTypeColor(
                        type: data.attributes?.transactions?.first?.type
                            ?? "unknown"
                    ))
                Spacer()
                Text(
                    formatJSONToPrettyStringDate(
                        data.attributes?.transactions?.first?.date
                            ?? "Unknown")
                        ?? "Unknown"
                )
                .font(.footnote)
            }
            Spacer()
        }.padding()
    }
}

//struct TransactionDetailAmountSection: View {
//    let title: String
//   let
//
//    var body: some View {
//        VStack(alignment: .leading) {
//            Text(title).font(.title3)
//            Text(formatAmount)
//        }
//    }
//}
//#Preview {
//    TransactionDetail()
//}
