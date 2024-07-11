//
//  TransactionDetail.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/10.
//

import SwiftUI

struct TransactionDetail: View {
    var transaction: TransactionsTransaction
    var tags = ["Test1", "Test2", "Test3", "LongTag", "AnotherTag"]
    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Image(systemName: transactionTypeIcon(transaction.type ?? "unknown"))
                        .foregroundStyle(transactionTypeStyle(transaction.type ?? "unknown"))
                        .frame(width: 80, height: 60)
                        .font(.system(size: 60))

                    VStack(alignment: .leading) {
                        Text(transaction.description ?? "Unkown")

                        Text(transaction.type?.capitalized ?? "Unknown").foregroundStyle(
                            transactionTypeColor(type: transaction.type ?? "unknown"))
                        Spacer()
                        Text(formatDate(transaction.date ?? "Unknown") ?? "Unknown")
                            .font(.footnote)
                    }
                    Spacer()
                }
                .padding()
                //                .background(.ultraThinMaterial)
                //                .clipShape(RoundedRectangle(cornerRadius: 16))

                HStack {
                    Text("Details")
                        .fontWeight(.bold)
                        .font(.title2)
                    Spacer()
                }.padding(.horizontal)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text("Amount").font(.title3)
                            Text(
                                formatAmount(transaction.amount, symbol: transaction.currencySymbol)
                            ).font(.largeTitle).minimumScaleFactor(0.5).lineLimit(1)
                                .foregroundStyle(
                                    transactionTypeColor(type: transaction.type ?? "unknown"))
                        }
                        .padding()

                        Spacer()

                    }
                    Divider()
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text("Source").font(.title3)
                            Text(transaction.sourceName ?? "Unknown").font(.largeTitle)
                                .minimumScaleFactor(0.5).lineLimit(1)
                        }
                        .padding()

                        Spacer()

                        VStack(alignment: .leading) {
                            Text("Destination").font(.title3)
                            Text(transaction.destinationName ?? "Unknown").font(.largeTitle)
                                .minimumScaleFactor(0.5).lineLimit(1)
                        }
                        .padding()
                    }
                    Divider()
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text("Category").font(.title3)
                            Text(transaction.categoryName ?? "Unknown").font(.largeTitle)
                                .minimumScaleFactor(0.5).lineLimit(
                                    1)
                        }
                        .padding()

                        Spacer()
                        if transaction.budgetName != nil {
                            VStack(alignment: .leading) {
                                Text("Budget").font(.title3)
                                Text(transaction.budgetName ?? "Unknown").font(.largeTitle)
                                    .minimumScaleFactor(0.5).lineLimit(
                                        1)
                            }
                            .padding()
                        }

                    }
                }
                .padding(.horizontal)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18.0))

                if transaction.notes != nil {
                    HStack {
                        Text("Notes")
                            .fontWeight(.bold)
                            .font(.title2)
                        Spacer()
                    }.padding().padding(.bottom, -10)

                    VStack(alignment: .leading, spacing: 0) {
                        VStack(alignment: .leading) {
                            Text(
                                "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse accumsan justo a dolor congue fringilla. Duis non purus velit. Integer hendrerit, lacus ac volutpat ullamcorper."
                            )
                            Spacer()  // This will push the content to the top
                        }
                        .frame(maxWidth: .infinity, minHeight: 100, alignment: .topLeading)
                        .padding(.vertical)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18.0))
                }

                //                HStack {
                //                    Text("Tags")
                //                        .fontWeight(.bold)
                //                        .font(.title2)
                //                    Spacer()
                //                }.padding().padding(.bottom, -10)

                //                LazyVGrid(
                //                    columns: [GridItem(.adaptive(minimum: 50, maximum: 80))], alignment: .leading, spacing: 8
                //                ) {
                //                    ForEach(tags, id: \.self) { tag in
                //                        TagView(tag: tag)
                //                    }
                //                }
                //                .padding()
                //                //.background(.ultraThinMaterial)
                //                .clipShape(RoundedRectangle(cornerRadius: 18.0))
            }
            .padding(.horizontal, 15)
            .navigationTitle("Transaction Details")
            .toolbarTitleDisplayMode(.inline)
        }

    }

    private func formatDate(_ dateString: String) -> String? {

        guard let date = ISO8601DateFormatter().date(from: dateString)
        else {
            return "Unknown Date"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
struct TagView: View {
    let tag: String

    var body: some View {
        Text(tag)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.blue.opacity(0.2))
            .foregroundColor(.blue)
            .clipShape(Capsule())
    }
}

//#Preview {
//    TransactionDetail()
//}
