import SwiftUI

struct CategoriesView: View {
    @StateObject private var viewMModel = CategoriesViewModel()
    @StateObject private var insightStore = CategoriesInsightStore()
    @State private var didLoadOnce = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    if viewMModel.isLoading {
                        LoadingSpinner()
                    } else if viewMModel.categories == nil, let message = viewMModel.errorMessage {
                        ErrorStateView(message: message) {
                            Task { await viewMModel.fetchCategories() }
                        }
                        .padding(.top, 80)
                    } else if viewMModel.categories?.data?.isEmpty == true {
                        EmptyStateView(message: "No categories yet")
                    } else if let categories = viewMModel.categories {
                        Text(formatDateRange(currentMonthFirstDate(), currentMonthLastDate()))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        CategoriesBodyView(categories: categories)
                        // Lives here rather than on the dashboard, where it showed
                        // the same month's category spending as the bar chart
                        CategoriesDonut(insightStore: insightStore)
                    }
                }
            }
        }
        .task {
            guard !didLoadOnce else { return }
            didLoadOnce = true
            await viewMModel.fetchCategories()
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct CategoriesBodyView: View {
    @State var categories: Categories

    @State private var opacity = 0.1

    var body: some View {
        Group {
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], alignment: .center, spacing: 10
            ) {
                ForEach(categories.data ?? [], id: \.id) {
                    category in CategoryItem(category: category)
                }
            }
            .padding()
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.2)) {
                opacity = 1.0
            }
        }
    }
}

struct CategoryItem: View {
    var category: CategoriesDatum

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text(category.attributes?.name ?? "Unknown")
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.green)
                        .font(.caption)
                }
                .padding(.bottom, -4)
                Divider().padding(.horizontal, -16)
                let (amount, symbol) = totalAmountAndSymbol(for: category.attributes)
                Text(formatAmount(amount, symbol: symbol))
                    .font(.title)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(amountColor(for: amount))
                    .padding(.bottom, 4)
            }
            .padding(.horizontal)
            .padding(.vertical, 7)
            .frame(width: 175)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            NavigationLink(destination: CategoryDetailView(category: category)) {
                Rectangle().fill(Color.clear).contentShape(Rectangle())
            }
        }
        .contextMenu {
            if let categoryID = category.id {
                WebviewButton(url: WebviewPaths.category(categoryID))
            }
        }
    }

    private func amountColor(for amount: Decimal) -> Color {
        if amount < 0 { return .red }
        if amount > 0 { return .green }
        return .secondary
    }

    /// `spent`/`earned` report one entry per currency actually used, so summing them
    /// directly mixes currencies together for categories with multi-currency transactions.
    /// `pc_spent`/`pc_earned` are pre-converted to the administration's primary currency,
    /// so they're always safe to sum and label with `primaryCurrencySymbol`. Falls back to
    /// the raw arrays for Firefly instances that don't return the `pc_*` fields.
    private func totalAmountAndSymbol(for attributes: CategoriesAttributes?) -> (Decimal, String?) {
        func sum(_ entries: [CategoriesEarned]?) -> Decimal {
            entries?.compactMap { Decimal(string: $0.sum ?? "0") }.reduce(0, +) ?? 0
        }

        let primarySymbol = attributes?.primaryCurrencySymbol

        if attributes?.pcSpent != nil || attributes?.pcEarned != nil {
            let spentTotal = sum(attributes?.pcSpent)
            if spentTotal != 0 {
                return (spentTotal, primarySymbol)
            }
            return (sum(attributes?.pcEarned), primarySymbol)
        }

        let spentTotal = sum(attributes?.spent)
        if spentTotal != 0 {
            return (spentTotal, attributes?.spent?.first?.currencySymbol ?? primarySymbol)
        }
        let earnedTotal = sum(attributes?.earned)
        if earnedTotal != 0 {
            return (earnedTotal, attributes?.earned?.first?.currencySymbol ?? primarySymbol)
        }
        return (0, primarySymbol)
    }
}

// #Preview {
//  CategoryItem()
// }

// #Preview {
//  CategoriesView()
// }
