import SwiftUI

struct CategoriesView: View {
    @StateObject private var viewMModel = CategoriesViewModel()
    @State private var didLoadOnce = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    if viewMModel.isLoading {
                        LoadingSpinner()
                    } else if let categories = viewMModel.categories {
                        CategoriesBodyView(categories: categories)
                    }
                }
            }
        }
        .task {
            guard !didLoadOnce else { return }
            didLoadOnce = true
            viewMModel.fetchCategories()
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
                        .font(.system(size: 12))
                }
                .padding(.bottom, -4)
                Divider().padding(.horizontal, -16)
                let (amount, symbol) = totalAmountAndSymbol(for: category.attributes)
                // Use your formatter helper — you already have: formatAmount(_:symbol:)
                Text(formatAmount(amount, symbol: symbol))
                    .font(.title)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(amount < 0 ? .red : .primary)
                HStack {
                    Spacer()
                    Text(formatDate(category.attributes?.updatedAt))
                        .lineLimit(1)
                        .font(.caption2)
                        .fontWeight(.ultraLight)
                }
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
    }

    private func totalAmountAndSymbol(for attributes: CategoriesAttributes?) -> (Decimal, String?) {
        // Sum the spent values
        let spentTotal =
            attributes?.spent?.compactMap { Decimal(string: $0.sum ?? "0") }.reduce(0, +) ?? 0
        // Sum the earned values
        let earnedTotal =
            attributes?.earned?.compactMap { Decimal(string: $0.sum ?? "0") }.reduce(0, +) ?? 0
        // Prefer spent if not zero, otherwise earned, otherwise zero.
        if spentTotal != 0 {
            let symbol = attributes?.spent?.first?.currencySymbol ?? attributes?.nativeCurrencySymbol
            return (spentTotal, symbol)
        } else if earnedTotal != 0 {
            let symbol = attributes?.earned?.first?.currencySymbol ?? attributes?.nativeCurrencySymbol
            return (earnedTotal, symbol)
        } else {
            return (0, attributes?.nativeCurrencySymbol)
        }
    }
}

// #Preview {
//  CategoryItem()
// }

// #Preview {
//  CategoriesView()
// }
