//
//  TransactionCreateNew.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/09/29.
//

import SwiftUI

struct TransactionCreateNew: View {
    @Environment(\.dismiss) var dismiss
    @Binding var shouldRefresh: Bool?

    @State private var transactionData: PostTransaction = defaultTransactionData()

    var transactionTypes = [
        TransactionTypes.withdrawals.rawValue.capitalized,
        TransactionTypes.deposits.rawValue.capitalized,
        TransactionTypes.transfers.rawValue.capitalized,
    ]

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    //if isSplitTransaction(transactionData) {
                    TextField(
                        "Group Title",
                        text: Binding(
                            get: { transactionData.groupTitle ?? "" },
                            set: { newValue in
                                transactionData.groupTitle = newValue
                                print(transactionData.groupTitle)
                            }))
                    //}
                    Picker(
                        "",
                        selection: Binding(
                            get: {
                                transactionData.transactions![0].type
                            },
                            set: { newValue in
                                transactionData.transactions![0].type = newValue
                            })
                    ) {
                        ForEach(transactionTypes, id: \.self) {
                            Text($0)
                        }
                    }.pickerStyle(.segmented)
                    TabView {
                        TransactionInputSingleton(
                            transactionSingleton: Binding(
                                get: { transactionData.transactions![0] },
                                set: { newValue in
                                    transactionData.transactions![0] = newValue
                                }
                            ))
                    }.tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)).frame(
                        height: 500)
                }
            }
            .safeAreaInset(edge: .bottom) {
                MasterButton(icon: "plus.circle.fill", label: "Add Transaction", fullWidth: true) {
                    print(transactionData)
                }
            }
        }
    }
}

struct TransactionInputSingleton: View {

    var transactionTypes = [
        TransactionTypes.withdrawals.rawValue.capitalized,
        TransactionTypes.deposits.rawValue.capitalized,
        TransactionTypes.transfers.rawValue.capitalized,
    ]

    @Binding var transactionSingleton: PostTransactionElement

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker(
                    "Type",
                    selection: Binding(
                        get: {
                            transactionSingleton.type ?? transactionTypes[0]
                        },
                        set: { newValue in
                            transactionSingleton.type = newValue
                            print(transactionSingleton.type ?? "")
                            print(newValue)
                        }
                    )
                ) {
                    ForEach(TransactionType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }.pickerStyle(.segmented)

                TextField(
                    "Amount",
                    text: Binding(
                        get: {
                            transactionSingleton.amount ?? ""
                        },
                        set: { newValue in
                            print(newValue)
                            transactionSingleton.amount = newValue
                        })
                )
                .font(.largeTitle)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)

                DatePicker(
                    "Date",
                    selection:
                        Binding(
                            get: { Date() },
                            set: { newValue in
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                                transactionSingleton.date = dateFormatter.string(from: newValue)
                            }),
                    displayedComponents: [.date]
                )
                .datePickerStyle(CompactDatePickerStyle())
            }
            .padding()
        }
    }

}

//#Preview {
//    TransactionCreateNew()
//}
