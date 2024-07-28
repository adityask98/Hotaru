//
//  CategoriesDonut.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/28.
//

import Charts
import SwiftUI

struct CategoriesDonut: View {
    let data: [PostCount] = [
        PostCount(category: "Xcode", count: 79), PostCount(category: "Swift", count: 73),
        PostCount(category: "SwiftUI", count: 50),
    ]
    @State private var chartData: CategoriesInsight?
    @State var isLoading = false
    var body: some View {
        if isLoading {
            LoadingSpinner()
        } else {
            VStack {
                HStack {
                    Text("Category Summary for current month").font(.headline)
                    Spacer()
                }

                Chart(chartData ?? [], id: \.id) { item in
                    SectorMark(
                        angle: .value("Amount spend", -(item.differenceFloat ?? 0)),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .cornerRadius(5)
                    .foregroundStyle(by: .value("Category", item.name ?? ""))
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
            .scaledToFit()
            .padding()
        }
    }

    private func getChartData() async throws {
        let calendar = Calendar.current
        let now = Date()

        //Start Of the Month
        let startOfMonth = calendar.date(
            from: calendar.dateComponents([.year, .month], from: now))!
        let startDateString = formatDate(startOfMonth)

        // End of the month
        let endOfMonth = calendar.date(
            byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
        let endDateString = formatDate(endOfMonth)

        func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }

        isLoading = true
        chartData = try await fetchCategoriesExpenseInsights(
            startDate: startDateString, endDate: endDateString)
        isLoading = false
    }
}

struct PostCount {
    var category: String
    var count: Int
}

//let byCategory: [PostCount] = [
//    .init(category: "Xcode", count: 79),
//    .init(category: "Swift", count: 73),
//    .init(category: "SwiftUI", count: 58),
//    .init(category: "WWDC", count: 15),
//    .init(category: "SwiftData", count: 9),
//]
//#Preview {
//    CategoriesDonut()
//}
