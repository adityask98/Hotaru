//
//  AboutView.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2023/10/09.
//

import SwiftUI

struct AboutView: View {
    @ObservedObject private var user = UserModel()
    @State private var transactions = TransactionsViewModel()
    //    @StateObject var userAPIClient = UserAPIClient()
    //    @State private var isDataLoaded = false
    var body: some View {
        NavigationView {
            VStack {
                List {
                    HStack {
                        Text("Email:")
                        Spacer()
                        Text(user.user?.data?.attributes?.email ?? "Email Placeholder")
                    }
                    NavigationLink(destination: TokenSettings()) {
                        Text("Token")
                    }
                }
                .refreshable {
                    do {
                        print("Refreshing")
                        print(user.user?.data?.attributes?.email ?? "Nothing")
                        try await user.getUser()
                    } catch {
                        print(error)
                    }
                }
            }
            .padding()
            .frame(width: .infinity, height: .infinity)
            .task {
                do {
                    try await user.getUser()

//                    if let userId = user.user?.data?.id {
//                        try await transactions.getTransactions(userId)
//                    } else {
//                        // Handle the case when user.user?.data?.id is nil
//                        print("User ID is missing")
//                    }
                } catch {
                    print(error)
                }
            }
        }

    }

    struct AboutView_Previews: PreviewProvider {
        static var previews: some View {
            AboutView()
        }
    }
}
