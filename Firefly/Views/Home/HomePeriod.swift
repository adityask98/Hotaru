import Foundation

/// The period the whole Home dashboard is scoped to. Selected once at the page
/// level and shared by the summary card, budget bars and the category chart.
enum TimePeriod: String, CaseIterable, Identifiable {
    case currentMonth = "Current Month"
    case last30Days = "Last 30 Days"
    case custom = "Custom"

    var id: String {
        rawValue
    }
}

/// A resolved start/end pair, plus the string forms the API wants.
struct HomeDateRange: Equatable {
    let start: Date
    let end: Date

    var apiStart: String {
        formatDateToYYYYMMDD(start)
    }

    var apiEnd: String {
        formatDateToYYYYMMDD(end)
    }

    /// Identity of the range at day granularity — used to key fetches and to
    /// re-run `.task` when the user picks a different period.
    var key: String {
        "\(apiStart)|\(apiEnd)"
    }

    var label: String {
        formatDateRange(start, end)
    }
}

extension TimePeriod {
    /// Turns the selected period into concrete dates. `customStart`/`customEnd`
    /// are only consulted for `.custom`.
    func resolve(customStart: Date, customEnd: Date) -> HomeDateRange {
        switch self {
        case .currentMonth:
            return HomeDateRange(start: currentMonthFirstDate(), end: currentMonthLastDate())
        case .last30Days:
            let now = Date()
            let start = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
            return HomeDateRange(start: start, end: now)
        case .custom:
            return HomeDateRange(start: customStart, end: customEnd)
        }
    }
}
