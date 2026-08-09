import AlertToast
import SafariServices
import SwiftUI

// MARK: - Notifications

// Posts transaction-related notifications that other views can listen for
// Notifications defined in: Firefly/Helpers/NotificationConstants.swift
// Example: AppNotifications.transactionDeleted

struct TransactionDetail: View {
    @State var transactionID: String
    @StateObject private var viewModel: TransactionDetailViewModel

    init(transactionID: String) {
        _transactionID = .init(initialValue: transactionID)
        _viewModel = StateObject(
            wrappedValue: TransactionDetailViewModel(transactionId: transactionID)
        )
    }

    /// Toasts and controllers
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var pendingDeleteManager: PendingDeleteManager

    @State private var editSheetShown = false
    @State private var cloneSheetShown = false
    @State private var cloneLoading = false
    @State private var toastParams = AlertToast(
        displayMode: .hud, type: .error(Color.red)
    )
    @State private var showToast = false
    @State private var deleteToast = false

    var body: some View {
        ScrollView {
            VStack {
                if viewModel.isLoading {
                    LoadingSpinner()
                } else if viewModel.errorMessage != nil {
                    Text("Something went wrong")
                } else if let transaction = viewModel.transaction {
                    TransactionBodyView(
                        transaction: transaction,
                        onDelete: { viewModel.showDeleteAlert = true }
                    )
                }
            }
        }
        .scrollIndicators(.hidden)
        .task {
            await viewModel.fetchTransaction()
        }
        .refreshable {
            await viewModel.refreshTransaction()
        }.toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Edit", systemImage: "pencil.circle.fill") {
                        editSheetShown = true
                    }.disabled(viewModel.isLoading)

                    Menu {
                        Button("Clone and Save", systemImage: "document.on.document.fill") {
                            Task {
                                await cloneAndSave()
                            }
                        }.disabled(viewModel.isLoading)

                        Button("Clone and Edit", systemImage: "long.text.page.and.pencil.fill") {
                            cloneSheetShown = true
                        }.disabled(viewModel.isLoading)
                    } label: {
                        Label("Clone", systemImage: "document.on.document.fill")
                    }

                    WebviewButton(url: WebviewPaths.transaction(viewModel.transactionId))
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("More options")
            }
        }
        .alert(
            "Are you sure you want to delete this transaction?",
            isPresented: $viewModel.showDeleteAlert
        ) {
            Button("Delete", role: .destructive) {
                // Schedule with an undo window; the snackbar in RootView offers Undo
                if let data = viewModel.transaction?.data {
                    pendingDeleteManager.scheduleDelete(
                        id: data.id ?? transactionID, title: data.transactionTitle
                    )
                } else {
                    pendingDeleteManager.scheduleDelete(id: transactionID, title: "Transaction")
                }
                dismiss()
            }
        }
        .sheet(
            isPresented: $editSheetShown,
            onDismiss: {
                Task {
                    await viewModel.refreshTransaction(transactionID: transactionID)
                }
            },
            content: {
                TransactionEdit(transactionData: (viewModel.transaction?.data)!)
            }
        )
        .sheet(
            isPresented: $cloneSheetShown,
            onDismiss: {
                Task {
                    await viewModel.refreshTransaction(transactionID: transactionID)
                }
            },
            content: {
                if let transaction = viewModel.transaction?.data {
                    TransactionCreate(initialTransaction: transaction)
                        .background(.ultraThinMaterial)
                }
            }
        )
        .toast(isPresenting: $showToast, tapToDismiss: false) {
            toastParams
        }
        .toast(isPresenting: $viewModel.showToast) {
            viewModel.toastParams
        }
        .padding(.horizontal, 15)
        .navigationTitle("Transaction Details")
        .toolbarTitleDisplayMode(.inline)
    }

    /// Clone and save transaction directly
    @MainActor
    private func cloneAndSave() async {
        guard let trans = viewModel.transaction?.data?.attributes?.transactions?.first else {
            AppLog.app.error("No transaction data to clone")
            return
        }

        cloneLoading = true
        do {
            try await postTransaction(
                description: trans.description ?? "",
                amount: formatAmountForTextField(
                    trans.amount ?? "0",
                    decimalPlace: trans.currencyDecimalPlaces ?? 2
                ),
                date: Date(), // Use current date and time
                category: trans.categoryName ?? "",
                type: convertTypeToDisplay(trans.type ?? "withdrawal"),
                sourceAccount: (
                    id: trans.sourceID ?? "",
                    name: trans.sourceName ?? ""
                ),
                destinationAccount: (
                    id: trans.destinationID ?? "",
                    name: trans.destinationName ?? ""
                ),
                // Drop the original's location — this clone is happening here and now, not where
                // the original was made. Quick clones don't capture a fresh fix; that would put a
                // multi-second wait behind a one-tap action.
                notes: TransactionLocation.strip(from: trans.notes) ?? "",
                budgetID: trans.budgetID
            )
            toastParams = AlertToast(
                displayMode: .alert, type: .complete(Color.green),
                title: "Transaction cloned successfully"
            )
            showToast = true

            // Post notification to refresh TransactionsView
            NotificationCenter.default.post(name: AppNotifications.transactionCreated, object: nil)
        } catch {
            toastParams = AlertToast(
                displayMode: .alert,
                type: .systemImage("exclamationmark.triangle.fill", Color.red),
                title: "Failed to clone transaction"
            )
            showToast = true
            AppLog.networkError("Failed to clone transaction", error)
        }
        cloneLoading = false
    }
}

