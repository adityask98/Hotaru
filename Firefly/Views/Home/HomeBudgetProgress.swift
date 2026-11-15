import SwiftUI

/// Spent-vs-limit bars for the selected period, one per budget that has a limit.
///
/// Renders nothing at all when the user keeps no budgets — an empty card on every
/// load would just be noise for the many Firefly instances that don't use them.
struct HomeBudgetProgress: View {
    let state: LoadState<[BudgetProgress]>
    let onRetry: () -> Void

    var body: some View {
        if shouldShow {
            VStack(alignment: .leading, spacing: 12) {
                HomeSectionHeader(title: "Budgets") {
                    NavigationLink("See all") {
                        BudgetsView()
                    }
                }

                switch state {
                case .idle, .loading:
                    HomeCard { HomeSectionLoading() }
                case .failed(let message):
                    HomeCard { HomeSectionError(message: message, onRetry: onRetry) }
                case .loaded(let budgets):
                    HomeCard {
                        VStack(spacing: 18) {
                            ForEach(budgets) { budget in
                                BudgetProgressRow(budget: budget)
                            }
                        }
                    }
                }
            }
        }
    }

    private var shouldShow: Bool {
        if case .loaded(let budgets) = state {
            return !budgets.isEmpty
        }
        return true
    }
}

private struct BudgetProgressRow: View {
    let budget: BudgetProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(budget.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Spacer()
                Text("\(amount(budget.spent)) / \(amount(budget.limit))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            ProgressView(value: budget.fraction)
                .tint(budget.isOverBudget ? .red : .green)

            Text(remainderText)
                .font(.caption)
                .foregroundStyle(budget.isOverBudget ? Color.red : Color.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(budget.name), \(amount(budget.spent)) of \(amount(budget.limit)) spent")
    }

    private var remainderText: String {
        budget.isOverBudget
            ? "\(amount(-budget.remaining)) over budget"
            : "\(amount(budget.remaining)) left"
    }

    private func amount(_ value: Decimal) -> String {
        formatAmount(
            value,
            symbol: budget.currencySymbol,
            decimalPlaces: budget.currencyDecimalPlaces
        )
    }
}
