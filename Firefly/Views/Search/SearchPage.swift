import SwiftUI

struct SearchPage: View {
    @StateObject var searchVM = SearchViewModel()
    @ScaledMetric(relativeTo: .largeTitle) private var promptIconSize: CGFloat = 70

    var body: some View {
        NavigationStack {
            Group {
                if searchVM.isLoading {
                    LoadingSpinner()
                } else if let errorMessage = searchVM.errorMessage {
                    ErrorStateView(message: errorMessage) {
                        searchVM.search()
                    }
                } else if let searchResults = searchVM.searchResults {
                    if searchResults.data?.isEmpty == false {
                        Text("Results for \"\(searchVM.searchDebouncedText)\"")
                            .font(.headline)
                        SearchTransactionsView(transactions: searchResults)
                    } else {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            message: "No results for \"\(searchVM.searchDebouncedText)\""
                        )
                    }
                } else {
                    // No search has run yet (empty field, or debounce still pending)
                    VStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: promptIconSize))
                            .foregroundColor(.gray.opacity(0.7))
                            .padding()

                        Text("Search for transactions")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal)

                        Text("Enter keywords in the search bar above")
                            .font(.subheadline)
                            .foregroundColor(.gray.opacity(0.8))
                            .padding(.top, 5)
                    }
                    .padding()
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .searchable(text: $searchVM.searchText, placement: .toolbar, prompt: "Search...")
            .onChange(of: searchVM.searchDebouncedText) { _, _ in
                searchVM.search()
            }
            .navigationTitle("Search")
            .transactionNavigationDestination()
            .navigationBarTitleDisplayMode(.inline)
        }
        .transactionNavigationScope()
    }
}

struct SearchTransactionsView: View {
    var transactions: Transactions
    @State private var transactionsLoaded = false
    @EnvironmentObject private var pendingDeleteManager: PendingDeleteManager

    /// Hides rows pending delete (swipe/context-menu delete), matching `TransactionsList`.
    private var visibleTransactions: [TransactionsDatum] {
        (transactions.data ?? []).filter { datum in
            guard let id = datum.id else { return true }
            return !pendingDeleteManager.hiddenIDs.contains(id)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(visibleTransactions, id: \.id) { transactionData in
                    TransactionsRow(transaction: transactionData)
                        .animation(
                            .easeIn(duration: 0.3).delay(0.05), value: transactionsLoaded
                        )
                        .onAppear {
                            transactionsLoaded = true
                        }
                }
            }
            .transactionSwipeActionsContainer()
        }
    }
}

// #Preview {
//  SearchPage()
// }
