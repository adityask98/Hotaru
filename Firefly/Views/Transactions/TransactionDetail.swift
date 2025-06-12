//
//  TransactionDetail.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/10.
//

import AlertToast
import SwiftUI

struct TransactionDetail: View {

  @State var transactionID: String
  @StateObject private var viewModel: TransactionDetailViewModel

  init(transactionID: String) {
    _transactionID = .init(initialValue: transactionID)
    _viewModel = StateObject(
      wrappedValue: TransactionDetailViewModel(transactionId: transactionID)
    )
  }

  //Toasts and controllers
  @Environment(\.dismiss) var dismiss
  //@Binding var shouldRefresh: Bool?

  @State private var editSheetShown = false
  @State private var toastParams: AlertToast = AlertToast(
    displayMode: .hud, type: .error(Color.red))
  @State private var showToast = false
  @State private var deleteToast = false

  var body: some View {
    ScrollView {
      VStack {
        if viewModel.isLoading {
          LoadingSpinner()
        } else if let errorMessage = viewModel.errorMessage {
          Text("Something went wrong")
        } else if let transaction = viewModel.transaction {
          TransactionBodyView(
            transaction: transaction,
            onDelete: { viewModel.showDeleteAlert = true })
        }
      }
    }
    .scrollIndicators(.hidden)
    .task {
      await viewModel.fetchTransaction()
    }
    .refreshable {
      await viewModel.refreshTransaction()
    }.toolbar {
      Button(action: {
        editSheetShown = true
      }) {
        Image(systemName: "pencil.circle.fill")
          .padding(6)
          .fontWeight(.heavy)
      }.disabled(viewModel.isLoading)
    }
    .alert(
      "Are you sure you want to delete this transaction?",
      isPresented: $viewModel.showDeleteAlert
    ) {
      Button("Delete", role: .destructive) {
        Task {
          do {
            try await deleteTransaction()
          }
        }
      }
    }
    .sheet(
      isPresented: $editSheetShown,
      onDismiss: {
        Task {
          await viewModel.refreshTransaction(transactionID: transactionID)
        }
      },
      content: {
        TransactionEdit(transactionData: (viewModel.transaction?.data)!)
      }
    )
    .toast(isPresenting: $showToast, tapToDismiss: false) {
      toastParams
    }
    .toast(isPresenting: $viewModel.showToast) {
      viewModel.toastParams
    }
    .padding(.horizontal, 15)
    .navigationTitle("Transaction Details")
    .toolbarTitleDisplayMode(.inline)
  }

  @MainActor
  private func deleteTransaction() async throws {
    do {
      try await viewModel.deleteTransaction(
        transactionID: transactionID)
      toastParams = AlertToast(
        displayMode: .alert, type: .complete(Color.green),
        title: "Transaction deleted successfully")
      showToast = true
      doThisAfter(2.0) {
        //shouldRefresh? = true
        dismiss()
      }
    } catch {
      toastParams = AlertToast(
        displayMode: .alert,
        type: .systemImage("exclamationmark.triangle.fill", Color.red),
        title: viewModel.errorMessage)
      withAnimation {
        showToast = true
      }
      doThisAfter(2.0) {
        showToast = false
      }
    }
  }

  private func formatDate(_ dateString: String) -> String? {

    guard let date = ISO8601DateFormatter().date(from: dateString)
    else {
      return "Unknown Date"
    }
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}

struct TransactionBodyView: View {
  @State var transaction: TransactionDetailDatum
  let onDelete: () -> Void

  @State private var opacity: Double = 0.1

