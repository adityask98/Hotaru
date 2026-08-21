import SwiftUI

/// The five most recent transactions, using the same row as the Transactions tab
/// (including its context menu, so edit/clone/delete work here too).
struct HomeRecentTransactions: View {
    let state: LoadState<[TransactionsDatum]>
    let onRetry: () -> Void

    /// Same key the tab bar binds to, so "See all" switches to the Transactions tab.
    @AppStorage("tabViewLast") private var selectedTab = 1
    @EnvironmentObject private var pendingDeleteManager: PendingDeleteManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader(title: "Recent") {
                Button("See all") {
                    selectedTab = 2
                }
            }

            switch state {
            case .idle, .loading:
                HomeCard { HomeSectionLoading() }
            case .failed(let message):
                HomeCard { HomeSectionError(message: message, onRetry: onRetry) }
            case .loaded(let transactions):
                let visible = transactions.filter { datum in
                    guard let id = datum.id else { return true }
                    return !pendingDeleteManager.hiddenIDs.contains(id)
                }
                if visible.isEmpty {
                    HomeCard {
                        Text("No transactions yet.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(visible, id: \.id) { transaction in
                            TransactionsRow(transaction: transaction)
                        }
                    }
                }
            }
        }
    }
}
