import Charts
import SwiftUI

/// Ranges that make sense for a balance-over-time chart, each mapped to a
/// `start`/`end` pair plus the server-side grouping granularity to request.
enum AccountBalancePeriod: String, CaseIterable, Identifiable {
    case last30Days = "30 Days"
    case threeMonths = "3 Months"
    case sixMonths = "6 Months"
    case oneYear = "1 Year"
    case custom = "Custom"

    var id: String {
        rawValue
    }

    var grouping: String {
        switch self {
        case .last30Days: "1D"
        case .custom, .sixMonths, .threeMonths: "1W"
        case .oneYear: "1M"
        }
    }

    /// Days to look back from today. `nil` for `.custom`, which uses explicit dates.
    var daysBack: Int? {
        switch self {
        case .last30Days: 30
        case .threeMonths: 90
        case .sixMonths: 182
        case .oneYear: 365
        case .custom: nil
        }
    }
}

/// A single parsed balance point ready for plotting.
private struct AccountBalancePoint: Identifiable {
    let id = UUID()
    let account: String
    let date: Date
    let value: Double
    let currencyCode: String
}

struct AccountBalanceChart: View {
    let store: ChartOverviewStore

    @State private var chartData: ChartOverview?
    @State private var isLoading = false
    @State private var loadFailed = false
    @State private var selectedDate: Date?
    @AppStorage("accountsBalanceChartPeriod") private var selectedPeriod: AccountBalancePeriod = .sixMonths
    @State private var customStartDate: Date
    @State private var customEndDate: Date

    init(store: ChartOverviewStore) {
        self.store = store
        let calendar = Calendar.current
        let now = Date()
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now) ?? now
        _customStartDate = State(initialValue: sixMonthsAgo)
        _customEndDate = State(initialValue: now)
    }

    private var points: [AccountBalancePoint] {
        var result: [AccountBalancePoint] = []
        for element in chartData ?? [] {
            guard let account = element.label, let entries = element.entries else { continue }
            let currencyCode = element.currencyCode ?? ""
            for (dateString, valueString) in entries {
                guard let date = parseEntryDate(dateString), let value = Double(valueString) else { continue }
                result.append(AccountBalancePoint(
                    account: account,
                    date: date,
                    value: value,
                    currencyCode: currencyCode
                ))
            }
        }
        return result.sorted { $0.date < $1.date }
    }

    private var pointsByAccount: [String: [AccountBalancePoint]] {
        Dictionary(grouping: points, by: \.account)
    }

    private var displayedPeriod: String {
        if selectedPeriod == .custom {
            let formatter = CachedFormatters.shortDate
            return "\(formatter.string(from: customStartDate)) - \(formatter.string(from: customEndDate))"
        }
        return selectedPeriod.rawValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(displayedPeriod).font(.footnote).foregroundStyle(.secondary)
                Spacer()
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(AccountBalancePeriod.allCases) { period in
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
                    .frame(height: 260)
            } else if loadFailed, chartData == nil {
                ErrorStateView(message: "Couldn't load balance history.") {
                    Task { await loadChartData() }
                }
                .frame(height: 200)
            } else if points.isEmpty {
                EmptyStateView(icon: "chart.xyaxis.line", message: "No balance history for this period")
                    .frame(height: 200)
            } else {
                chartView
            }

            if let selectedDate {
                selectionRow(at: selectedDate)
            }
        }
        .onChange(of: selectedDate) { _, newValue in
            if newValue != nil {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedDate)
        .onChange(of: selectedPeriod) { _, _ in
            Task { await loadChartData() }
        }
        .onChange(of: customStartDate) { _, _ in
            if selectedPeriod == .custom {
                Task { await loadChartData() }
            }
        }
        .onChange(of: customEndDate) { _, _ in
            if selectedPeriod == .custom {
                Task { await loadChartData() }
            }
        }
        .onAppear {
            if chartData == nil {
                Task { await loadChartData() }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }

    private var chartView: some View {
        Chart(points) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Balance", point.value)
            )
            .foregroundStyle(by: .value("Account", point.account))
            .interpolationMethod(.catmullRom)
        }
        .chartXSelection(value: $selectedDate)
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(formatAxisValue(doubleValue))
                            .font(.caption2)
                    }
                }
            }
        }
        .chartLegend(position: .bottom, spacing: 16)
        .frame(height: 260)
    }

    @ViewBuilder
    private func selectionRow(at date: Date) -> some View {
        let nearest = pointsByAccount.compactMap { _, accountPoints in
            accountPoints.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
        }
        .sorted { $0.account < $1.account }

        if nearest.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text(CachedFormatters.mediumDate.string(from: date))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                ForEach(nearest) { point in
                    HStack {
                        Text(point.account).font(.subheadline)
                        Spacer()
                        Text(formatCurrency(amount: point.value, code: point.currencyCode))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
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

    private func parseEntryDate(_ dateString: String) -> Date? {
        CachedFormatters.iso8601WithFractionalSeconds.date(from: dateString)
            ?? CachedFormatters.iso8601.date(from: dateString)
    }

    private func formatCurrency(amount: Double, code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }

    private func formatAxisValue(_ value: Double) -> String {
        if abs(value) >= 1_000 {
            return String(format: "%.0fK", value / 1_000)
        }
        return String(format: "%.0f", value)
    }

    private func loadChartData() async {
        let calendar = Calendar.current
        let now = Date()

        let startDate: Date
        let endDate: Date
        if let daysBack = selectedPeriod.daysBack {
            endDate = now
            startDate = calendar.date(byAdding: .day, value: -daysBack, to: now) ?? now
        } else {
            startDate = customStartDate
            endDate = customEndDate
        }

        isLoading = true
        loadFailed = false
        do {
            chartData = try await store.overview(
                startDate: formatDateToYYYYMMDD(startDate),
                endDate: formatDateToYYYYMMDD(endDate),
                period: selectedPeriod.grouping,
                preselected: "assets"
            )
        } catch {
            loadFailed = true
            AppLog.networkError("Failed to load account balance chart", error)
        }
        isLoading = false
    }
}
