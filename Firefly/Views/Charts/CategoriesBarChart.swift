import Charts
import SwiftUI

enum TimePeriod: String, CaseIterable, Identifiable {
    case currentMonth = "Current Month"
    case last30Days = "Last 30 Days"
    case custom = "Custom"

    var id: String { rawValue }
}

struct CategoriesBarChart: View {
    var refreshTrigger = UUID()

    @State private var chartData: CategoriesInsight?
    @State private var isLoading = false
    @State private var selectedCategory: String?
    @AppStorage("categoriesBarChartPeriod") private var selectedPeriod: TimePeriod = .currentMonth
    @State private var customStartDate: Date
    @State private var customEndDate: Date

    init(refreshTrigger: UUID = UUID()) {
        self.refreshTrigger = refreshTrigger
        let calendar = Calendar.current
        let now = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        _customStartDate = State(initialValue: thirtyDaysAgo)
        _customEndDate = State(initialValue: now)
    }

    private var sortedData: CategoriesInsight {
        (chartData ?? []).sorted { abs($0.differenceFloat ?? 0) > abs($1.differenceFloat ?? 0) }
    }

    private var totalSpending: Int {
        chartData?.reduce(0) { $0 + abs($1.differenceFloat ?? 0) } ?? 0
    }

    private var displayedPeriod: String {
        if selectedPeriod == .custom {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "\(formatter.string(from: customStartDate)) - \(formatter.string(from: customEndDate))"
        }
        return selectedPeriod.rawValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spending by Category").font(.title2).fontWeight(.semibold)
                    Text(displayedPeriod).font(.footnote).foregroundStyle(.secondary)
                }

                Spacer()

                Picker("Period", selection: $selectedPeriod) {
                    ForEach(TimePeriod.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            if selectedPeriod == .custom {
                VStack(spacing: 12) {
                    DatePicker("Start Date", selection: $customStartDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    DatePicker("End Date", selection: $customEndDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(10)
            }

            if isLoading {
                ProgressView()
                    .frame(height: 300)
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
                            if let intValue = value.as(Int.self) {
                                Text(formatAxisValue(intValue))
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
                    ))
            }

            // Total spending summary
            VStack(spacing: 4) {
                HStack {
                    Text("Total Spent")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatCurrency(amount: totalSpending, code: chartData?.first?.currencyCode ?? ""))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                Text("For \(displayedPeriod.lowercased())")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)
        }
        .onChange(of: selectedCategory) { _, newValue in
            if newValue != nil {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedCategory)
        .onChange(of: selectedPeriod) { _, _ in
            Task {
                try? await getChartData()
            }
        }
        .onChange(of: customStartDate) { _, _ in
            if selectedPeriod == .custom {
                Task {
                    try? await getChartData()
                }
            }
        }
        .onChange(of: customEndDate) { _, _ in
            if selectedPeriod == .custom {
                Task {
                    try? await getChartData()
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
            }
        }
        .padding()
    }

    private func formatCurrency(amount: Int, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: abs(amount))) ?? "\(abs(amount))"
    }

    private func formatAxisValue(_ value: Int) -> String {
        if value >= 1_000 {
            return "\(value / 1_000)K"
        }
        return "\(value)"
    }

    private func percentageOfTotal(amount: Int) -> String {
        guard totalSpending > 0 else { return "0%" }
        let percentage = Double(abs(amount)) / Double(totalSpending) * 100
        return String(format: "%.1f%%", percentage)
    }

    private func getChartData() async throws {
        let calendar = Calendar.current
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let startDate: Date
        let endDate: Date

        switch selectedPeriod {
        case .currentMonth:
            startDate = calendar.date(
                from: calendar.dateComponents([.year, .month], from: now))!
            endDate = calendar.date(
                byAdding: DateComponents(month: 1, day: -1), to: startDate
            )!
        case .last30Days:
            endDate = now
            startDate = calendar.date(byAdding: .day, value: -30, to: now)!
        case .custom:
            startDate = customStartDate
            endDate = customEndDate
        }

        isLoading = true
        chartData = try await fetchCategoriesExpenseInsights(
            startDate: formatter.string(from: startDate),
            endDate: formatter.string(from: endDate)
        )
        isLoading = false
    }
}
