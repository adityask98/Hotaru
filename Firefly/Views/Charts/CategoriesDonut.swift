import Charts
import SwiftUI

struct CategoriesDonut: View {
    var refreshTrigger = UUID()

    @State private var chartData: CategoriesInsight?
    @State private var isLoading = false
    @State private var selectedAngle: Int?
    @State private var selectedCategory: CategoriesInsightElement?

    private var totalSpending: Int {
        chartData?.reduce(0) { $0 + abs($1.differenceFloat ?? 0) } ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category Summary").font(.title2).fontWeight(.semibold)
            Text("Current Month").font(.footnote).foregroundStyle(.secondary)

            if isLoading {
                ProgressView()
                    .frame(width: 280, height: 280)
            } else {
                ZStack {
                    Chart(chartData ?? [], id: \.id) { item in
                        SectorMark(
                            angle: .value("Amount", abs(item.differenceFloat ?? 0)),
                            innerRadius: .ratio(0.618),
                            outerRadius: selectedCategory?.id == item.id
                                ? .ratio(1.0)
                                : .ratio(0.9),
                            angularInset: 1.5
                        )
                        .cornerRadius(6)
                        .foregroundStyle(by: .value("Category", item.name ?? ""))
                        .opacity(selectedCategory == nil || selectedCategory?.id == item.id ? 1.0 : 0.4)
                    }
                    .chartAngleSelection(value: $selectedAngle)
                    .chartLegend(position: .bottom, spacing: 16)
                    .frame(width: 280, height: 280)

                    // Center annotation
                    VStack(spacing: 4) {
                        if let selected = selectedCategory {
                            Text(selected.name ?? "")
                                .font(.headline)
                                .lineLimit(1)
                            Text(formatCurrency(
                                amount: selected.differenceFloat ?? 0,
                                code: selected.currencyCode ?? ""
                            ))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                            Text(percentageOfTotal(amount: selected.differenceFloat ?? 0))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Total")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(formatCurrency(amount: totalSpending, code: chartData?.first?.currencyCode ?? ""))
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    .frame(width: 120)
                    .multilineTextAlignment(.center)
                }
            }
        }
        .onChange(of: selectedAngle) { _, newValue in
            withAnimation(.easeInOut(duration: 0.2)) {
                if let newValue {
                    selectedCategory = findCategory(for: newValue)
                } else {
                    selectedCategory = nil
                }
            }
        }
        .onChange(of: refreshTrigger) { _, _ in
            Task {
                try? await getChartData()
            }
        }
        .onAppear {
            if chartData == nil {
                Task {
                    try? await getChartData()
                }
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = nil
                selectedAngle = nil
            }
        }
        .padding()
    }

    private func findCategory(for angle: Int) -> CategoriesInsightElement? {
        let total = Double(totalSpending)
        guard total > 0 else { return nil }

        let normalizedValue = Double(angle) / 360.0 * total
        var cumulativeTotal: Double = 0

        for item in chartData ?? [] {
            let itemValue = abs(Double(item.differenceFloat ?? 0))
            cumulativeTotal += itemValue
            if normalizedValue <= cumulativeTotal {
                return item
            }
        }
        return nil
    }

    private func formatCurrency(amount: Int, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: abs(amount))) ?? "\(abs(amount))"
    }

    private func percentageOfTotal(amount: Int) -> String {
        guard totalSpending > 0 else { return "0%" }
        let percentage = Double(abs(amount)) / Double(totalSpending) * 100
        return String(format: "%.1f%%", percentage)
    }

    private func getChartData() async throws {
        let calendar = Calendar.current
        let now = Date()

        let startOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(
            byAdding: DateComponents(month: 1, day: -1), to: startOfMonth
        )!

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        isLoading = true
        chartData = try await fetchCategoriesExpenseInsights(
            startDate: formatter.string(from: startOfMonth),
            endDate: formatter.string(from: endOfMonth)
        )
        isLoading = false
    }
}
