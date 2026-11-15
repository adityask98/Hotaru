import SwiftUI

@MainActor
struct AccountsView: View {
    @EnvironmentObject var menuViewModel: MenuViewModel
    @StateObject private var accounts = AccountsViewModel()
    @StateObject private var chartStore = ChartOverviewStore()
    @AppStorage(UserDefaultKeys.amountHidden) private var amountHidden = false
    @AppStorage("accountsBalanceChartExpanded") private var balanceChartExpanded = true
    @Namespace private var accountTransition

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Only before the first load; pull-to-refresh keeps the grid on screen
                    if accounts.isLoading, accounts.accounts == nil {
                        LoadingSpinner()
                    } else if accounts.accounts == nil, let message = accounts.errorMessage {
                        ErrorStateView(message: message) {
                            Task { await accounts.fetchAccounts() }
                        }
                        .padding(.top, 80)
                    } else if accounts.accounts?.data?.isEmpty == true {
                        EmptyStateView(icon: "creditcard", message: "No accounts found")
                    } else {
                        // Cards fill their column, so the grid's outer edges line up
                        // with the balance chart card below
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12),
                            ], spacing: 12
                        ) {
                            ForEach(accounts.accounts?.data ?? [], id: \.id) { accountData in
                                AccountItem(account: accountData, namespace: accountTransition)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)

                        balanceChartSection
                            .padding(.horizontal)

                        // Buffer so the chart's scrub-selection card (which appears
                        // below the chart) has room to scroll into view — the user's
                        // finger is locked to the chart's drag gesture while scrubbing,
                        // so they can't scroll to reveal it after the fact.
                        Color.clear.frame(height: 200)
                    }
                }
            }
            .navigationTitle(Text("Accounts"))
            .transactionNavigationDestination()
            .overlay(
                alignment: .bottomTrailing,
                content: {
                    FloatingButton(
                        action: {
                            withAnimation(.snappy) { amountHidden.toggle() }
                        },
                        imageSystemName: amountHidden ? "eye.slash.fill" : "eye.fill",
                        accessibilityLabel: amountHidden ? "Show balances" : "Hide balances"
                    )
                }
            )

            .background(Color.clear)
            .scrollBounceBehavior(.always)
            .refreshable {
                await accounts.fetchAccounts()
                if balanceChartExpanded {
                    chartStore.invalidate()
                }
            }
        }
        .transactionNavigationScope()
        .onAppear {
            if accounts.accounts == nil {
                Task {
                    await accounts.fetchAccounts()
                }
            }
        }
    }

    private var balanceChartSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                withAnimation {
                    balanceChartExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Balance over time")
                        .fontSize(15, .bold, design: .rounded)
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 26, height: 26)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .rotationEffect(Angle.degrees(balanceChartExpanded ? 180 : 0))
                            .animation(.bouncy, value: balanceChartExpanded)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .foregroundStyle(.primary)
            .padding(16)

            if balanceChartExpanded {
                AccountBalanceChart(store: chartStore)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct AccountItem: View {
    var account: AccountsDatum
    let namespace: Namespace.ID
    /// Fixed card width for horizontal strips (Home). `nil` fills the grid column.
    var fixedWidth: CGFloat?
    @AppStorage(UserDefaultKeys.amountHidden) private var amountHidden = false

    /// Source/destination pairing key for the zoom transition. Falls back to the
    /// account name so two accounts never share an id if the API omits one.
    private var transitionID: String {
        account.id ?? account.attributes?.name ?? "unknown"
    }

    var body: some View {
        // The card itself is the link's label, so VoiceOver reads the account and the
        // card gets the plain style's press highlight.
        NavigationLink {
            AccountDetail(account: account)
                .navigationTransition(.zoom(sourceID: transitionID, in: namespace))
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text(account.attributes?.name ?? "Unknown")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tertiary)
                }

                Text(
                    formatAmount(
                        account.attributes?.currentBalance,
                        symbol: account.attributes?.currencySymbol
                    )
                )
                .font(.title2)
                .fontWeight(.semibold)
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .redacted(reason: amountHidden ? .placeholder : [])
                .contentTransition(.numericText())
                .animation(.default, value: account.attributes?.currentBalance)

                Text("As of \(formatDate(account.attributes?.currentBalanceDate))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            .padding(14)
            .frame(width: fixedWidth, alignment: .leading)
            .frame(maxWidth: fixedWidth == nil ? .infinity : nil, alignment: .leading)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .contentShape(RoundedRectangle(cornerRadius: 18))
            // Applied to the card rather than the link, so the zoom starts from the
            // card's clipped bounds.
            .matchedTransitionSource(id: transitionID, in: namespace) { source in
                source.clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            WebviewButton(url: WebviewPaths.account(account.id!))
        }
    }

    private func formatAmount(_ amountString: String?, symbol: String?) -> String {
        guard let amountString = amountString,
              let amount = Double(amountString) else {
            return "Unknown Amount"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = symbol ?? "¥"
        return formatter.string(from: NSNumber(value: amount)) ?? "Unknown Amount"
    }
}

// #Preview {
//    AccountsView()
// }
