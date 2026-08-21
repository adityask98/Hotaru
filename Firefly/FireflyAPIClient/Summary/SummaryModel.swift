import Foundation

// MARK: - BasicSummaryEntry

/// One pre-computed dashboard figure from `/v1/summary/basic`.
///
/// The endpoint is multi-currency: it returns one entry per metric *per currency*,
/// keyed like `spent-in-JPY`. `key` carries the untranslated metric name, so match
/// on it rather than on `title` (which is localized to the user's Firefly locale).
struct BasicSummaryEntry: Codable {
    let key, title: String?
    let monetaryValue: Double?
    let currencyID, currencyCode, currencySymbol: String?
    let currencyDecimalPlaces: Int?
    let noAvailableBudgets: Bool?
    let valueParsed, localIcon, subTitle: String?

    enum CodingKeys: String, CodingKey {
        case key, title
        case monetaryValue = "monetary_value"
        case currencyID = "currency_id"
        case currencyCode = "currency_code"
        case currencySymbol = "currency_symbol"
        case currencyDecimalPlaces = "currency_decimal_places"
        case noAvailableBudgets = "no_available_budgets"
        case valueParsed = "value_parsed"
        case localIcon = "local_icon"
        case subTitle = "sub_title"
    }

    /// Hand-written because the numeric fields aren't reliably numeric: the spec
    /// types `monetary_value` as a double, but real instances return it as a
    /// string (`"1234.56"`) for at least some keys, which fails synthesized
    /// decoding for the whole response.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decodeIfPresent(String.self, forKey: .key)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        monetaryValue = try container.decodeFlexibleDouble(forKey: .monetaryValue)
        currencyID = try container.decodeIfPresent(String.self, forKey: .currencyID)
        currencyCode = try container.decodeIfPresent(String.self, forKey: .currencyCode)
        currencySymbol = try container.decodeIfPresent(String.self, forKey: .currencySymbol)
        currencyDecimalPlaces = try container.decodeFlexibleInt(forKey: .currencyDecimalPlaces)
        noAvailableBudgets = try container.decodeIfPresent(Bool.self, forKey: .noAvailableBudgets)
        valueParsed = try container.decodeIfPresent(String.self, forKey: .valueParsed)
        localIcon = try container.decodeIfPresent(String.self, forKey: .localIcon)
        subTitle = try container.decodeIfPresent(String.self, forKey: .subTitle)
    }
}

private extension KeyedDecodingContainer {
    /// Decodes a number that may arrive as either a JSON number or a string.
    func decodeFlexibleDouble(forKey key: Key) throws -> Double? {
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return value
        }
        return try decodeIfPresent(String.self, forKey: key).flatMap(Double.init)
    }

    func decodeFlexibleInt(forKey key: Key) throws -> Int? {
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        return try decodeIfPresent(String.self, forKey: key).flatMap(Int.init)
    }
}

/// The raw response shape: a dictionary keyed by `<metric>-in-<currency code>`.
typealias BasicSummary = [String: BasicSummaryEntry]

// MARK: - SummaryMetric

/// The metric half of a summary key (`spent-in-JPY` -> `.spent`).
enum SummaryMetric: String {
    case balance
    case spent
    case earned
    case netWorth = "net-worth"
    case billsPaid = "bills-paid"
    case billsUnpaid = "bills-unpaid"
    case leftToSpend = "left-to-spend"
}

// MARK: - CurrencySummary

/// All of one currency's summary figures, gathered from the flat key/value response.
struct CurrencySummary: Identifiable {
    let currencyCode: String
    let currencySymbol: String?
    let currencyDecimalPlaces: Int?
    let balance, spent, earned, netWorth: Double?
    let billsPaid, billsUnpaid, leftToSpend: Double?
    /// True when the user has no available budgets for the period, in which case
    /// "left to spend" is meaningless and shouldn't be shown.
    let noAvailableBudgets: Bool

    var id: String {
        currencyCode
    }

    /// Spent comes back negative from Firefly; report it as a positive magnitude.
    var spentMagnitude: Double? {
        spent.map(abs)
    }

    /// Earned minus spent for the period. Positive means the user came out ahead.
    var net: Double? {
        guard earned != nil || spent != nil else { return nil }
        return (earned ?? 0) - abs(spent ?? 0)
    }

    /// How busy this currency was over the period, used to rank currencies when
    /// the primary one can't be determined.
    var activity: Double {
        abs(spent ?? 0) + abs(earned ?? 0)
    }
}

// MARK: - Grouping

/// Regroups the flat `<metric>-in-<currency>` response into one entry per currency.
///
/// Currencies are ordered by how much activity they saw over the period, so the
/// caller can fall back to `first` when the primary currency isn't known.
func summariesByCurrency(_ summary: BasicSummary) -> [CurrencySummary] {
    var entriesByCurrency: [String: [SummaryMetric: BasicSummaryEntry]] = [:]

    for entry in summary.values {
        guard let key = entry.key,
              let separator = key.range(of: "-in-", options: .backwards),
              let metric = SummaryMetric(rawValue: String(key[key.startIndex..<separator.lowerBound])) else { continue }

        // Prefer the currency the entry reports over the one parsed out of the key
        let code = entry.currencyCode ?? String(key[separator.upperBound...])
        entriesByCurrency[code, default: [:]][metric] = entry
    }

    return entriesByCurrency.map { code, metrics in
        // Every entry of a currency carries the same currency metadata, so any of
        // them can supply the symbol/decimals.
        let anyEntry = metrics.values.first
        return CurrencySummary(
            currencyCode: code,
            currencySymbol: anyEntry?.currencySymbol,
            currencyDecimalPlaces: anyEntry?.currencyDecimalPlaces,
            balance: metrics[.balance]?.monetaryValue,
            spent: metrics[.spent]?.monetaryValue,
            earned: metrics[.earned]?.monetaryValue,
            netWorth: metrics[.netWorth]?.monetaryValue,
            billsPaid: metrics[.billsPaid]?.monetaryValue,
            billsUnpaid: metrics[.billsUnpaid]?.monetaryValue,
            leftToSpend: metrics[.leftToSpend]?.monetaryValue,
            noAvailableBudgets: metrics.values.contains { $0.noAvailableBudgets == true }
        )
    }
    .sorted { $0.activity > $1.activity }
}
