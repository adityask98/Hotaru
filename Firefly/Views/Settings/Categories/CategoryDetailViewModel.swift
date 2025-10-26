import Foundation

@MainActor
final class CategoryDetailViewModel: ObservableObject {
    @Published var category: CategoriesDatum?
    @Published var isLoading = false
    @Published var transactions: Transactions?
    @Published var transactionsIsLoading = false
    @Published var hasMorePages = true

    private var paginationManager: TransactionsPaginationManager?

    let categoryId: String

    init(categoryId: String) {
        self.categoryId = categoryId
        updatePaginationManager()
    }

    private func updatePaginationManager() {
        let apiProvider = CategoryTransactionsAPIProvider(categoryId: categoryId)
        paginationManager = TransactionsPaginationManager(apiProvider: apiProvider)

        setupBindings()
    }

    private func setupBindings() {
        guard let paginationManager = paginationManager else { return }

        paginationManager.$transactions
            .assign(to: &$transactions)

        paginationManager.$isLoading
            .assign(to: &$transactionsIsLoading)

        paginationManager.$hasMorePages
            .assign(to: &$hasMorePages)
    }

    func fetchTransactions(loadMore: Bool = false) async {
        if !loadMore {
            updatePaginationManager()
        }
        await paginationManager?.fetchTransactions(loadMore: loadMore)
    }
}
