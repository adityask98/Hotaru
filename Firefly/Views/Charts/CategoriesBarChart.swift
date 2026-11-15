import Charts
import SwiftUI

/// Ranked spending per category for a date range. The range is supplied by the
/// screen (the Home dashboard's page-level period control) rather than owned here,
/// so every section of that page reports on the same period.
struct CategoriesBarChart: View {
    let startDate: Date
    let endDate: Date
    let insightStore: CategoriesInsightStore
    var refreshTrigger = UUID()

    @State private var chartData: CategoriesInsight?
    @State private var isLoading = false
    @State private var loadFailed = false
    @State private var selectedCategory: String?

    private var sortedData: CategoriesInsight {
        (chartData ?? []).sorted { abs($0.differenceFloat ?? 0) > abs($1.differenceFloat ?? 0) }
    }

    private var totalSpending: Double {
        chartData?.reduce(0) { $0 + abs($1.differenceFloat ?? 0) } ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isLoading, chartData == nil {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
            } else if loadFailed, chartData == nil {
                ErrorStateView(message: "Couldn't load spending data.") {
                    Task { await loadChartData() }
                }
                .frame(height: 200)
            } else if sortedData.isEmpty {
                EmptyStateView(icon: "chart.bar", message: "No spending in this period")
            } else {
                Chart(sortedData, id: \.id) { item in
                    BarMark(
                        x: .value("Amount", abs(item.differenceFloat ?? 0)),
                        y: .value("Category", item.name ?? "")
                    )
                    .cornerRadius(4)
                    .foregroundStyle(by: .value("Category", item.name ?? ""))
                    .opacity(selectedCategory == nil || selectedCategory == item.name ? 1.0 : 0.4)
                    .annotation(position: .trailing, alignment: .leading, spacing: 4) {
                        if selectedCategory == nil || selectedCategory == item.name {
                            Text(formatCurrency(amount: item.differenceFloat ?? 0, code: item.currencyCode ?? ""))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .chartYSelection(value: $selectedCategory)
                .chartLegend(.hidden)
                .chartXAxis {
                    AxisMarks(position: .bottom) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(formatAxisValue(doubleValue))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisValueLabel()
                    }
                }
                .frame(height: CGFloat(sortedData.count * 44 + 40))
            }

            if let selected = selectedCategory,
               let item = chartData?.first(where: { $0.name == selected }) {
                HStack {
                    Text(selected)
                        .font(.headline)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(formatCurrency(amount: item.differenceFloat ?? 0, code: item.currencyCode ?? ""))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(percentageOfTotal(amount: item.differenceFloat ?? 0))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(10)
                .transition(
                    .asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity.combined(with: .scale(scale: 0.95))
                    )
                )
            }
        }
        // Dim rather than blank while a new period loads, so the chart doesn't
        // present the previous period's bars as if they were the new selection
        .opacity(isLoading ? 0.4 : 1)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .onChange(of: selectedCategory) { _, newValue in
            if newValue != nil {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedCategory)
        .onChange(of: refreshTrigger) { _, _ in
            Task {
                await loadChartData()
            }
        }
        .task(id: rangeKey) {
            await loadChartData()
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = nil
            }
        }
    }

    /// Identity of the requested range, so the fetch re-runs when the screen's
    /// period changes but not on every unrelated redraw.
    private var rangeKey: String {
        "\(formatDateToYYYYMMDD(startDate))|\(formatDateToYYYYMMDD(endDate))"
    }

    private func formatCurrency(amount: Double, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: abs(amount))) ?? "\(abs(amount))"
    }

    private func formatAxisValue(_ value: Double) -> String {
        if value >= 1_000 {
            return String(format: "%.0fK", value / 1_000)
        }
        return String(format: "%.0f", value)
    }

    private func percentageOfTotal(amount: Double) -> String {
        guard totalSpending > 0 else { return "0%" }
        let percentage = abs(amount) / totalSpending * 100
        return String(format: "%.1f%%", percentage)
    }

    private func loadChartData() async {
        isLoading = true
        loadFailed = false
        do {
            chartData = try await insightStore.insights(
                startDate: formatDateToYYYYMMDD(startDate),
                endDate: formatDateToYYYYMMDD(endDate)
            )
        } catch {
            loadFailed = true
            AppLog.networkError("Failed to load categories bar chart", error)
        }
        isLoading = false
    }
}
