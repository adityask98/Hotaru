import Foundation

@MainActor
final class CategoryDetailViewModel: ObservableObject {
    @Published var category: CategoriesDatum?
    @Published var isLoading = false
    @Published var transactions: Transactions?
    @Published var transactionsIsLoading = false
    @Published var hasMorePages = true
    @Published var transactionsErrorMessage: String?

    private let paginationManager: TransactionsPaginationManager

    let categoryId: String

    init(categoryId: String) {
        self.categoryId = categoryId
        paginationManager = TransactionsPaginationManager(
            apiProvider: CategoryTransactionsAPIProvider(categoryId: categoryId)
        )

        paginationManager.$transactions.assign(to: &$transactions)
        paginationManager.$isLoading.assign(to: &$transactionsIsLoading)
        paginationManager.$hasMorePages.assign(to: &$hasMorePages)
        paginationManager.$errorMessage.assign(to: &$transactionsErrorMessage)
    }

    func fetchTransactions(loadMore: Bool = false) async {
        await paginationManager.fetchTransactions(loadMore: loadMore)
    }
}
