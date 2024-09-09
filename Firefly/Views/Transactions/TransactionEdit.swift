//
//  TransactionEdit.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/08/17.
//

import AlertToast
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
    @State private var showToast = false
    @State private var toastParams: AlertToast = AlertToast(displayMode: .alert, type: .regular)
    @State private var autocompleteLoading = true

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

                        switch transaction.type {
                        case "withdrawal":
                            //Text("WithDrawal")
                            AccountPicker(
                                title: "Source Account", accounts: accounts,
                                selectedAccountID: Binding(
                                    get: { transaction.sourceID ?? "" },
                                    set: { newValue in
                                        postTransactionData.transactions?[index].sourceID = newValue
                                        postTransactionData.transactions?[index].sourceName =
                                            accounts.first(where: { $0.id == newValue })?.name ?? ""
                                    }
                                )
                            )
                        case "deposit":
                            //Text("Deposit")
                            AccountPicker(
                                title: "Destination Account", accounts: accounts,
                                selectedAccountID: Binding(
                                    get: { transaction.destinationID ?? "" },
                                    set: { newValue in
                                        postTransactionData.transactions?[index].destinationID =
                                            newValue
                                        postTransactionData.transactions?[index].destinationName =
                                            accounts.first(where: { $0.id == newValue })?.name ?? ""
                                    }
                                )
                            )
                        case "transfer":
                            //Text("Transfer")
                            AccountPicker(
                                title: "Source Account", accounts: accounts,
                                selectedAccountID: Binding(
                                    get: { transaction.sourceID ?? "" },
                                    set: { newValue in
                                        postTransactionData.transactions?[index].sourceID = newValue
                                        postTransactionData.transactions?[index].sourceName =
                                            accounts.first(where: { $0.id == newValue })?.name ?? ""
                                    }
                                )
                            )
                            AccountPicker(
                                title: "Destination Account", accounts: accounts,
                                selectedAccountID: Binding(
                                    get: { transaction.destinationID ?? "" },
                                    set: { newValue in
                                        postTransactionData.transactions?[index].destinationID =
                                            newValue
                                        postTransactionData.transactions?[index].destinationName =
                                            accounts.first(where: { $0.id == newValue })?.name ?? ""
                                    }
                                )
                            )
                        default:
                            EmptyView()
                        }
                        if autocompleteLoading {
                            ProgressView()
                        } else {

                            Picker(
                                "Category",
                                selection: Binding(
                                    get: { transaction.categoryName ?? "" },
                                    set: { newValue in
                                        postTransactionData.transactions?[index].categoryName =
                                            newValue
                                    })
                            ) {
                                Text("Uncategorized").tag("")
                                ForEach(categories.filter { $0 != "Uncategorized" }, id: \.self) {
                                    category in
                                    Text(category).tag(category)
                                }
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
                                }), axis: .vertical
                        ).lineLimit(5)

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
            .safeAreaInset(
                edge: .bottom,
                content: {
                    MasterButton(
                        icon: "square.and.pencil", label: "Edit Transaction", fullWidth: true,
                        disabled: submitLoading,
                        action: {
                            Task {
                                do {
                                    try await submitTransaction()
                                } catch {
                                    print("ERROR EDITING: \(error)")
                                }
                            }
                        }
                    ).padding(.horizontal, 16).padding(.bottom, 8)
                }
            )
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
            .toast(isPresenting: $showToast, tapToDismiss: false) {
                toastParams
            }
        }

        .onAppear {
            loadAutocomplete()
        }
    }

    func loadAutocomplete() {
        Task {
            do {
                autocompleteLoading = true
                //Categories
                categories = try await createCategoriesAutocompleteArray()
                //Transactions (for Description Autocomplete)
                descriptions = try await fetchTransactionAutocomplete()
                //Accounts
                accounts = try await fetchAccountsAutocomplete()
                autocompleteLoading = false

            } catch {
                print("Error: \(error)")
            }
        }
    }

    func submitTransaction() async throws {
        submitLoading = true
        do {
            try await editTransaction(
                transactionData: postTransactionData, transactionID: transactionData.id!)
            toastParams = AlertToast(
                displayMode: .alert, type: .complete(Color.green), title: "Saved Successfully")
            showToast = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismiss()
            }

        } catch {
            toastParams = AlertToast(
                displayMode: .alert, type: .error(Color.red), title: "Something went wrong")
            showToast = true
            print(error)
        }
        submitLoading = false
    }
}

struct AccountPicker: View {
    let title: String
    let accounts: AutoAccounts
    @Binding var selectedAccountID: String

    var body: some View {
        Picker(title, selection: $selectedAccountID) {
            Text("Select an account").tag("")
            ForEach(accounts, id: \.id) { account in
                Text(account.name ?? "Unnamed Account")
                    .tag(account.id ?? "")
            }
        }
    }
}
