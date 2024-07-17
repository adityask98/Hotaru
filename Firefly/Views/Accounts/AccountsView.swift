//
//  AuthInfo.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/01/04.
//

import SwiftUI

@MainActor
struct AccountsView: View {
    @StateObject private var accounts = AccountsViewModel()
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    if isLoading {
                        LoadingSpinner()
                    } else {
                        //                        VStack {
                        //                            HStack {
                        //                                SearchOption(optionName: "Savings", active: false)
                        //                                SearchOption(optionName: "Spending", active: true)
                        //                            }
                        //                            .padding()
                        //
                        //                            ForEach(accounts.accounts?.data ?? [], id: \.id) { accountData in
                        //                                if accountData.attributes != nil {
                        //                                    Text(accountData.attributes?.name ?? "NO NAME")
                        //                                }
                        //                            }
                        //                        }

                        LazyVGrid(
                            columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                            ], alignment: .center, spacing: 10
                        ) {
                            ForEach(accounts.accounts?.data ?? [], id: \.id) { accountData in
                                AccountItem(account: accountData)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Accounts")
            .background(Color.clear)
            .refreshable {
                Task {
                    await accounts.fetchAccounts()
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
}

struct AccountItem: View {
    var account: AccountsDatum
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
                        .font(.system(size: 12))
                }
                .padding(.bottom, -4)
                Divider().padding(.horizontal, -16)
                // Balance
                Text(
                    formatAmount(
                        account.attributes?.currentBalance,
                        symbol: account.attributes?.currencySymbol)
                )
                .font(.title)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Spacer()
                    Text("As of \(formatDate(account.attributes?.currentBalanceDate))").font(
                        .caption2
                    )
                    .fontWeight(
                        .ultraLight)
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
    }

    private func formatAmount(_ amountString: String?, symbol: String?) -> String {
        guard let amountString = amountString,
            let amount = Double(amountString)
        else {
            return "Unknown Amount"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = symbol ?? "¥"
        return formatter.string(from: NSNumber(value: amount)) ?? "Unknown Amount"
    }

    private func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString,
            let date = ISO8601DateFormatter().date(from: dateString)
        else {
            return "Unknown Date"
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

//#Preview {
//    AccountsView()
//}
