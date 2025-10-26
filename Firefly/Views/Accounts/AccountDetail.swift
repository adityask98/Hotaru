import SwiftUI

struct AccountDetail: View {
    @State var account: AccountsDatum
    @StateObject private var viewModel: AccountDetailViewModel

    init(account: AccountsDatum) {
        _account = .init(initialValue: account)
        _viewModel = StateObject(wrappedValue: AccountDetailViewModel(accountID: account.id ?? "1"))
    }

    var body: some View {
        ScrollView {
            VStack {
                Text("Current balance")
                Text(
                    formatAmount(
                        account.attributes?.currentBalance ?? "Unknown",
                        symbol: account.attributes?.currencySymbol
                    )
                )
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 1)
            }
            .padding(.top, 40)
            .padding(.bottom)

            // Notes
            NotesDisplayField(notes: account.attributes?.notes)

            if account.attributes?.accountNumber != nil {
                AccountNumberCopiableView(
                    label: "Account Number", value: account.attributes?.accountNumber
                )
            }

            HStack {
                Text("Recent Transactions")
                    .fontWeight(.bold)
                    .font(.title2)
                Spacer()
            }.padding()

            if viewModel.transactionsIsLoading && viewModel.transactions?.data?.isEmpty != false {
                LoadingSpinner()
                    .padding()
            } else {
                TransactionsList(
                    transactions: viewModel.transactions,
                    hasMorePages: viewModel.hasMorePages
                ) {
                    Task {
                        await viewModel.fetchTransactions(loadMore: true)
                    }
                }
            }
        }.onAppear {
            Task {
                if viewModel.transactions == nil {
                    await viewModel.fetchTransactions()
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

struct AccountNumberCopiableView: View {
    var label: String
    var value: String?
    @State private var copied = false
    @State private var refreshed = false
    @State private var bounce = 0
    @State private var spin = false
    @State private var loading = false
    @State private var feedbackTrigger = 0

    var body: some View {
        let empty = value == nil || (value?.isEmpty ?? false)
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .bottom) {
                Text(label).fontWeight(.semibold)
                Spacer()
                HStack(spacing: 12) {
                    Button {
                        feedbackTrigger += 1
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
        .sensoryFeedback(.success, trigger: feedbackTrigger)
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
                        Text(notes ?? "Something went wrong").textSelection(.enabled)
                        Spacer() // This will push the content to the top
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

//
////#Preview {
////    AccountDetail()
////}