  var body: some View {
    Group {

      TransactionDetailHeader(data: transaction.data!)
      TransactionDetailSectionHeader(title: "Details")

      TransactionInfoCard(transaction: transaction.data!)

      // Split transactions if any
      if isSplitTransaction(transaction.data!) {
        if let transactions = transaction.data?.attributes?.transactions {
          ForEach(
            Array(transactions.enumerated()), id: \.element.transactionJournalID
          ) { index, splitTransaction in
            TransactionDetailSectionHeader(
              title: splitTransaction.description ?? "Unknown",
              subTitle: "Split Transaction #\(index + 1)")

            SplitTransactionCard(transaction: splitTransaction)
          }
        }
      }
      if let notes = transaction.data?.attributes?.transactions?.first?.notes {
        TransactionDetailSectionHeader(title: "Notes")
          .padding(.bottom, -10)

        NotesCard(notes: notes)
      }

      VStack {
        MasterButton(
          icon: "trash.fill",
          label: "Delete Transaction",
          color: Color.red,
          fullWidth: true,
          action: { onDelete() }
        ).padding(.vertical, 8)
      }

      TransactionDetailMoreInfo(
        transactionID: transaction.data?.id, transaction: transaction.data)
    }
    .opacity(opacity)
    .onAppear {
      withAnimation(.easeInOut(duration: 0.2)) {
        opacity = 1.0
      }
    }
  }
}

struct TagView: View {
  let tag: String

  var body: some View {
    Text(tag)
      .lineLimit(1)
      .padding(.horizontal, 10)
      .padding(.vertical, 5)
      .background(Color.blue.opacity(0.2))
      .foregroundColor(.blue)
      .clipShape(Capsule())
  }
}

struct TransactionDetailSectionHeader: View {
  let title: String
  let subTitle: String?

  init(title: String = "Details", subTitle: String? = nil) {
    self.title = title
    self.subTitle = subTitle
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .fontWeight(.bold)
        .font(.title2)

      if let subTitle = subTitle {
        Text(subTitle)
          .font(.caption)
          .fontWeight(.light)
          .foregroundStyle(Color.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal)
  }
}

struct TransactionDetailHeader: View {

  var data: TransactionsDatum
  var body: some View {
    HStack {
      Image(
        systemName: transactionTypeIcon(
          data.attributes?.transactions?
            .first?
            .type ?? "unknown")
      )
      .foregroundStyle(
        transactionTypeStyle(
          data.attributes?.transactions?.first?.type ?? "unknown")
      )
      .frame(width: 80, height: 60)
      .font(.system(size: 60))

      VStack(alignment: .leading) {

        HStack {
          Text(transactionMainTitle(data))
          if isSplitTransaction(data) {
            SplitBadge()
          }
        }

        Text(
          data.attributes?.transactions?.first?.type?.capitalized
            ?? "Unknown"
        ).foregroundStyle(
          transactionTypeColor(
            type: data.attributes?.transactions?.first?.type
              ?? "unknown"
          ))
        Spacer()
        Text(
          formatJSONToPrettyStringDate(
            data.attributes?.transactions?.first?.date
              ?? "Unknown")
            ?? "Unknown"
        )
        .font(.footnote)
      }
      Spacer()
    }.padding()
  }
}

struct TransactionDetailMoreInfo: View {

  @State private var showDetails: Bool = false

  let transactionID: String?
  let transaction: TransactionsDatum?

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text("More Info")
        Spacer()
        Image(systemName: showDetails ? "eye.fill" : "eye.slash.fill").contentTransition(
          .symbolEffect(.automatic))
      }.highPriorityGesture(
        TapGesture().onEnded {
          withAnimation {
            showDetails.toggle()
          }
        }
      )

      if showDetails {
        Text("Transaction ID: \(transactionID ?? "N/A")")
        Text("Location: \(transaction?.attributes?.transactions?[0].latitude)")
        Spacer()
      }
    }
    .foregroundStyle(Color.gray)
    .padding(.horizontal)
  }
}

struct TransactionInfoCard: View {
  var transaction: TransactionsDatum

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Amount section
      AmountSection(transaction: transaction)
      Divider()
      // Source/Destination section
      AccountsSection(transaction: transaction)
      Divider()
      // Category/Budget section
      if !isSplitTransaction(transaction) {
        CategorySection(transaction: transaction)
      }
    }
    .padding(.horizontal)
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 18.0))
  }
}

