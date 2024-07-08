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
            .background(Color.clear)

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

//#Preview {
//    AccountsView()
//}
