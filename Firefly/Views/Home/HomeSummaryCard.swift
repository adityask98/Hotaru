import SwiftUI

/// The dashboard's hero card: what was spent and earned over the selected period,
/// the net of the two, and — when the user actually keeps budgets — what's left to
/// spend. All of it comes pre-computed from `/v1/summary/basic`.
struct HomeSummaryCard: View {
    let state: LoadState<[CurrencySummary]>
    let primaryCurrencyCode: String?
    let onRetry: () -> Void

    var body: some View {
        HomeCard {
            switch state {
            case .idle, .loading:
                HomeSectionLoading(height: 104)
            case .failed(let message):
                HomeSectionError(message: message, onRetry: onRetry)
            case .loaded(let summaries):
                if let primary = primarySummary(in: summaries) {
                    VStack(alignment: .leading, spacing: 16) {
                        SummaryPrimaryFigures(summary: primary)

                        let others = summaries.filter { $0.currencyCode != primary.currencyCode }
                        if !others.isEmpty {
                            Divider()
                            VStack(spacing: 8) {
                                ForEach(others) { other in
                                    SummaryCurrencyRow(summary: other)
                                }
                            }
                        }
                    }
                } else {
                    Text("Nothing recorded in this period.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// The administration's primary currency when the server told us what it is,
    /// otherwise whichever currency saw the most activity (the list is already
    /// sorted that way).
    private func primarySummary(in summaries: [CurrencySummary]) -> CurrencySummary? {
        if let primaryCurrencyCode,
           let match = summaries.first(where: { $0.currencyCode == primaryCurrencyCode }) {
            return match
        }
        return summaries.first
    }
}

private struct SummaryPrimaryFigures: View {
    let summary: CurrencySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                SummaryFigure(
                    label: "Spent",
                    amount: summary.spentMagnitude,
                    summary: summary,
                    tint: .red
                )
                Divider().frame(height: 44)
                SummaryFigure(
                    label: "Earned",
                    amount: summary.earned.map(abs),
                    summary: summary,
                    tint: .green
                )
            }

            if let net = summary.net {
                Divider()
                HStack {
                    Text("Net")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(signedText(net, summary: summary))
                        .font(.headline)
                        .foregroundStyle(net < 0 ? Color.red : Color.green)
                }
            }

            // `no_available_budgets` is Firefly's way of saying the user doesn't
            // keep budgets for this period, which makes "left to spend" meaningless.
            if !summary.noAvailableBudgets, let left = summary.leftToSpend {
                HStack {
                    Text("Left to spend")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(amountText(left, summary: summary))
                        .font(.headline)
                        .foregroundStyle(left < 0 ? Color.red : Color.primary)
                }
            }
        }
    }
}

private struct SummaryFigure: View {
    let label: String
    let amount: Double?
    let summary: CurrencySummary
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .tracking(0.4)
            Text(amount.map { amountText($0, summary: summary) } ?? "—")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// One line per additional currency, when the user records in more than one.
private struct SummaryCurrencyRow: View {
    let summary: CurrencySummary

    var body: some View {
        HStack {
            Text(summary.currencyCode)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Spacer()
            if let spent = summary.spentMagnitude {
                Text("−\(amountText(spent, summary: summary))")
                    .font(.subheadline)
                    .foregroundStyle(.red)
            }
            if let earned = summary.earned, earned != 0 {
                Text("+\(amountText(abs(earned), summary: summary))")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
        }
    }
}

private func amountText(_ value: Double, summary: CurrencySummary) -> String {
    formatAmount(
        Decimal(value),
        symbol: summary.currencySymbol ?? summary.currencyCode,
        decimalPlaces: summary.currencyDecimalPlaces
    )
}

private func signedText(_ value: Double, summary: CurrencySummary) -> String {
    let formatted = amountText(abs(value), summary: summary)
    return value < 0 ? "−\(formatted)" : "+\(formatted)"
}
