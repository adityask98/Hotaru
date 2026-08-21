import SwiftUI

/// The dashboard (the app's first tab). One period selection drives every section:
/// the summary card, budget bars and the category chart all read the same range.
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var insightStore = CategoriesInsightStore()
    @EnvironmentObject var menuViewModel: MenuViewModel

    @AppStorage("homeDashboardPeriod") private var selectedPeriod: TimePeriod = .currentMonth
    @State private var customStartDate = Calendar.current.date(
        byAdding: .day, value: -30, to: Date()
    ) ?? Date()
    @State private var customEndDate = Date()
    @State private var refreshTrigger = UUID()

    private var range: HomeDateRange {
        selectedPeriod.resolve(customStart: customStartDate, customEnd: customEndDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    periodControl

                    HomeSummaryCard(
                        state: viewModel.summary,
                        primaryCurrencyCode: viewModel.primaryCurrencyCode,
                        onRetry: reload
                    )

                    HomeAccountsStrip(state: viewModel.accounts, onRetry: reload)

                    HomeBudgetProgress(state: viewModel.budgets, onRetry: reload)

                    categoriesSection

                    HomeRecentTransactions(state: viewModel.recentTransactions, onRetry: reload)
                }
                .padding(.top, 4)
            }
            // Keeps the last section clear of the floating add button
            .contentMargins(.bottom, 96, for: .scrollContent)
            .refreshable {
                await refreshAll()
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        CategoriesView()
                    } label: {
                        Image(systemName: "tray.full")
                    }
                    .accessibilityLabel("Categories")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        BudgetsView()
                    } label: {
                        Image(systemName: "chart.line.text.clipboard")
                    }
                    .accessibilityLabel("Budgets")
                }
            }
            // Re-runs whenever the selected period resolves to a different range
            .task(id: range.key) {
                await viewModel.load(range: range)
            }
            .onReceive(
                NotificationCenter.default.publisher(for: AppNotifications.transactionCreated)
            ) { _ in
                Task { await refreshAll() }
            }
            .onReceive(
                NotificationCenter.default.publisher(for: AppNotifications.transactionUpdated)
            ) { _ in
                Task { await refreshAll() }
            }
            .onReceive(
                NotificationCenter.default.publisher(for: AppNotifications.transactionDeleted)
            ) { _ in
                Task { await refreshAll() }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            FloatingButton(action: {
                menuViewModel.openTransactionSheet()
            })
        }
        .background(.ultraThinMaterial)
    }

    /// The page's single period control — the menu picks the period, and its label
    /// spells out the dates that period resolves to.
    private var periodControl: some View {
        VStack(alignment: .leading, spacing: 12) {
            Menu {
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                    Text(range.label)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(.ultraThinMaterial, in: Capsule())
            }
            .accessibilityLabel("Period, \(range.label)")

            if selectedPeriod == .custom {
                VStack(spacing: 10) {
                    DatePicker("Start", selection: $customStartDate, displayedComponents: .date)
                    DatePicker("End", selection: $customEndDate, displayedComponents: .date)
                }
                .datePickerStyle(.compact)
                .padding(14)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(.horizontal)
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HomeSectionHeader(title: "Spending by Category") {
                NavigationLink("See all") {
                    CategoriesView()
                }
            }
            CategoriesBarChart(
                startDate: range.start,
                endDate: range.end,
                insightStore: insightStore,
                refreshTrigger: refreshTrigger
            )
            .padding(.horizontal)
        }
    }

    private func reload() {
        Task { await viewModel.load(range: range, force: true) }
    }

    private func refreshAll() async {
        insightStore.invalidate()
        refreshTrigger = UUID()
        await viewModel.load(range: range, force: true)
    }
}
