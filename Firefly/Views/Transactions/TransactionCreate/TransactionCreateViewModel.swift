import Foundation

// class TransactionCreateViewModel: ObservableObject {
//    @Published var descriptionText: String = ""
//    @Published var descriptionDebouncedText: String = ""
//    @Published var transactionsAutocomplete: [AutoTransactionElement] = []
//    private var fetchTask: Task<Void, Never>?
// }

class DescriptionInputViewModel: ObservableObject {
    @Published var text = ""
    @Published var debouncedText = ""
    @Published var transactionsAutocomplete: [AutoTransactionElement] = []
    @Published var transactionsAutocompleteEmptyQuery: [AutoTransactionElement] = []
    private var fetchTask: Task<Void, Never>?

    init() {
        setupTextDebounce()
        Task {
            try? await self.performFetch()
        }
    }

    func setupTextDebounce() {
        debouncedText = text
        $text
            .debounce(for: .seconds(0.75), scheduler: RunLoop.main)
            .assign(to: &$debouncedText)
    }

    func fetch() {
        fetchTask?.cancel()

        if debouncedText.isEmpty { return }

        fetchTask = Task {
            do {
                try await performFetch()
                if Task.isCancelled { return }
            } catch {
                if Task.isCancelled { return }
            }
        }
    }

    @MainActor
    func performFetch(onlyForInit: Bool = false) async throws {
        var request = try RequestBuilder(apiURL: AutocompleteApiPaths.transactions)
        request.url?.append(queryItems: [
            URLQueryItem(name: "query", value: String(debouncedText)),
        ])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw AutocompleteError.common
        }

        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(AutoTransactions.self, from: data)

            if onlyForInit {
                transactionsAutocompleteEmptyQuery = result
            }
            transactionsAutocomplete = result
            #if DEBUG
                print("Search Results: \(String(describing: transactionsAutocomplete))")
            #endif
        }
    }
}
