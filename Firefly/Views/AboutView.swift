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
  @EnvironmentObject var menuViewModel: MenuViewModel
  var body: some View {
    NavigationView {
      VStack(alignment: .leading) {
        //                List {
        //                    HStack {
        //                        Text("Email:")
        //                        Spacer()
        //                        Text(user.user?.data?.attributes?.email ?? "Email Placeholder")
        //                    }
        //                    NavigationLink(destination: TokenSettings()) {
        //                        Text("Token")
        //                    }
        //
        //                }
        //                .refreshable {
        //                    do {
        //                        print("Refreshing")
        //                        print(user.user?.data?.attributes?.email ?? "Nothing")
        //                        try await user.getUser()
        //                    } catch {
        //                        print(error)
        //                    }
        //                }
        CategoriesDonut()
        //.frame(height: 300)
        Spacer()
      }

      //.frame(width: .infinity, height: .infinity)
      .task {
        do {
          try await user.getUser()
        } catch {
          print(error)
        }
      }

      .navigationTitle("Home")
      .toolbar {
        Button(action: {
          menuViewModel.openSearchSheet()
        }) {
          Image(systemName: "magnifyingglass.circle.fill")
            .padding(6)
            .fontWeight(.heavy)
        }
      }
      //            .navigationBarItems(leading: Text("Analytics").font(.subheadline))
      //            .navigationTitle("Home")
      //            .navigationBarTitleDisplayMode(.large)
    }
    .overlay(alignment: .bottomTrailing) {
      FloatingButton(action: {
        menuViewModel.openTransactionSheet()
      })
    }
    .background(.ultraThinMaterial)

  }

}
//struct AboutView_Previews: PreviewProvider {
//    static var previews: some View {
//        AboutView()
//    }
//}
