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
            .frame(width: .infinity, height: .infinity)
            .task {
                do {
                    try await user.getUser()
                } catch {
                    print(error)
                }
            }
            //            .toolbar {
            //                ToolbarItem(placement: .topBarLeading) {
            //                    VStack {
            //                        Text("Title")
            //                        Text("Subtitle")
            //                    }
            //                }
            //            }
            .navigationTitle("Subtitle")
            .navigationBarItems(leading: Text("Analytics").font(.subheadline))
            //            .navigationTitle("Home")
            //            .navigationBarTitleDisplayMode(.large)
        }

    }

    struct AboutView_Previews: PreviewProvider {
        static var previews: some View {
            AboutView()
        }
    }
}
