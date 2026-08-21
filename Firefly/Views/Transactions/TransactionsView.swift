import SwiftUI

// Warm accent used in place of the (unset) system AccentColor, scoped to the
// filter card so it reads intentionally against the red/green/blue already
// used for transaction types elsewhere in the app.
private let filterAccent = Color(red: 1.0, green: 0.616, blue: 0.361) // #FF9D5C
private let filterAccentText = Color(red: 0.169, green: 0.078, blue: 0) // #2B1400

// MARK: - Notification Listeners

// Transaction events from other views are observed via .onReceive in the body,
// using AppNotifications constants defined in NotificationConstants.swift

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
    @State var addSheetShown = false
    @State private var filterExpanded = false
    @State private var dateRangeEditing = false
    @EnvironmentObject var menuViewModel: MenuViewModel

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                filterSection
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                // Full-screen spinner only before the first load; refreshes and
                // filter changes keep the list on screen so it doesn't flash
                if transactions.isLoading, transactions.transactions == nil {
                    LoadingSpinner()
                } else if transactions.transactions == nil, let message = transactions.errorMessage {
                    ErrorStateView(message: message) {
                        applyDateFilter()
                    }
                    Spacer()
                } else {
                    ScrollView {
                        TransactionsList(
                            transactions: transactions.transactions,
                            hasMorePages: transactions.hasMorePages,
                            onLoadMore: {
                                Task {
                                    await transactions.fetchTransactions(loadMore: true)
                                }
                            }
                        )
                    }
                    // Keeps the last row clear of the floating add button
                    .contentMargins(.bottom, 96, for: .scrollContent)
                    // .listRowSpacing(-10)
                    .listStyle(PlainListStyle())
                    .background(Color.clear)
                    .opacity(transactions.isLoading ? 0.5 : 1)
                    .animation(.easeInOut(duration: 0.2), value: transactions.isLoading)
                    .refreshable {
                        // Await directly so the system refresh indicator stays up
                        // until the new data has actually arrived
                        await transactions.fetchTransactions()
                    }
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
            .onReceive(
                NotificationCenter.default.publisher(for: AppNotifications.transactionDeleted)
            ) { _ in
                Task { await transactions.fetchTransactions() }
            }
            .onReceive(
                NotificationCenter.default.publisher(for: AppNotifications.transactionCreated)
            ) { _ in
                Task { await transactions.fetchTransactions() }
            }
            .onReceive(
                NotificationCenter.default.publisher(for: AppNotifications.transactionUpdated)
            ) { _ in
                Task { await transactions.fetchTransactions() }
            }
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    // Opens the experimental TransactionAdd screen
                    // (see docs/TRANSACTION_FORM_REWRITE.md)
                    Button(action: {
                        menuViewModel.openTransactionAddSheet()
                    }) {
                        Image(systemName: "testtube.2")
                            .padding(6)
                            .fontWeight(.heavy)
                            .foregroundStyle(.orange)
                    }
                    .accessibilityLabel("Experimental add transaction screen")
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            FloatingButton(action: {
                addSheetShown = true
            })
        }
        .sheet(isPresented: $addSheetShown) {
            TransactionCreate().background(.ultraThinMaterial)
        }
    }

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation {
                    filterExpanded.toggle()
                }
            }) {
                HStack {
                    HStack(spacing: 8) {
                        Text("Filter")
                            .fontSize(15, .bold, design: .rounded)
                        if transactions.type != .all {
                            Text(transactions.type.displayName)
                                .fontSize(11, .bold, design: .rounded)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 3)
                                .background(filterAccent)
                                .foregroundStyle(filterAccentText)
                                .clipShape(Capsule())
                        }
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 26, height: 26)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(filterAccent)
                            .rotationEffect(Angle.degrees(filterExpanded ? 180 : 0))
                            .animation(.bouncy, value: filterExpanded)
                    }
                }
                .contentShape(Rectangle()) // This ensures the entire HStack is tappable
            }
            .buttonStyle(PlainButtonStyle()) // This removes the default button styling
            .foregroundStyle(.primary)

            if filterExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    filterDateRangeRow
                    filterTypeRow
                    filterActionRow
                }
                .padding(.top, 18)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }

    private func filterRowLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .fontSize(12, .semibold, design: .rounded)
            .foregroundStyle(.secondary)
            .tracking(0.3)
    }

    private var filterDateRangeRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            filterRowLabel("Date Range")
            Button(action: {
                withAnimation {
                    dateRangeEditing.toggle()
                }
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text(formatDateRange(transactions.startDate, transactions.endDate))
                        .fontSize(15, .medium, design: .rounded)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(Angle.degrees(dateRangeEditing ? 90 : 0))
                        .animation(.bouncy, value: dateRangeEditing)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(Color.gray.opacity(0.12))
                .cornerRadius(10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)

            if dateRangeEditing {
                HStack(spacing: 12) {
                    DatePicker("Start Date", selection: $transactions.startDate, displayedComponents: .date)
                        .labelsHidden()
                    Text("–")
                        .foregroundStyle(.secondary)
                    DatePicker("End Date", selection: $transactions.endDate, displayedComponents: .date)
                        .labelsHidden()
                    Spacer()
                }
                .datePickerStyle(.compact)
                .tint(filterAccent)
                .padding(.top, 2)
            }
        }
    }

    private var filterTypeRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            filterRowLabel("Type")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(TransactionTypes.filterCases) { type in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                transactions.type = type
                            }
                        }) {
                            Text(type.displayName)
                                .fontSize(13, .semibold, design: .rounded)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(transactions.type == type ? filterAccent : Color.gray.opacity(0.12))
                                )
                                .foregroundStyle(transactions.type == type ? filterAccentText : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var filterActionRow: some View {
        HStack(spacing: 10) {
            Button(action: {
                transactions.resetDates()
                applyDateFilter()
            }) {
                Text("Reset")
                    .fontSize(15, .semibold, design: .rounded)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.12))
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)

            PrimaryButton(
                label: "Apply Filter",
                textSize: 15,
                color: filterAccent,
                textColor: filterAccentText,
                height: 44,
                fullWidth: true,
                cornerRadius: 12,
                action: { applyDateFilter() }
            )
        }
    }

    private func applyDateFilter(isRefreshing: Bool = false) {
        Task {
            await transactions.fetchTransactions()
        }
        withAnimation {
            filterExpanded = false
            dateRangeEditing = false
        }
    }
}

// struct TransactionsView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionsView(transactions: TransactionsViewModel.mock())
//    }
// }
