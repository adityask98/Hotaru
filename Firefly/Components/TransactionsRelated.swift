//
//  TransactionsRelated.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2025/05/27.
//

import SwiftUI

struct TransactionsList: View {
  var transactions: Transactions?
  var hasMorePages: Bool
  let onLoadMore: () -> Void

  var body: some View {
    LazyVStack {
      ForEach(transactions?.data ?? [], id: \.id) {
        transactionData in
        TransactionsRow(transaction: transactionData)
          .listRowInsets(EdgeInsets())
          .listRowSeparator(.hidden)
      }
      if hasMorePages || ((transactions?.data?.isEmpty) != nil) {
        LoadingSpinner()
          .onAppear {
            onLoadMore()
          }
      }
    }
    //    .listStyle(PlainListStyle())
    //    .background(Color.clear)
  }
}

struct TransactionsRow: View {
  var transaction: TransactionsDatum
  @State private var isActiveNav: Bool = true
  var showDate = true
  var showAccount = true
  var animate = true

  @State private var opacity: Double = 1.0
  @State private var showingActionSheet = false

  var body: some View {
    NavigationLink(
      destination: TransactionDetail(transactionID: transaction.id!)
    ) {
      VStack {
        HStack {
          Image(
            systemName: transactionTypeIcon(
              transaction.attributes?.transactions?.first?.type ?? "unknown")
          )
          .foregroundStyle(
            transactionTypeStyle(
              transaction.attributes?.transactions?.first?.type ?? "unknown")
          )
          .frame(width: 60, height: 60)
          .font(.system(size: 30))

          VStack(alignment: .leading) {
            Text(
              transactionMainTitle(transaction)
            )
            .font(.headline)
            .lineLimit(1)
            Text(
              formatAmount(
                calculateTransactionTotalAmount(transaction),
                symbol: transaction.attributes?.transactions?.first?.currencySymbol)
            )
            .font(.largeTitle)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
          }
          Spacer()
          VStack(alignment: .trailing) {
            Spacer()

            //In case of split Transaction
            if isSplitTransaction(transaction) {
              if showAccount {
                SplitBadge()
              }
            } else {
              if showAccount {
                if transaction.attributes?.transactions?.first?.sourceName != nil {
                  Text(
                    transaction.attributes?.transactions?.first?.sourceName
                      ?? "Source Error"
                  )
                  .font(.subheadline)
                  .foregroundStyle(.gray)
                }
              }
            }
            if showDate {
              Text(formatDate(transaction.attributes?.transactions?.first?.date))
                .foregroundStyle(.gray)
            }
          }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)  // Add padding inside the HStack
      }
      .background(.ultraThinMaterial)  // Add a background color if needed
      .cornerRadius(12)  // Round the corners
      .padding(.horizontal)  // Add horizontal padding to the entire row
      .padding(.vertical, 2)
    }
    .buttonStyle(PlainButtonStyle())
    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    .opacity(opacity)
    .onAppear {
      if animate {
        withAnimation(.easeInOut(duration: 0.1)) {
          opacity = 1.0
        }
      }
    }
    .simultaneousGesture(
      LongPressGesture(minimumDuration: 0.5)
        .onEnded { _ in
          showingActionSheet = true
        }
    )
    .confirmationDialog("Transaction Options", isPresented: $showingActionSheet) {
      Button("Edit") {
        print("edit")
      }
      Button("Delete") {
        print("delete")
      }
    }
  }

  //date formatter specific to this View
  private func formatDate(_ dateString: String?) -> String {
    guard let dateString = dateString,
      let date = ISO8601DateFormatter().date(from: dateString)
    else {
      return "Unknown Date"
    }

    let calendar = Calendar.current
    let now = Date()

    if calendar.isDate(date, equalTo: now, toGranularity: .day) {
      return "Today"
    }

    if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
      let formatter = DateFormatter()
      formatter.dateFormat = "EEEE"  // Full name of the day
      return formatter.string(from: date)
    } else {
      let formatter = DateFormatter()
      formatter.dateStyle = .medium
      formatter.timeStyle = .none
      return formatter.string(from: date)
    }
  }

}

struct SplitBadge: View {
  let text: String
  let imageName: String
  let font: Font
  let foregroundStyle: Color
  let backgroundColor: Color

  init(
    text: String = "Split",
    imageName: String = "arrow.branch",
    font: Font = .subheadline,
    foregroundStyle: Color = .white,
    backgroundColor: Color = .green
  ) {
    self.text = text
    self.imageName = imageName
    self.font = font
    self.foregroundStyle = foregroundStyle
    self.backgroundColor = backgroundColor
  }

  var body: some View {
    HStack {
      Image(systemName: imageName)
      Text(text)
    }
    .font(font)
    .foregroundStyle(foregroundStyle)
    .padding(.horizontal, 10)
    .padding(.vertical, 1)
    .background(backgroundColor)
    .clipShape(Capsule())
  }
}
