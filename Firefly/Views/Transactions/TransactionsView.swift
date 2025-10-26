import SwiftUI

// MARK: - Notification Listeners

/// To listen for and handle transaction events from other views,
/// add observers here using AppNotifications constants defined in NotificationConstants.swift
/// Example:
/// ```
/// NotificationCenter.default.addObserver(
///     forName: AppNotifications.transactionDeleted,
///     object: nil,
///     queue: .main
/// ) { _ in
///     // Handle the notification
/// }
/// ```

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
    @State private var isLoading = false
    @State private var shouldRefresh: Bool? = false // Used to refresh after the create page is dismissed.
    @EnvironmentObject var menuViewModel: MenuViewModel

    var body: some View {
        let _ = setupNotificationListeners()
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                filterSection
                    .padding()
                if isLoading {
                    LoadingSpinner()
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
                    // .listRowSpacing(-10)
                    .listStyle(PlainListStyle())
                    .background(Color.clear)
                }
            }
            .background(Color.clear)
            .onAppear {
                if transactions.transactions == nil {
                    Task {
                        isLoading = true
                        await transactions.fetchTransactions()
                        isLoading = false
                    }
                }
            }
            .refreshable {
                applyDateFilter()
            }
            .navigationTitle("Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        menuViewModel.openTransactionAddSheet()
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .padding(6)
                            .fontWeight(.heavy)
                    }
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            FloatingButton(action: {
                addSheetShown = true
            })
        }
        .sheet(
            isPresented: $addSheetShown,
            onDismiss: {
                if shouldRefresh! {
                    Task {
                        applyDateFilter()
                        shouldRefresh = false
                    }
                }
            }
        ) {
            TransactionCreate(shouldRefresh: $shouldRefresh).background(.ultraThinMaterial)
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
                    Image(systemName: "chevron.down")
                        .rotationEffect(Angle.degrees(filterExpanded ? 180 : 0))
                        .animation(.bouncy, value: filterExpanded)
                }
                .contentShape(Rectangle()) // This ensures the entire HStack is tappable
            }
            .buttonStyle(PlainButtonStyle()) // This removes the default button styling

            if filterExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    DatePicker(
                        "Start Date", selection: $transactions.startDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                    DatePicker(
                        "End Date", selection: $transactions.endDate, displayedComponents: .date
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                    HStack {
                        Text("Type")
                        Spacer()
                        Picker("Type", selection: $transactions.type) {
                            ForEach(TransactionTypes.allCases) { type in
                                Text(type.rawValue.capitalized).tag(type)
                            }
                        }
                    }

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

    private func applyDateFilter(isRefreshing: Bool = false) {
        Task {
            await transactions.fetchTransactions()
        }
        withAnimation {
            filterExpanded = false
        }
    }

    // MARK: - Notification Listeners

    /// Sets up notification listeners for transaction events
    /// Call this in the body to ensure listeners are active whenever the view is rendered
    private func setupNotificationListeners() {
        NotificationCenter.default.addObserver(
            forName: AppNotifications.transactionDeleted,
            object: nil,
            queue: .main
        ) { _ in
            // Silent refresh when a transaction is deleted
            Task {
                await transactions.fetchTransactions()
            }
        }

        NotificationCenter.default.addObserver(
            forName: AppNotifications.transactionCreated,
            object: nil,
            queue: .main
        ) { _ in
            // Refresh transactions when a new one is created
            Task {
                await transactions.fetchTransactions()
            }
        }

        NotificationCenter.default.addObserver(
            forName: AppNotifications.transactionUpdated,
            object: nil,
            queue: .main
        ) { _ in
            // Refresh transactions when one is updated
            Task {
                await transactions.fetchTransactions()
            }
        }
    }
}

// struct TransactionsView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionsView(transactions: TransactionsViewModel.mock())
//    }
// }
