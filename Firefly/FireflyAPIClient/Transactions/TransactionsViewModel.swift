import Foundation

enum TransactionsModelError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
}

enum TransactionTypes: String, CaseIterable, Identifiable {
    case all
    case withdrawal
    case withdrawals
    case expense
    case deposit
    case deposits
    case income
    case transfer
    case transfers
    case opening_balance
    case reconciliation
    case special
    case specials
    // case default = "default"
    var id: String { rawValue }
}

@MainActor
final class TransactionsViewModel: ObservableObject {
    @Published var transactions: Transactions?
    @Published var isLoading = false
    @Published var currentPage = 1
    @Published var hasMorePages = true
    @Published var startDate: Date = Calendar.current.date(
        byAdding: .month, value: -1, to: Date.now
    )!
    @Published var endDate = Date.now
    @Published var type: TransactionTypes = .all

    func fetchTransactions(loadMore: Bool = false) async {
        if loadMore {
            currentPage += 1
        } else {
            currentPage = 1
        }
        if !loadMore {
            isLoading = true
        }

        do {
            // let newTransactions = try await getTransactions(page: currentPage)
            let newTransactions: Transactions

            if loadMore {
                if (transactions?.links?.next) != nil {
                    newTransactions = try await getTransactionsFromURL(
                        (transactions?.links?.next)!)
                    transactions?.data?.append(contentsOf: newTransactions.data ?? [])
                    transactions?.links = newTransactions.links
                    transactions?.meta = newTransactions.meta
                }
            } else {
                transactions = try await getTransactions(
                    type: type.rawValue, startDate: formatDateToYYYYMMDD(startDate),
                    endDate: formatDateToYYYYMMDD(endDate),
                    page: 1
                )
            }

            if transactions?.meta?.pagination?.currentPage
                == transactions?.meta?.pagination?.totalPages {
                hasMorePages = false
            }
        } catch {
            print("Error fetching transactions: \(error)")
        }
        if !loadMore {
            isLoading = false
        }
    }

    func getTransactions(
        limit: Int = 20,
        type: String = "all",
        startDate: String,
        endDate: String,
        page: Int
    ) async throws -> Transactions {
        var request = try RequestBuilder(apiURL: ApiPaths.transactions)
        request.url?.append(queryItems: [
            // URLQueryItem(name: "type", value: type),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "start", value: startDate),
            URLQueryItem(name: "end", value: endDate),
            URLQueryItem(name: "type", value: type),
        ])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw TransactionsModelError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(Transactions.self, from: data)

            return result
        } catch {
            print(error)
            throw TransactionsModelError.invalidData
        }
    }

    func getTransactionsFromURL(_ urlString: String) async throws -> Transactions {
        let request = try RequestBuilder(apiURL: urlString, ignoreBaseURL: true)

        return try await performRequest(request)
    }

    private func performRequest(_ request: URLRequest) async throws -> Transactions {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw TransactionsModelError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(Transactions.self, from: data)
            return result
        } catch {
            print(error)
            throw TransactionsModelError.invalidData
        }
    }

    func resetDates() {
        startDate = Calendar.current.date(
            byAdding: .month, value: -1, to: Date.now
        )!
        endDate = Date.now
        type = .all
    }
}

extension TransactionsViewModel {
    static func mock() -> TransactionsViewModel {
        let viewModel = TransactionsViewModel()

        let mockTransactions = Transactions(
            data: [
                createMockTransaction(
                    id: "95", amount: "500", description: "Transit", category: "Transit",
                    date: "2024-07-02T22:01:00+02:00"
                ),
                createMockTransaction(
                    id: "94", amount: "888", description: "Conbini", category: "Eating out",
                    date: "2024-07-02T13:08:00+02:00"
                ),
                createMockTransaction(
                    id: "93", amount: "2185", description: "Groceries", category: "Groceries",
                    date: "2024-07-01T13:18:55+02:00"
                ),
                createMockTransaction(
                    id: "91", amount: "523", description: "Conbini", category: "Eating out",
                    date: "2024-06-30T21:58:00+02:00"
                ),
                createMockTransaction(
                    id: "90", amount: "1270", description: "McDonald's", category: "Eating out",
                    date: "2024-06-29T23:10:00+02:00"
                ),
            ],
            meta: TransactionsMeta(
                pagination: TransactionsPagination(
                    total: 92,
                    count: 15,
                    perPage: 15,
                    currentPage: 1,
                    totalPages: 7
                )),
            links: TransactionsLinks(
                linksSelf:
                "http://100.96.204.49:8888/api/v1/transactions?limit=15&type=default&page=1",
                first: "http://100.96.204.49:8888/api/v1/transactions?limit=15&type=default&page=1",
                next: "http://100.96.204.49:8888/api/v1/transactions?limit=15&type=default&page=2",
                last: "http://100.96.204.49:8888/api/v1/transactions?limit=15&type=default&page=7"
            )
        )

        viewModel.transactions = mockTransactions
        viewModel.isLoading = false

        return viewModel
    }

    private static func createMockTransaction(
        id: String, amount: String, description: String, category: String, date: String
    ) -> TransactionsDatum {
        let transaction = TransactionsTransaction(
            user: "1",
            transactionJournalID: id,
            type: "withdrawal",
            date: date,
            order: 0,
            currencyID: "18",
            currencyCode: "JPY",
            currencyName: "Japanese yen",
            currencySymbol: "¥",
            currencyDecimalPlaces: 0,
            foreignCurrencyID: nil,
            foreignCurrencyCode: nil,
            foreignCurrencySymbol: nil,
            foreignCurrencyDecimalPlaces: 0,
            amount: amount,
            foreignAmount: nil,
            description: description,
            sourceID: "5",
            sourceName: "SMBC",
            sourceIban: nil,
            sourceType: "Asset account",
            destinationID: "7",
            destinationName: "Cash account",
            destinationIban: nil,
            destinationType: "Cash account",
            budgetID: nil,
            budgetName: nil,
            categoryID: "1",
            categoryName: category,
            billID: nil,
            billName: nil,
            reconciled: false,
            notes: nil,
            tags: [],
            internalReference: nil,
            externalID: nil,
            originalSource: "ff3-v6.1.15|api-v2.0.14",
            recurrenceID: nil,
            recurrenceTotal: nil,
            recurrenceCount: nil,
            bunqPaymentID: nil,
            externalURL: nil,
            importHashV2: "hash",
            sepaCc: nil,
            sepaCTOp: nil,
            sepaCTID: nil,
            sepaDB: nil,
            sepaCountry: nil,
            sepaEp: nil,
            sepaCi: nil,
            sepaBatchID: nil,
            interestDate: nil,
            bookDate: nil,
            processDate: nil,
            dueDate: nil,
            paymentDate: nil,
            invoiceDate: nil,
            longitude: nil,
            latitude: nil,
            zoomLevel: nil,
            hasAttachments: false
        )

        return TransactionsDatum(
            type: "transactions",
            id: id,
            attributes: TransactionsAttributes(
                createdAt: "2024-07-02T15:01:51+02:00",
                updatedAt: "2024-07-02T15:01:51+02:00",
                user: "1",
                groupTitle: nil,
                transactions: [transaction]
            ),
            links: TransactionsDatumLinks(
                the0: TransactionsThe0(rel: "self", uri: "/transactions/\(id)"),
                linksSelf: "http://100.96.204.49:8888/api/v1/transactions/\(id)"
            )
        )
    }
}
