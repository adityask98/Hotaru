import SwiftUI

struct SearchPage: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var searchVM = SearchViewModel()
    @State private var searchText = ""
    @FocusState private var isSearchFieldFocused: Bool
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
            .interactiveDismissDisabled(!searchVM.searchText.isEmpty)
            .scrollDismissesKeyboard(.immediately)
            .searchable(text: $searchVM.searchText, placement: .toolbar, prompt: "Search...")
            .focused($isSearchFieldFocused)
            .onChange(of: searchVM.searchDebouncedText) { _, _ in
                searchVM.search()
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isSearchFieldFocused = false
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SearchTransactionsView: View {
    var transactions: Transactions
    @State private var transactionsLoaded = false

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(transactions.data ?? [], id: \.id) { transactionData in
                    TransactionsRow(transaction: transactionData)
                        .animation(
                            .easeIn(duration: 0.3).delay(0.05), value: transactionsLoaded
                        )
                        .onAppear {
                            transactionsLoaded = true
                        }
                }
            }
        }
    }
}

// #Preview {
//  SearchPage()
// }
