//
//  AccountDetail.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/12.
//

import SwiftUI

struct AccountDetail: View {

  @State var account: AccountsDatum
  //var accountID: String
  var accountTransactions: Transactions = Transactions()

  @StateObject private var viewModel: AccountDetailViewModel

  init(account: AccountsDatum) {
    _account = .init(initialValue: account)
    _viewModel = StateObject(wrappedValue: AccountDetailViewModel(accountID: account.id ?? "1"))
  }

  var body: some View {

    ScrollView {
      VStack {
        Text("DEBUG").onTapGesture {
          print(viewModel.accountID)
        }
        Text("Current balance")
        Text(
          formatAmount(
            account.attributes?.currentBalance ?? "Unknown",
            symbol: account.attributes?.currencySymbol)
        )
        .font(.largeTitle)
        .fontWeight(.bold)
        .padding(.top, 1)
      }
      .padding(.top, 40)
      .padding(.bottom)
      //Notes
      NotesDisplayField(notes: account.attributes?.notes)

      if account.attributes?.accountNumber != nil {
        ObfuscatedTextDisplayField(
          label: "AccountNumber", value: account.attributes?.accountNumber)
      }
      HStack {
        Text("Recent Transactions")
          .fontWeight(.bold)
          .font(.title2)
        Spacer()
      }.padding()
      AccountTransactionsView(accountID: account.id!)

    }.onAppear {
      if accountTransactions == nil {
        Task {
          do {
            let result = try await getTransactionsForAccount(account.id!)
          }

        }
      }
    }

    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .principal) {
        VStack {
          Text(account.attributes?.name ?? "Unknown").font(.headline)
          Text("Asset Account")
        }
      }
    }
  }
}

struct ObfuscatedTextDisplayField: View {
  var label: String
  var value: String?
  @State private var copied = false
  @State private var refreshed = false
  @State private var bounce = 0
  @State private var spin = false
  @State private var loading = false
  //@State private var timer = TimerHolder()

  var body: some View {
    let empty = value == nil || (value?.isEmpty ?? false)
    VStack(alignment: .leading, spacing: 6) {
      HStack(alignment: .bottom) {
        Text(label).fontWeight(.semibold)
        Spacer()
        HStack(spacing: 12) {
          Button {

            UIPasteboard.general.string = value
            withAnimation(.bouncy) {
              copied = true
              bounce += 1
            }
            doThisAfter(0.3) {
              withAnimation {
                copied = false
              }
            }
          } label: {
            Image(systemName: "doc.on.clipboard")
              .symbolRenderingMode(.hierarchical)
              .brightness(copied ? 0.2 : 0)
              .symbolEffect(.bounce, value: bounce)
          }
        }
      }
      Text((empty ? "Empty" : value) ?? "Empty").opacity(0.5)
        .fontDesign(.monospaced)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .compositingGroup()
    .opacity(empty ? 0.75 : 1)
  }
}

struct NotesDisplayField: View {
  let notes: String?

  var body: some View {
    if notes == nil {
      EmptyView()
    } else {
      VStack {
        TransactionDetailSectionHeader(title: "Notes")
        VStack(alignment: .leading, spacing: 0) {
          VStack(alignment: .leading) {
            Text(notes ?? "Something went wrong")
            Spacer()  // This will push the content to the top
          }
          .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
          .padding(.vertical)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18.0))
      }.padding()
    }
  }
}

struct AccountTransactionsView: View {
  var accountID: String
  @State private var transactions: Transactions? = nil
  @State private var isLoading = false
  @State private var transactionsLoaded = false

  var body: some View {
    NavigationStack {

      ScrollView {
        LazyVStack {
          ForEach(transactions?.data ?? [], id: \.id) { transactionData in
            TransactionsRow(transaction: transactionData)
              .animation(
                .easeIn(duration: 0.3).delay(0.05), value: transactionsLoaded)
          }
        }
      }
      .onAppear {
        if transactions == nil {
          Task {
            do {
              isLoading = true
              transactions = try await fetchAccountTransactions(accountID)
              isLoading = false
            }
          }
        }
      }
    }

  }
  func fetchAccountTransactions(_ accountID: String) async throws -> Transactions {
    var request = try RequestBuilder(apiURL: apiPaths.accountTransactions(accountID))
    request.url?.append(queryItems: [
      URLQueryItem(name: "limit", value: "100")
    ])

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
      throw UserModelError.invalidResponse
    }

    do {
      let decoder = JSONDecoder()
      let result = try decoder.decode(Transactions.self, from: data)
      return result
    }
  }
}
//
////#Preview {
////    AccountDetail()
////}
