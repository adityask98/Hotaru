import Combine
import Foundation

class SearchViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchDebouncedText = ""
    @Published var searchResults: Transactions?
    @Published var isLoading = false
    @Published var errorMessage: String?
    private var searchTask: Task<Void, Never>?

    init() {
        setupSearchTextDebounce()
    }

    func setupSearchTextDebounce() {
        searchDebouncedText = searchText
        $searchText
            .debounce(for: .seconds(0.75), scheduler: RunLoop.main)
            .assign(to: &$searchDebouncedText)
    }

    func search() {
        errorMessage = nil
        searchTask?.cancel()

        if searchDebouncedText.isEmpty {
            searchResults = nil
            return
        }

        isLoading = true

        searchTask = Task {
            do {
                try await performSearch()
                if Task.isCancelled { return }
            } catch {
                if Task.isCancelled { return }
                await MainActor.run {
                    self.errorMessage = "Search failed: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    @MainActor
    func performSearch() async throws {
        var request = try RequestBuilder(apiURL: ApiPaths.searchTransactions)
        request.url?.append(queryItems: [
            URLQueryItem(name: "query", value: String(searchDebouncedText)),
        ])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw TransactionsModelError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(Transactions.self, from: data)

            searchResults = result
            isLoading = false
            #if DEBUG
                print("Search Results: \(String(describing: searchResults))")
            #endif
        }
    }
}
