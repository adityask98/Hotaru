//
//  SearchPage.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2025/05/11.
//

import SwiftUI

struct SearchPage: View {
  @Environment(\.dismiss) var dismiss
  @StateObject var searchVM = SearchViewModel()
  @State private var searchText = ""

  var body: some View {
      Group {
        if searchVM.searchText.isEmpty {
          // Show centered search symbol when no search text
          VStack {
            Image(systemName: "magnifyingglass")
              .font(.system(size: 70))
              .foregroundColor(.gray.opacity(0.7))
              .padding()

            Text("Search for transactions")
              .font(.headline)
              .multilineTextAlignment(.center)
              .foregroundColor(.gray)
              .padding(.horizontal)

            Text("Enter keywords in the search bar above")
              .font(.subheadline)
              .foregroundColor(.gray.opacity(0.8))
              .padding(.top, 5)
          }
          .padding()
        } else if searchVM.isLoading {
          LoadingSpinner()
        } else if let errorMessage = searchVM.errorMessage {
          // Show error state
          VStack {
            Image(systemName: "exclamationmark.triangle")
              .font(.system(size: 50))
              .foregroundColor(.orange)
              .padding()

            Text("Error")
              .font(.headline)
              .foregroundColor(.primary)
              .padding(.bottom, 4)

            Text(errorMessage)
              .font(.subheadline)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
              .padding(.horizontal)

            Button("Try Again") {
              searchVM.search()
            }
            .buttonStyle(.bordered)
            .padding(.top)
          }
          .padding()
        } else {
          // Show search results when text is entered
          Text("Results for \"\(searchVM.searchDebouncedText)\"")
            .font(.headline)
          if let searchResults = searchVM.searchResults {
            SearchTransactionsView(transactions: searchResults)
          } else {
            Text("No results found")
              .foregroundColor(.gray)
              .padding()
          }
        }
      }
      .scrollDismissesKeyboard(.automatic)
      .searchable(text: $searchVM.searchText, placement: .toolbar, prompt: "Search...")
      .onChange(of: searchVM.searchDebouncedText) { oldValue, newValue in
        searchVM.search()
        print("Searching")
      }
      .navigationTitle("Search")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }
}

struct SearchTransactionsView: View {
  var transactions: Transactions
  @State private var transactionsLoaded = false

  var body: some View {
    ScrollView {
      LazyVStack {
        ForEach(transactions.data ?? [], id: \.id) { transactionData in
          TransactionsRow(transaction: transactionData)
            .animation(
              .easeIn(duration: 0.3).delay(0.05), value: transactionsLoaded
            )
            .onAppear {
              transactionsLoaded = true
            }
        }
      }
    }
  }
}

//#Preview {
//  SearchPage()
//}
