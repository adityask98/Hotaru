import SwiftUI

struct CategoryDetailView: View {
    @State var category: CategoriesDatum?
    @StateObject private var viewModel: CategoryDetailViewModel

    init(category: CategoriesDatum? = nil) {
        _category = .init(initialValue: category)
        _viewModel = StateObject(
            wrappedValue: CategoryDetailViewModel(
                categoryId: category?.id ?? "1"
            )
        )
    }

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Text("Recent Transactions").fontWeight(.bold).font(.title2)
                    Spacer()
                }.padding()

                if viewModel.transactionsIsLoading && viewModel.transactions?.data?.isEmpty != false {
                    LoadingSpinner()
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
            }
        }
        .onAppear {
            Task {
                if viewModel.transactions == nil {
                    await viewModel.fetchTransactions()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(category?.attributes?.name ?? "Unknown Category")
    }
}

#Preview {
    CategoryDetailView()
}
