import SwiftUI

@MainActor
struct AccountsView: View {
    @EnvironmentObject var menuViewModel: MenuViewModel
    @StateObject private var accounts = AccountsViewModel()
    @StateObject private var chartStore = ChartOverviewStore()
    @State private var isLoading = false
    @AppStorage("accountsBalanceChartExpanded") private var balanceChartExpanded = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    if isLoading {
                        LoadingSpinner()
                    } else if accounts.accounts == nil, let message = accounts.errorMessage {
                        ErrorStateView(message: message) {
                            Task { await accounts.fetchAccounts() }
                        }
                        .padding(.top, 80)
                    } else if accounts.accounts?.data?.isEmpty == true {
                        EmptyStateView(icon: "creditcard", message: "No accounts found")
                    } else {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                            ], alignment: .center, spacing: 10
                        ) {
                            ForEach(accounts.accounts?.data ?? [], id: \.id) { accountData in
                                AccountItem(account: accountData, amountHidden: $accounts.amountHidden)
                            }
                        }
                        .padding()

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
            .overlay(
                alignment: .bottomTrailing,
                content: {
                    FloatingButton(
                        action: {
                            accounts.toggleAmountVisibility()
                        },
                        imageSystemName: accounts.amountHidden ? "eye.slash.fill" : "eye.fill",
                        accessibilityLabel: accounts.amountHidden ? "Show balances" : "Hide balances"
                    ).contentTransition(.symbolEffect(.automatic))
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
        .cornerRadius(10)
    }
}

struct AccountItem: View {
    var account: AccountsDatum
    @Binding var amountHidden: Bool
    var body: some View {
        ZStack {
            VStack {
                // Account Name
                HStack {
                    Text(account.attributes?.name ?? "Unknown")
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.green)
                        .font(.caption)
                }
                .padding(.bottom, -4)
                Divider().padding(.horizontal, -16)
                // Balance
                Text(
                    formatAmount(
                        account.attributes?.currentBalance,
                        symbol: account.attributes?.currencySymbol
                    )
                )
                .redacted(reason: amountHidden ? .placeholder : [])
                .contentTransition(.numericText())
                .animation(.default, value: account.attributes?.currentBalance)
                .font(.title)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Spacer()
                    Text("As of \(formatDate(account.attributes?.currentBalanceDate))")
                        .font(.caption2)
                        .fontWeight(.ultraLight)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 7)
            .frame(width: 175)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            NavigationLink(destination: AccountDetail(account: account)) {
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
            }
        }
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