struct TransactionBodyView: View {
    @State var transaction: TransactionDetailDatum
    let onDelete: () -> Void

    @State private var opacity = 0.1

    var body: some View {
        Group {
            TransactionDetailHeader(data: transaction.data!)
            TransactionDetailSectionHeader(title: "Details")

            TransactionInfoCard(transaction: transaction.data!)

            // Split transactions if any
            if transaction.data!.isSplitTransaction {
                if let transactions = transaction.data?.attributes?.transactions {
                    ForEach(
                        Array(transactions.enumerated()), id: \.element.transactionJournalID
                    ) { index, splitTransaction in
                        TransactionDetailSectionHeader(
                            title: splitTransaction.description ?? "Unknown",
                            subTitle: "Split Transaction #\(index + 1)"
                        )

                        SplitTransactionCard(transaction: splitTransaction)
                    }
                }
            }
            if let tags = transaction.data?.attributes?.transactions?.first?.tags, !tags.isEmpty {
                TransactionDetailSectionHeader(title: "Tags")
                    .padding(.bottom, -10)

                TagsCard(tags: tags)
            }

            // Strip the location marker: it's Hotaru's own bookkeeping, not something the user wrote.
            // A transaction whose notes are *only* a marker has no notes to show at all.
            if let notes = TransactionLocation.strip(
                from: transaction.data?.attributes?.transactions?.first?.notes
            ) {
                TransactionDetailSectionHeader(title: "Notes")

                NotesCard(notes: notes)
            }

            if let location = TransactionLocation.resolve(
                for: transaction.data?.attributes?.transactions?.first
            ) {
                TransactionDetailSectionHeader(title: "Location")

                TransactionLocationCard(location: location)
            }

            VStack {
                PrimaryButton(
                    icon: "trash.fill",
                    label: "Delete Transaction",
                    color: Color.red,
                    fullWidth: true,
                    action: { onDelete() }
                ).padding(.vertical, 8)
            }

            TransactionDetailMoreInfo(
                transactionID: transaction.data?.id, transaction: transaction.data
            )
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.2)) {
                opacity = 1.0
            }
        }
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
    var data: TransactionsDatum
    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 60
    var body: some View {
        HStack {
            Image(
                systemName: transactionTypeIcon(
                    data.attributes?.transactions?
                        .first?
                        .type ?? "unknown"
                )
            )
            .foregroundStyle(
                transactionTypeStyle(
                    data.attributes?.transactions?.first?.type ?? "unknown"
                )
            )
            .frame(width: iconSize * 1.33, height: iconSize)
            .font(.system(size: iconSize))

            VStack(alignment: .leading) {
                HStack {
                    Text(transactionMainTitle(data))
                    if data.isSplitTransaction {
                        SplitBadge()
                    }
                    if data.attributes?.transactions?.first?.reconciled == true {
                        SplitBadge(text: "Reconciled", imageName: "checkmark.seal.fill", backgroundColor: .blue)
                    }
                }

                Text(
                    data.attributes?.transactions?.first?.type?.capitalized
                        ?? "Unknown"
                ).foregroundStyle(
                    transactionTypeColor(
                        type: data.attributes?.transactions?.first?.type
                            ?? "unknown"
                    )
                )
                Spacer()
                Text(
                    formatJSONToPrettyStringDate(
                        data.attributes?.transactions?.first?.date
                            ?? "Unknown"
                    )
                        ?? "Unknown"
                )
                .font(.footnote)
            }
            Spacer()
        }.padding()
    }
}

struct TransactionDetailMoreInfo: View {
    @State private var showDetails = false

    let transactionID: String?
    let transaction: TransactionsDatum?

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("More Info")
                Spacer()
                Image(systemName: showDetails ? "eye.fill" : "eye.slash.fill").contentTransition(
                    .symbolEffect(.automatic)
                )
            }.highPriorityGesture(
                TapGesture().onEnded {
                    withAnimation {
                        showDetails.toggle()
                    }
                }
            )

            if showDetails {
                Text("Transaction ID: \(transactionID ?? "N/A")")
                if let latitude = transaction?.attributes?.transactions?.first?.latitude,
                   let longitude = transaction?.attributes?.transactions?.first?.longitude,
                   let mapsURL = URL(string: "https://maps.apple.com/?ll=\(latitude),\(longitude)") {
                    Link(destination: mapsURL) {
                        HStack(spacing: 4) {
                            Image(systemName: "map.fill")
                            Text("Open Location in Maps")
                        }
                    }
                    .foregroundStyle(Color.accentColor)
                }
                Spacer()
            }
        }
        .foregroundStyle(Color.gray)
        .padding(.horizontal)
    }
}

