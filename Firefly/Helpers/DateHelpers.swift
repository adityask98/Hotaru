import Foundation

/// Cached formatters. `DateFormatter`/`ISO8601DateFormatter` creation is expensive
/// (noticeable when formatting per row while scrolling), and both are thread-safe
/// as long as they aren't mutated after setup — so configure once here and never
/// change them at call sites.
enum CachedFormatters {
    /// API date parameter format (yyyy-MM-dd)
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Firefly JSON date-time format (e.g. 2024-07-23T09:53:00+09:00)
    static let jsonDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    static let iso8601 = ISO8601DateFormatter()

    static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let mediumDateShortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    /// "Jul 1" — used when pairing with a same-year date that carries the year
    static let monthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    /// "Jul 1, 2026"
    static let monthDayYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }()

    /// Full weekday name ("Monday")
    static let weekdayName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
}

/// Converts Date Object to YYYY-MM-DD. If no argument is provided, it assumes today's date.
func formatDateToYYYYMMDD(_ date: Date = Date()) -> String {
    CachedFormatters.yyyyMMdd.string(from: date)
}

func formatDate(_ dateString: String?) -> String {
    guard let dateString = dateString,
          let date = CachedFormatters.iso8601.date(from: dateString) else {
        return "Unknown Date"
    }

    return CachedFormatters.mediumDate.string(from: date)
}

// 2024-07-23T09:53:00+09:00"
func formatDateFromJSON(_ date: String) -> Date {
    CachedFormatters.jsonDateTime.date(from: date) ?? Date.now
}

func formatJSONToPrettyStringDate(
    _ dateString: String, dateStyle: DateFormatter.Style = .medium,
    timeStyle: DateFormatter.Style = .short
) -> String? {
    guard let date = CachedFormatters.iso8601.date(from: dateString) else {
        return "Unknown Date"
    }
    if dateStyle == .medium, timeStyle == .short {
        return CachedFormatters.mediumDateShortTime.string(from: date)
    }
    let formatter = DateFormatter()
    formatter.dateStyle = dateStyle
    formatter.timeStyle = timeStyle
    return formatter.string(from: date)
}

/// Formats a start/end pair as a single range string, e.g. "Jul 1 – Jul 20, 2026".
/// The start date drops its year when it matches the end date's year.
func formatDateRange(_ start: Date, _ end: Date) -> String {
    let sameYear = Calendar.current.isDate(start, equalTo: end, toGranularity: .year)
    let startText = sameYear
        ? CachedFormatters.monthDay.string(from: start)
        : CachedFormatters.monthDayYear.string(from: start)
    let endText = CachedFormatters.monthDayYear.string(from: end)
    return "\(startText) – \(endText)"
}

/// Returns the first date of the current month
func currentMonthFirstDate() -> Date {
    let calendar = Calendar.current
    let now = Date()
    let components = calendar.dateComponents([.year, .month], from: now)
    return calendar.date(from: components) ?? now
}

/// Returns the last date of the current month
func currentMonthLastDate() -> Date {
    let calendar = Calendar.current
    let now = Date()
    if let range = calendar.range(of: .day, in: .month, for: now),
       let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) {
        var components = DateComponents()
        components.day = range.count - 1
        return calendar.date(byAdding: components, to: firstDay) ?? now
    }
    return now
}
