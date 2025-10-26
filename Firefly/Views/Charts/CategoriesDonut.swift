import Charts
import SwiftUI

struct CategoriesDonut: View {
    let data: [PostCount] = [
        PostCount(category: "Xcode", count: 79), PostCount(category: "Swift", count: 73),
        PostCount(category: "SwiftUI", count: 50),
    ]
    @State private var chartData: CategoriesInsight?
    @State var isLoading = false
    @State var selectedAngle: Int?
    @State var selectedCategory: String?
    var body: some View {
        if isLoading {
            LoadingSpinner()
        } else {
            VStack(alignment: .leading) {
                Text("Category Summary").font(.title2).fontWeight(.semibold)
                Text("Current Month").font(.footnote).foregroundStyle(.gray)

                Chart(chartData ?? [], id: \.id) { item in
                    SectorMark(
                        angle: .value("Amount spend", -(item.differenceFloat ?? 0)),
                        innerRadius: .ratio(0.618),
                        outerRadius: selectedCategory == "Eating out" ? 400 : 150,
                        angularInset: 1
                    )
                    .cornerRadius(5)
                    .foregroundStyle(by: .value("Category", item.name ?? ""))
                }
                .chartAngleSelection(value: $selectedAngle)
                .frame(width: 300, height: 300)
            }
            .onChange(of: selectedAngle) { _, newValue in
                if let newValue {
                    print(selectedAngle)
                    withAnimation {
                        getSelectedCategory(value: selectedAngle!)
                    }
                }
            }

            .onAppear {
                if chartData == nil {
                    Task {
                        do {
                            try await getChartData()
                        } catch {
                            print(error)
                        }
                    }
                }
            }
            // .scaledToFit()
            .padding()
        }
    }

    //    private func getSelectedCategory(value: Int) {
    //        var cumulativeTotal = 0
    //        let category = chartData?.first { item in
    //            cumulativeTotal += Int(item.differenceFloat!)
    //            if value <= cumulativeTotal {
    //                selectedCategory = item.name
    //                print(selectedCategory)
    //                return true
    //            }
    //            return false
    //        }
    //    }

    private func getSelectedCategory(value: Int) {
        var totalFirst = chartData?.reduce(0) { $0 + abs($1.differenceFloat ?? 0) } ?? 0
        var total = Double(totalFirst)
        let normalizedAngle = Double(value) / 360.0 * total

        var cumulativeTotal: Double = 0

        for item in chartData ?? [] {
            let itemValue = abs(Double(item.differenceFloat ?? 0))
            cumulativeTotal += itemValue
            if normalizedAngle <= cumulativeTotal {
                DispatchQueue.main.async {
                    self.selectedCategory = item.name
                    print(selectedCategory)
                }
                break
            }
        }
    }

    private func getChartData() async throws {
        let calendar = Calendar.current
        let now = Date()

        // Start Of the Month
        let startOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: now))!
        let startDateString = formatDate(startOfMonth)

        // End of the month
        let endOfMonth = calendar.date(
            byAdding: DateComponents(month: 1, day: -1), to: startOfMonth
        )!
        let endDateString = formatDate(endOfMonth)

        func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }

        isLoading = true
        chartData = try await fetchCategoriesExpenseInsights(
            startDate: startDateString, endDate: endDateString
        )
        isLoading = false
    }
}

struct PostCount {
    var category: String
    var count: Int
}

// let byCategory: [PostCount] = [
//    .init(category: "Xcode", count: 79),
//    .init(category: "Swift", count: 73),
//    .init(category: "SwiftUI", count: 58),
//    .init(category: "WWDC", count: 15),
//    .init(category: "SwiftData", count: 9),
// ]
// #Preview {
//    CategoriesDonut()
// }
