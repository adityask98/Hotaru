//
//  BalanceCharts.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/28.
//

import Charts
import SwiftUI

struct AccountBalanceData: Codable {
    var accountName: String
    var entries: [Entry]
}

struct Entry: Codable {
    var date: Date
    var value: Double
}

struct BalanceCharts: View {
    @State private var chartData: ChartOverview?
    @State var accountBalances: [AccountBalanceData] = []
    @State var chartCopyData: [(Date, Double)] = []
    @State var isLoading = false
    var body: some View {
        VStack {
            if isLoading {
                LoadingSpinner()
            } else {
                //                Chart(accountBalances) { balance in
                //                    ForEach(balance.entries, id: \.date) {entry in
                //                        LineMark(x: .value("Date", entry.date), y: .value("Value", entry.value))
                //                    }
                ////                    LineMark(
                ////                        x: .value("Date", balance.date),
                ////                        y: .value("Balance", balance.balance)
                ////                    )
                ////                    .foregroundStyle(by: .value("Account", balance.account))
                //                }
                //                .chartXAxis {
                //                    AxisMarks(values: .stride(by: .month)) { _ in
                //                        AxisGridLine()
                //                        AxisTick()
                //                        AxisValueLabel(format: .dateTime.month())
                //                    }
                //                }
                //                .chartYAxis {
                //                    AxisMarks(position: .leading)
                //                }
                //                .chartLegend(position: .bottom, spacing: 20)
                //                .chartYScale(domain: 0...400000)
                //                .frame(height: 300)
                //                .padding()
                Text("Loaded")
            }
        }
        .onAppear {
//            if chartData == nil {
                Task {
                    do {
                        isLoading = true
                        chartData = try await fetchChartOverview()
                        copyChartData(chartData: chartData!)
                        print(chartData)
                        //                        ForEach(
                        //                            Array((chartData ?? []).enumerated()),
                        //                            id: \.offset
                        //                        ) { index, element in
                        //                            let accountName = element.label
                        //
                        //                            var entries: [Entry] = []
                        //
                        //                            entries = extractEntries(data: element.entries!)
                        //                            //                            for (dateString, valueString) in element.entries ?? [:] {
                        //                            //                                let dateFormatter = ISO8601DateFormatter()
                        //                            //                                dateFormatter.formatOptions = [
                        //                            //                                    .withInternetDateTime, .withFractionalSeconds,
                        //                            //                                ]
                        //                            //                                if let date = dateFormatter.date(from: dateString) {
                        //                            //                                        // Convert the value to a Double
                        //                            //                                        if let value = Double(valueString) {
                        //                            //                                            // Create an Entry object and add it to the entries array
                        //                            //                                            let entry = Entry(date: date, value: value)
                        //                            //                                            entries.append(entry)
                        //                            //                                        }
                        //                            //                                    }
                        //                            //
                        //                            //                            }
                        //
                        //                        }
                        isLoading = false
                    } catch {
                        print(error)
                    }
                }
            //}
        }
    }

    private func copyChartData(chartData: ChartOverview) {
        for (index, element) in (chartData).enumerated() {
            let accountName = element.label
            let entries: [Entry] = extractEntries(data: element.entries!)
            accountBalances.append(AccountBalanceData(accountName: accountName!, entries: entries))
        }

    }

    private func extractEntries(data: [String: String]) -> [Entry] {
        var entries: [Entry] = []

        for (dateString, valueString) in data {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let date = dateFormatter.date(from: dateString)
            let value = Double(valueString)
            entries.append(Entry(date: date!, value: value!))

        }

        return entries
    }
}

//#Preview {
//    BalanceCharts()
//}
