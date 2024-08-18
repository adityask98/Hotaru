//
//  TransactionEdit.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/08/17.
//

import SwiftUI

struct TransactionEdit: View {
    @Environment(\.dismiss) var dismiss
    @State var transactionData: TransactionsDatum
    @State var postTransactionData: PostTransaction

    //Autocomplete
    @State private var categories: [String] = ["Default"]
    @State private var descriptions: AutoTransactions = AutoTransactions()
    @State private var accounts: AutoAccounts = AutoAccounts()
    
    //Toasts and UIControllers
    @State private var submitLoading = false

    init(transactionData: TransactionsDatum) {
        self._transactionData = State(initialValue: transactionData)
        self._postTransactionData = State(
            initialValue: PostTransaction(
                errorIfDuplicateHash: true, applyRules: true, fireWebhooks: true,
                groupTitle: transactionData.attributes?.groupTitle,
                transactions: transactionData.attributes?.transactions?.map { transaction in
                    PostTransactionElement(
                        type: transaction.type?.lowercased(),
                        date: transaction.date,
                        amount: formatAmountForTextField(
                            transaction.amount ?? "0",
                            decimalPlace: transaction.currencyDecimalPlaces ?? 0),
                        description: transaction.description,
                        categoryID: transaction.categoryID,
                        categoryName: transaction.categoryName,
                        sourceID: transaction.sourceID,
                        sourceName: transaction.sourceName,
                        destinationID: transaction.destinationID,
                        destinationName: transaction.destinationName,
                        notes: transaction.notes
                    )
                }
            ))
    }

    var transactionTypes = ["Expenses", "Income", "Transfer"]

    var body: some View {
        NavigationView {
            Form {
                if isSplitTransaction(transactionData) {
                    Section("Group Title") {
                        TextField(
                            "Group Title",
                            text: Binding(
                                get: {
                                    postTransactionData.groupTitle ?? ""
                                },
                                set: { newValue in
                                    postTransactionData.groupTitle = newValue
                                }))
                    }

                }

                VStack {
                    Picker("", selection: $transactionData.type.animation()) {
                        ForEach(transactionTypes, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(.segmented)
                    HStack {
                        Spacer()
                        TextField(
                            "Amount",
                            text: Binding(
                                get: {
                                    postTransactionData.transactions?.first?.amount ?? ""
                                },
                                set: { newValue in
                                    if var transaction = transactionData.attributes?.transactions?
                                        .first
                                    {
                                        transaction.amount = newValue
                                        transactionData.attributes?.transactions?[0] = transaction
                                    }
                                })
                        )
                        .font(.largeTitle)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding(.vertical, 20)

                    HStack {
                        Spacer()
                        //DatePicker("", selection: $date).pickerStyle(.inline).labelsHidden()
                        Spacer()
                    }
                }

                ForEach(Array(postTransactionData.transactions!.enumerated()), id: \.offset) {
                    index, transaction in

                    Section {
                        DescriptionInput(
                            bindingText: Binding(
                                get: { transaction.description ?? "" },
                                set: { newValue in
                                    postTransactionData.transactions?[index].description =
                                        newValue
                                }), transactionsAutocomplete: descriptions)
                        TextField(
                            "Amount",
                            text: Binding(
                                get: {
                                    transaction.amount ?? ""
                                },
                                set: { newValue in
                                    let amount = "\(newValue)"
                                    postTransactionData.transactions?[index].amount = amount
                                })
                        ).keyboardType(.decimalPad)
                        Picker(
                            "Category",
                            selection: Binding(
                                get: { transaction.categoryName ?? "" },
                                set: { newValue in
                                    postTransactionData.transactions?[index].categoryName = newValue
                                })
                        ) {
                            Text("Uncategorized").tag("")
                            ForEach(categories.filter { $0 != "Uncategorized" }, id: \.self) {
                                category in
                                Text(category).tag(category)
                            }
                        }
                        DatePicker(
                            "Date",
                            selection: Binding(
                                get: {
                                    formatDateFromJSON(transaction.date ?? "")
                                },
                                set: { newValue in
                                    let dateFormatter = DateFormatter()
                                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                                    postTransactionData.transactions?[index].date =
                                        dateFormatter.string(from: newValue)
                                }
                            )
                        ).datePickerStyle(.compact)
                        TextField(
                            "Notes",
                            text: Binding(
                                get: {
                                    transaction.notes ?? ""
                                },
                                set: { newValue in
                                    postTransactionData.transactions?[index].notes = newValue
                                }))

                        //TODO: add category button
                        //TODO: budget select

                    } header: {
                        HStack {
                            Text("Details")
                            Spacer()
                            if isSplitTransaction(postTransactionData) {
                                Text("Split #\(index + 1)")
                            }
                        }
                    }

                }

            }
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
        
        .onAppear {
            loadAutocomplete()
        }
    }

    func loadAutocomplete() {
        Task {
            do {
                //Categories
                categories = try await createCategoriesAutocompleteArray()
                //Transactions (for Description Autocomplete)
                descriptions = try await fetchTransactionAutocomplete()
                //Accounts
                accounts = try await fetchAccountsAutocomplete()

            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    func submitTransaction() async throws {
        
    }
}
