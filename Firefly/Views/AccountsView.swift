//
//  AuthInfo.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/01/04.
//

import SwiftUI

struct SearchOption: View {
    var optionName: String
    var active: Bool
    var body: some View {
        Text(optionName)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Capsule(style: .continuous).fill(active ? Color.blue : Color.white))
            .foregroundStyle(active ? .red : .black)
            .contentShape(Capsule())
            .onTapGesture {
                withAnimation(.interactiveSpring()) {
                    print("tapped")
                }
            }
    }
}

struct AccountsView: View {
    @StateObject private var accounts = AccountsViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                if accounts.isLoading {
                    Text("Loading")
                } else {
                    List {
                        HStack {
                            SearchOption(optionName: "Savings", active: false)
                            SearchOption(optionName: "Spending", active: true)
                        }

                        ForEach(accounts.accounts?.data ?? [], id: \.id) {
                            accountData in
                            if accountData.attributes != nil {
                                Text(accountData.attributes?.name ?? "NO NAME")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Accounts")

        }
        .task {
            do {
                try await accounts.getAccounts()
            } catch {
                print(error)
            }
        }
    }

}

#Preview {
    AccountsView()
}
