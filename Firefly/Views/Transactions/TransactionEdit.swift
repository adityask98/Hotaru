import AlertToast
import SwiftUI

struct TransactionEdit: View {
    @Environment(\.dismiss) var dismiss
    @State var transactionData: TransactionsDatum
    @State var postTransactionData: PostTransaction

    // Autocomplete
    @State private var categories = ["Default"]
    @State private var descriptions = AutoTransactions()
    @State private var accounts = AutoAccounts()
    @State private var budgets = AutoBudget()

    // Toasts and UIControllers
    @State private var submitLoading = false
    @State private var showToast = false
    @State private var toastParams = AlertToast(displayMode: .alert, type: .regular)
    @State private var autocompleteLoading = true

    /// The location marker each split arrived with, keyed by split index, held aside while the user
    /// edits so they never see it in the notes field — and re-applied on save so editing a
    /// transaction doesn't silently discard where it happened. Splits can't be added or removed here,
    /// so the indices stay aligned with `postTransactionData.transactions`.
    @State private var preservedLocations: [TransactionLocation?]

    init(transactionData: TransactionsDatum) {
        _transactionData = State(initialValue: transactionData)
        _preservedLocations = State(
            initialValue: (transactionData.attributes?.transactions ?? []).map {
                TransactionLocation.parse(from: $0.notes)
            }
        )
        _postTransactionData = State(
            initialValue: PostTransaction(
                errorIfDuplicateHash: true, applyRules: true, fireWebhooks: true,
                groupTitle: transactionData.attributes?.groupTitle,
                transactions: transactionData.attributes?.transactions?.map { transaction in
                    let native = TransactionLocation.fromNativeFields(transaction)
                    return PostTransactionElement(
                        type: transaction.type?.lowercased(),
                        date: transaction.date,
                        amount: formatAmountForTextField(
                            transaction.amount ?? "0",
                            decimalPlace: transaction.currencyDecimalPlaces ?? 0
                        ),
                        description: transaction.description,
                        categoryID: transaction.categoryID,
                        categoryName: transaction.categoryName,
                        sourceID: transaction.sourceID,
                        sourceName: transaction.sourceName,
                        destinationID: transaction.destinationID,
                        destinationName: transaction.destinationName,
                        // Hide our own marker from the notes editor; it's restored on save.
                        notes: TransactionLocation.strip(from: transaction.notes),
                        // Echo back whatever the server gave us, so a PUT doesn't clear a native
                        // location on any server that actually supports these.
                        latitude: native?.nativeLatitude,
                        longitude: native?.nativeLongitude
                    )
                }
            )
        )
    }

    var transactionTypes = ["Expenses", "Income", "Transfer"]

    var body: some View {
        NavigationStack {
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
                                }
                            )
                        )
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
                                }
                            )
                        )
                        TextField(
                            "Amount",
                            text: Binding(
                                get: {
                                    transaction.amount ?? ""
                                },
                                set: { newValue in
                                    let amount = "\(newValue)"
                                    postTransactionData.transactions?[index].amount = amount
                                }
                            )
                        ).keyboardType(.decimalPad)

                        switch transaction.type {
                        case "withdrawal":
                            // Text("WithDrawal")
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
                            // Text("Deposit")
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
                            // Text("Transfer")
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
                                    }
                                )
                            ) {
                                Text("Uncategorized").tag("")
                                ForEach(categories.filter { $0 != "Uncategorized" }, id: \.self) {
                                    category in
                                    Text(category).tag(category)
                                }
                            }

                            Picker(
                                "Budget",
                                selection: Binding(
                                    get: { postTransactionData.transactions?[index].budgetID },
                                    set: { newValue in
                                        postTransactionData.transactions?[index].budgetID = newValue
                                    }
                                )
                            ) {
                                Text("No Budget").tag(nil as String?)
                                ForEach(budgets, id: \.id) { budget in
                                    Text(budget.name ?? "Unnamed Budget")
                                        .tag(budget.id as String?)
                                }
                            }
                        }

                        DatePicker(
                            "Date",
                            selection: Binding(
                                get: {
                                    formatDateFromJSON(postTransactionData.transactions?[index].date ?? "")
                                },
                                set: { newValue in
                                    postTransactionData.transactions?[index].date =
                                        CachedFormatters.jsonDateTime.string(from: newValue)
                                }
                            )
                        ).datePickerStyle(.compact)

                        TextField(
                            "Notes",
                            text: Binding(
                                get: {
                                    postTransactionData.transactions?[index].notes ?? ""
                                },
                                set: { newValue in
                                    postTransactionData.transactions?[index].notes = newValue
                                }
                            ), axis: .vertical
                        ).lineLimit(5)

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
                    PrimaryButton(
                        icon: "square.and.pencil", label: "Edit Transaction", fullWidth: true,
                        disabled: submitLoading,
                        action: {
                            Task {
                                do {
                                    try await submitTransaction()
                                } catch {
                                    AppLog.networkError("Failed to edit transaction", error)
                                }
                            }
                        }
                    ).padding(.horizontal, 16).padding(.bottom, 8)
                }
            )
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
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
                // Categories
                categories = try await createCategoriesAutocompleteArray()
                // Transactions (for Description Autocomplete)
                descriptions = try await fetchTransactionAutocomplete()
                // Accounts
                accounts = try await fetchAccountsAutocomplete()
                // Budgets
                budgets = try await fetchBudgetsAutocomplete()
                autocompleteLoading = false
            } catch {
                AppLog.networkError("Failed to load autocomplete data", error)
            }
        }
    }

    /// Puts each split's location marker back on the end of its notes before saving.
    ///
    /// `appended(to:)` strips any existing marker first, so this can't stack duplicates even if the
    /// user pasted one in by hand.
    private func payloadWithLocationsRestored() -> PostTransaction {
        var payload = postTransactionData

        guard var splits = payload.transactions else { return payload }

        for index in splits.indices {
            guard index < preservedLocations.count,
                  let location = preservedLocations[index] else { continue }

            splits[index].notes = location.appended(to: splits[index].notes ?? "")
        }

        payload.transactions = splits
        return payload
    }

    func submitTransaction() async throws {
        submitLoading = true
        do {
            try await editTransaction(
                transactionData: payloadWithLocationsRestored(), transactionID: transactionData.id!
            )
            NotificationCenter.default.post(
                name: AppNotifications.transactionUpdated, object: nil,
                userInfo: ["message": "Transaction updated"]
            )
            dismiss()
        } catch {
            toastParams = AlertToast(
                displayMode: .alert, type: .error(Color.red), title: "Something went wrong"
            )
            showToast = true
            AppLog.networkError("Failed to edit transaction", error)
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