struct TransactionInfoCard: View {
    var transaction: TransactionsDatum

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Amount section
            AmountSection(transaction: transaction)
            Divider()
            // Source/Destination section
            AccountsSection(transaction: transaction)
            // Category/Budget/Bill — split transactions show these per-split in
            // SplitTransactionCard instead, since the parent journal doesn't have a single
            // category/budget/bill of its own.
            if !transaction.isSplitTransaction {
                Divider()
                CategorySection(transaction: transaction)

                if let billName = transaction.attributes?.transactions?.first?.billName,
                   !billName.isEmpty {
                    Divider()
                    BillSection(transaction: transaction)
                }
            }
        }
        .padding(.horizontal)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18.0))
    }
}

struct AmountSection: View {
    var transaction: TransactionsDatum

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                if transaction.isSplitTransaction {
                    Text("Total Amount")
                } else {
                    Text("Amount").font(.title3)
                }
                Text(
                    formatAmount(
                        calculateTransactionTotalAmount(transaction),
                        symbol: transaction.attributes?.transactions?.first?.currencySymbol
                    )
                )
                .font(.largeTitle)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(
                    transactionTypeColor(
                        type: transaction.attributes?.transactions?.first?.type ?? "unknown"
                    )
                )
                .contentTransition(.numericText(countsDown: true))

                if let foreignAmount = transaction.attributes?.transactions?.first?.foreignAmount,
                   let foreignSymbol = transaction.attributes?.transactions?.first?.foreignCurrencySymbol {
                    Text("≈ \(formatAmount(foreignAmount, symbol: foreignSymbol))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            Spacer()
        }
    }
}

struct AccountsSection: View {
    let transaction: TransactionsDatum

    @AppStorage(UserDefaultKeys.showSourceBalanceAfter) private var showSourceBalanceAfter = false
    @AppStorage(UserDefaultKeys.showDestinationBalanceAfter) private var showDestinationBalanceAfter = false

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text("Source").font(.title3)
                Text(transaction.attributes?.transactions?.first?.sourceName ?? "Unknown")
                    .font(.largeTitle)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                if showSourceBalanceAfter,
                   let balance = transaction.attributes?.transactions?.first?.sourceBalanceAfter {
                    Text(
                        "Balance after: \(formatAmount(balance, symbol: transaction.attributes?.transactions?.first?.currencySymbol))"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding()

            Spacer()

            VStack(alignment: .leading) {
                Text("Destination").font(.title3)
                Text(transaction.attributes?.transactions?.first?.destinationName ?? "Unknown")
                    .font(.largeTitle)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                if showDestinationBalanceAfter,
                   let balance = transaction.attributes?.transactions?.first?.destinationBalanceAfter {
                    Text(
                        "Balance after: \(formatAmount(balance, symbol: transaction.attributes?.transactions?.first?.currencySymbol))"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
    }
}

struct CategorySection: View {
    let transaction: TransactionsDatum

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                Text("Category").font(.title3)
                Text(transaction.attributes?.transactions?.first?.categoryName ?? "Unknown")
                    .font(.largeTitle)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .padding()

            Spacer()

            if let budgetName = transaction.attributes?.transactions?.first?.budgetName {
                VStack(alignment: .leading) {
                    Text("Budget").font(.title3)
                    Text(budgetName)
                        .font(.largeTitle)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .padding()
            }
        }
    }
}

struct BillSection: View {
    let transaction: TransactionsDatum

    var body: some View {
        VStack(alignment: .leading) {
            Text("Bill").font(.title3)
            Text(transaction.attributes?.transactions?.first?.billName ?? "Unknown")
                .font(.title)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SplitTransactionCard: View {
    let transaction: TransactionsTransaction

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Amount Section
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text("Amount").font(.title3)
                    Text(
                        formatAmount(
                            transaction.amount ?? "Unknown",
                            symbol: transaction.currencySymbol
                        )
                    )
                    .font(.largeTitle)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(
                        transactionTypeColor(type: transaction.type ?? "unknown")
                    )
                }
                .padding()
                Spacer()
            }

            Divider()

            // Category and Budget Section
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Text("Category").font(.title3)
                    Text(transaction.categoryName ?? "Unknown")
                        .font(.largeTitle)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .padding()

                Spacer()

                if transaction.budgetName != nil {
                    VStack(alignment: .leading) {
                        Text("Budget").font(.title3)
                        Text(transaction.budgetName ?? "Unknown")
                            .font(.largeTitle)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
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

struct NotesCard: View {
    let notes: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(notes)
                .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                .padding(.vertical)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18.0))
    }
}

struct TagsCard: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    TagView(tag: tag)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18.0))
    }
}

// struct TransactionDetailAmountSection: View {
//    let title: String
//   let
//
//    var body: some View {
//        VStack(alignment: .leading) {
//            Text(title).font(.title3)
//            Text(formatAmount)
//        }
//    }
// }
// #Preview {
//    TransactionDetail()
// }