struct AmountSection: View {
  var transaction: TransactionsDatum

  var body: some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading) {
        if isSplitTransaction(transaction) {
          Text("Total Amount")
        } else {
          Text("Amount").font(.title3)
        }
        Text(
          formatAmount(
            calculateTransactionTotalAmount(transaction),
            symbol: transaction.attributes?.transactions?.first?.currencySymbol
          )
        )
        .font(.largeTitle)
        .minimumScaleFactor(0.5)
        .lineLimit(1)
        .foregroundStyle(
          transactionTypeColor(
            type: transaction.attributes?.transactions?.first?.type ?? "unknown"
          )
        )
        .contentTransition(.numericText(countsDown: true))
      }
      .padding()
      Spacer()
    }
  }
}

struct AccountsSection: View {
  let transaction: TransactionsDatum

  var body: some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading) {
        Text("Source").font(.title3)
        Text(transaction.attributes?.transactions?.first?.sourceName ?? "Unknown")
          .font(.largeTitle)
          .minimumScaleFactor(0.5)
          .lineLimit(1)
      }
      .padding()

      Spacer()

      VStack(alignment: .leading) {
        Text("Destination").font(.title3)
        Text(transaction.attributes?.transactions?.first?.destinationName ?? "Unknown")
          .font(.largeTitle)
          .minimumScaleFactor(0.5)
          .lineLimit(1)
      }
      .padding()
    }
  }
}

struct CategorySection: View {
  let transaction: TransactionsDatum

  var body: some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading) {
        Text("Category").font(.title3)
        Text(transaction.attributes?.transactions?.first?.categoryName ?? "Unknown")
          .font(.largeTitle)
          .minimumScaleFactor(0.5)
          .lineLimit(1)
      }
      .padding()

      Spacer()

      if let budgetName = transaction.attributes?.transactions?.first?.budgetName {
        VStack(alignment: .leading) {
          Text("Budget").font(.title3)
          Text(budgetName)
            .font(.largeTitle)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
        }
        .padding()
      }
    }
  }
}

struct SplitTransactionCard: View {
  let transaction: TransactionsTransaction

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Amount Section
      HStack(alignment: .top) {
        VStack(alignment: .leading) {
          Text("Amount").font(.title3)
          Text(
            formatAmount(
              transaction.amount ?? "Unknown",
              symbol: transaction.currencySymbol
            )
          )
          .font(.largeTitle)
          .minimumScaleFactor(0.5)
          .lineLimit(1)
          .foregroundStyle(
            transactionTypeColor(type: transaction.type ?? "unknown")
          )
        }
        .padding()
        Spacer()
      }

      Divider()

      // Category and Budget Section
      HStack(alignment: .top) {
        VStack(alignment: .leading) {
          Text("Category").font(.title3)
          Text(transaction.categoryName ?? "Unknown")
            .font(.largeTitle)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
        }
        .padding()

        Spacer()

        if transaction.budgetName != nil {
          VStack(alignment: .leading) {
            Text("Budget").font(.title3)
            Text(transaction.budgetName ?? "Unknown")
              .font(.largeTitle)
              .minimumScaleFactor(0.5)
              .lineLimit(1)
          }
          .padding()
        }
      }
    }
    .padding(.horizontal)
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 18.0))
  }
}

struct NotesCard: View {
  let notes: String

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(notes)
        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
        .padding(.vertical)
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal)
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 18.0))
  }
}

//struct TransactionDetailAmountSection: View {
//    let title: String
//   let
//
//    var body: some View {
//        VStack(alignment: .leading) {
//            Text(title).font(.title3)
//            Text(formatAmount)
//        }
//    }
//}
//#Preview {
//    TransactionDetail()
//}
