import SwiftUI

/// Horizontally scrolling asset accounts with their current balance, so "how much
/// money do I have" is answered without switching to the Accounts tab. Reuses the
/// Accounts tab's card, and each one pushes the same `AccountDetail`.
struct HomeAccountsStrip: View {
    let state: LoadState<[AccountsDatum]>
    let onRetry: () -> Void
    @Namespace private var accountTransition

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader(title: "Accounts")

            switch state {
            case .idle, .loading:
                HomeCard { HomeSectionLoading() }
            case .failed(let message):
                HomeCard { HomeSectionError(message: message, onRetry: onRetry) }
            case .loaded(let accounts):
                if accounts.isEmpty {
                    HomeCard {
                        Text("No asset accounts yet.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 12) {
                            ForEach(accounts, id: \.id) { account in
                                AccountItem(
                                    account: account,
                                    amountHidden: .constant(false),
                                    namespace: accountTransition
                                )
                            }
                        }
                        .padding(.horizontal)
                        // Cards carry a shadow-free material background; a little
                        // vertical room keeps them from clipping against the row.
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }
}
