import Foundation

/// Backs the Home dashboard. Each section fetches independently and keeps its own
/// `LoadState`, so one failing endpoint (say, budgets on an instance that doesn't
/// use them) leaves the rest of the page intact.
@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var summary: LoadState<[CurrencySummary]> = .idle
    @Published private(set) var accounts: LoadState<[AccountsDatum]> = .idle
    @Published private(set) var budgets: LoadState<[BudgetProgress]> = .idle
    @Published private(set) var recentTransactions: LoadState<[TransactionsDatum]> = .idle

    /// Currency code of the administration's primary currency, once known. The
    /// summary card leads with this currency and lists the rest beneath it.
    @Published private(set) var primaryCurrencyCode: String?

    /// The range the currently-held data belongs to; results are reused when the
    /// page reappears with the same period selected.
    private var loadedRangeKey: String?
    private var loadTask: Task<Void, Never>?

    /// Loads every section for `range`. Repeated calls for a range that's already
    /// loaded are ignored unless `force` is set (pull-to-refresh, or a transaction
    /// was created/edited/deleted elsewhere in the app).
    func load(range: HomeDateRange, force: Bool = false) async {
        if !force, loadedRangeKey == range.key, summary.hasValue {
            return
        }

        // Cancel a period change or refresh that's still in flight so only the
        // latest request lands.
        loadTask?.cancel()
        let task = Task { [weak self] in
            await self?.performLoad(range: range)
            return ()
        }
        loadTask = task
        await task.value
    }

    private func performLoad(range: HomeDateRange) async {
        let rangeChanged = loadedRangeKey != range.key
        loadedRangeKey = range.key

        // Range-scoped sections show a spinner when the period changes, since the
        // values on screen belong to a different period. A same-range refresh
        // keeps them visible instead of flashing.
        if rangeChanged || !summary.hasValue { summary = .loading }
        if rangeChanged || !budgets.hasValue { budgets = .loading }
        if !accounts.hasValue { accounts = .loading }
        if !recentTransactions.hasValue { recentTransactions = .loading }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadSummary(range: range) }
            group.addTask { await self.loadAccounts() }
            group.addTask { await self.loadBudgets(range: range) }
            group.addTask { await self.loadRecentTransactions() }
        }
    }

    private func loadSummary(range: HomeDateRange) async {
        async let primaryCode = resolvePrimaryCurrencyCode()
        async let raw = fetchBasicSummary(startDate: range.apiStart, endDate: range.apiEnd)

        if let code = await primaryCode {
            primaryCurrencyCode = code
        }

        do {
            let response = try await raw
            summary = .loaded(summariesByCurrency(response))
        } catch {
            guard !Task.isCancelled else { return }
            AppLog.networkError("Failed to load dashboard summary", error)
            summary = .failed("Couldn't load this period's summary.")
        }
    }

    private func loadAccounts() async {
        do {
            let response = try await fetchAccountsPage(limit: 20, page: 1, type: "asset")
            accounts = .loaded(response.data ?? [])
        } catch {
            guard !Task.isCancelled else { return }
            AppLog.networkError("Failed to load dashboard accounts", error)
            accounts = .failed("Couldn't load accounts.")
        }
    }

    private func loadBudgets(range: HomeDateRange) async {
        do {
            let progress = try await fetchBudgetProgress(
                startDate: range.apiStart, endDate: range.apiEnd
            )
            budgets = .loaded(progress)
        } catch {
            guard !Task.isCancelled else { return }
            AppLog.networkError("Failed to load dashboard budgets", error)
            budgets = .failed("Couldn't load budgets.")
        }
    }

    private func loadRecentTransactions() async {
        do {
            let response = try await RecentTransactionsAPIProvider(limit: 5).getTransactions(page: 1)
            recentTransactions = .loaded(response.data ?? [])
        } catch {
            guard !Task.isCancelled else { return }
            AppLog.networkError("Failed to load recent transactions", error)
            recentTransactions = .failed("Couldn't load recent transactions.")
        }
    }

    /// Best-effort: the dashboard still renders without it, ordering currencies by
    /// activity instead, so a failure here is logged and swallowed.
    private func resolvePrimaryCurrencyCode() async -> String? {
        if let primaryCurrencyCode {
            return primaryCurrencyCode
        }
        do {
            return try await fetchPrimaryCurrency()?.code
        } catch {
            AppLog.networkError("Failed to load primary currency", error)
            return nil
        }
    }
}
