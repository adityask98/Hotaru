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

    @AppStorage(UserDefaultKeys.writeLocationToNotes) private var writeLocationToNotes = false

    /// Each split's location as it arrived (native coordinates, else the notes marker), keyed by
    /// split index. Shown in the editor, and written back as a notes marker on save when
    /// `writeLocationToNotes` is on. Splits can't be added or removed here, so the indices stay
    /// aligned with `postTransactionData.transactions`.
    @State private var locations: [TransactionLocation?]

    /// Split indices whose location the user has asked to delete.
    @State private var removedLocations: Set<Int> = []

    init(transactionData: TransactionsDatum) {
        _transactionData = State(initialValue: transactionData)
        _locations = State(
            initialValue: (transactionData.attributes?.transactions ?? []).map {
                TransactionLocation.resolve(for: $0)
            }
        )
        _postTransactionData = State(
            initialValue: PostTransaction(
                errorIfDuplicateHash: true, applyRules: true, fireWebhooks: true,
                groupTitle: transactionData.attributes?.groupTitle,
                transactions: transactionData.attributes?.transactions?.map { transaction in
                    var element = PostTransactionElement(
                        transactionJournalID: transaction.transactionJournalID,
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
                        // Hide our own marker from the notes editor; it's restored on save if
                        // `writeLocationToNotes` is on.
                        notes: TransactionLocation.strip(from: transaction.notes)
                    )

                    // Echo back the native location with the server's own zoom. Failing that, send
                    // the notes marker's location as native fields so an edit upgrades the
                    // transaction — PUT stores these on Firefly 6.7.0+ and is ignored before that.
                    if let native = TransactionLocation.fromNativeFields(transaction) {
                        native.apply(to: &element, zoomLevel: transaction.zoomLevel)
                    } else {
                        TransactionLocation.parse(from: transaction.notes)?.apply(to: &element)
                    }

                    return element
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

                        if index < locations.count, let location = locations[index] {
                            locationRow(location, index: index)
                        }
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
                        loading: submitLoading,
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

    // MARK: - Location

    private func locationRow(_ location: TransactionLocation, index: Int) -> some View {
        let isRemoved = removedLocations.contains(index)

        return HStack {
            Label {
                Text(location.name ?? Self.coordinateText(location))
                    .strikethrough(isRemoved)
                    .lineLimit(1)
            } icon: {
                Image(systemName: isRemoved ? "location.slash" : "location.fill")
            }
            .foregroundStyle(isRemoved ? .secondary : .primary)

            Spacer()

            if isRemoved {
                Button("Undo") { removedLocations.remove(index) }
            } else {
                Button("Remove", role: .destructive) { removedLocations.insert(index) }
            }
        }
        .buttonStyle(.borderless)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isRemoved ? "Location will be removed" : "Location")
    }

    private static func coordinateText(_ location: TransactionLocation) -> String {
        String(format: "%.5f, %.5f", location.latitude, location.longitude)
    }

    /// Applies location removals and, if enabled, the notes marker to each split before saving.
    ///
    /// `appended(to:)` strips any existing marker first, so this can't stack duplicates even if the
    /// user pasted one in by hand.
    private func payloadWithLocations() -> PostTransaction {
        var payload = postTransactionData

        guard var splits = payload.transactions else { return payload }

        let originals = transactionData.attributes?.transactions ?? []

        for index in splits.indices {
            let original = index < originals.count ? originals[index] : nil
            let location = index < locations.count ? locations[index] : nil
            var notes = splits[index].notes

            if removedLocations.contains(index) {
                TransactionLocation.clear(on: &splits[index])
            } else if writeLocationToNotes, let location {
                notes = location.appended(to: notes ?? "")
            }

            // The editor shows notes with the marker stripped, and a marker-only note arrives as
            // nil — which the encoder would omit, leaving the server's marker in place. Send it
            // explicitly whenever the original had a marker so dropping it actually sticks.
            if notes == nil, TransactionLocation.parse(from: original?.notes) != nil {
                notes = ""
            }

            splits[index].notes = notes
        }

        payload.transactions = splits
        return payload
    }

    func submitTransaction() async throws {
        submitLoading = true
        do {
            try await editTransaction(
                transactionData: payloadWithLocations(), transactionID: transactionData.id!
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
        AccountSelectorRow(title: title, accounts: accounts, selectedID: $selectedAccountID)
    }
}
