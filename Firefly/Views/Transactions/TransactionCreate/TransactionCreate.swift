import AlertToast
import SwiftUI
import UIKit

struct TransactionCreate: View {
    @Environment(\.dismiss) var dismiss

    @State private var transactionData: PostTransaction = defaultTransactionData()

    // To populate
    var transactionTypes = ["Withdrawal", "Income", "Transfer"]
    @State private var categories = ["Default"]
    @State private var budgets = AutoBudget()
    @State private var accounts = AutoAccounts()
    @State private var currencies = AutoCurrency()
    //  @State private var descriptions: AutoTransactions = AutoTransactions()

    // Selections
    @State private var transactionDescription: String
    @State private var amount: String
    @State private var displayAmount: String
    @State private var date: Date
    @State private var selectedCategory: String
    @State private var selectedBudgetID: String?
    @State private var transactionType: String
    @State private var sourceAccount: (id: String, name: String)
    @State private var destinationAccount: (id: String, name: String)
    @State private var transactionNote: String
    @FocusState private var amountFieldFocused: Bool

    // Location (beta) — see docs/LOCATION_IN_NOTES.md
    @AppStorage(UserDefaultKeys.attachLocationToTransactions) private var locationFeatureEnabled = true
    @AppStorage(UserDefaultKeys.writeLocationToNotes) private var writeLocationToNotes = false
    @StateObject private var locationProvider = LocationProvider()
    @State private var attachLocation = true
    @State private var capturedLocation: TransactionLocation?
    @State private var locationStatus: LocationCaptureStatus = .idle

    // Toasts and controllers
    @State private var showToast = false
    @State private var toastParams = AlertToast(displayMode: .alert, type: .regular)
    @State private var showingNewCategoryToast = false
    @State private var newCategoryName = ""
    @State private var submitIsLoading = false

    /// Initializer with optional initial transaction data
    init(initialTransaction: TransactionsDatum? = nil) {
        // If initial transaction data is provided, use it to initialize the state
        if let transaction = initialTransaction?.attributes?.transactions?.first {
            _transactionDescription = State(initialValue: transaction.description ?? "")
            let initialAmount = formatAmountForTextField(
                transaction.amount ?? "0",
                decimalPlace: transaction.currencyDecimalPlaces ?? 2
            )
            _amount = State(initialValue: initialAmount)
            _displayAmount = State(initialValue: formatAmountForDisplay(initialAmount))
            // Always use current date when cloning
            _date = State(initialValue: Date())
            _selectedCategory = State(initialValue: transaction.categoryName ?? "")
            _selectedBudgetID = State(initialValue: transaction.budgetID)
            _transactionType = State(initialValue: convertTypeToDisplay(transaction.type ?? "withdrawal"))
            _sourceAccount = State(initialValue: (
                id: transaction.sourceID ?? "",
                name: transaction.sourceName ?? ""
            ))
            _destinationAccount = State(initialValue: (
                id: transaction.destinationID ?? "",
                name: transaction.destinationName ?? ""
            ))
            // Strip any location marker: a clone happens somewhere else, at some other time, so
            // inheriting the original's coordinates would be plainly wrong.
            _transactionNote = State(initialValue: TransactionLocation.strip(from: transaction.notes) ?? "")
        } else {
            // Default values for new transaction
            _transactionDescription = State(initialValue: "")
            _amount = State(initialValue: "")
            _displayAmount = State(initialValue: "")
            _date = State(initialValue: Date())
            _selectedCategory = State(initialValue: "")
            _selectedBudgetID = State(initialValue: nil)
            _transactionType = State(initialValue: "Withdrawal")
            _sourceAccount = State(initialValue: ("", ""))
            _destinationAccount = State(initialValue: ("", ""))
            _transactionNote = State(initialValue: "")
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    VStack {
                        Picker("", selection: $transactionType.animation()) {
                            ForEach(transactionTypes, id: \.self) {
                                Text($0)
                            }
                        }
                        .pickerStyle(.segmented)
                        HStack {
                            Spacer()
                            TextField("Amount", text: $displayAmount)
                                .font(.largeTitle)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .focused($amountFieldFocused)
                                .onChange(of: displayAmount) { _, newValue in
                                    let raw = stripAmountGrouping(newValue)
                                    amount = raw
                                    let formatted = formatAmountForDisplay(raw)
                                    if formatted != newValue {
                                        displayAmount = formatted
                                    }
                                }
                            Spacer()
                        }
                        .padding(.vertical, 20)

                        HStack {
                            Spacer()
                            DatePicker("", selection: $date).pickerStyle(.inline).labelsHidden()
                            Spacer()
                        }
                    }

                    Section("Details") {
                        DescriptionInput(
                            bindingText: $transactionDescription
                        )

                        Picker("Category", selection: $selectedCategory) {
                            Text("Uncategorized").tag("")
                            ForEach(categories.filter { $0 != "Uncategorized" }, id: \.self) {
                                category in
                                Text(category)
                            }
                        }
                        Button(action: addNewCategory) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Category")
                            }
                        }

                        Picker("Budget", selection: $selectedBudgetID) {
                            Text("No Budget").tag(nil as String?)
                            ForEach(budgets, id: \.id) { budget in
                                Text(budget.name ?? "Unnamed Budget")
                                    .tag(budget.id as String?)
                            }
                        }
                    }

                    Section("Accounts") {
                        switch transactionType {
                        case "Withdrawal":
                            accountPicker(title: "Source Account", binding: $sourceAccount)
                        case "Income":
                            accountPicker(
                                title: "Destination Account", binding: $destinationAccount
                            )
                        case "Transfer":
                            accountPicker(title: "Source Account", binding: $sourceAccount)
                            accountPicker(
                                title: "Destination Account", binding: $destinationAccount
                            )
                        default:
                            EmptyView()
                        }
                    }

                    Section("Notes") {
                        TextField("Notes", text: $transactionNote, axis: .vertical)
                            .lineLimit(5)
                    }

                    if locationFeatureEnabled {
                        Section("Location") {
                            locationRow
                        }
                    }
                }
                .safeAreaInset(
                    edge: .bottom,
                    content: {
                        PrimaryButton(
                            icon: "plus.circle.fill", label: "Add Transaction", fullWidth: true,
                            loading: submitIsLoading,
                            action: {
                                Task {
                                    do {
                                        try await submitTransaction()
                                    } catch {
                                        AppLog.networkError("Failed to submit transaction", error)
                                        // Handle the error appropriately
                                    }
                                }
                            }
                        )
                        .padding(.horizontal, 16).padding(.bottom, 8)
                    }
                )
                .scrollDismissesKeyboard(.interactively)
            }

            .navigationTitle("Add Transaction")
            .allowsHitTesting(!showToast)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .toast(isPresenting: $showToast, tapToDismiss: false) {
                toastParams
            }
            .alert("Enter the name for a new category", isPresented: $showingNewCategoryToast) {
                TextField("New category", text: $newCategoryName).foregroundStyle(Color.black)
                Button("Add") {
                    Task {
                        do {
                            try await confirmAddNewCategory()
                        } catch {
                            AppLog.appError("Failed to add category", error)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    showingNewCategoryToast = false
                }
            } message: {
                Text("Please enter a name for the new category.")
            }
        }
        .onAppear {
            loadAutocomplete()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                amountFieldFocused = true
            }
        }
        .task {
            // Start early so a fix is usually ready by the time the form is filled in. Capture never
            // gates submission — if nothing has arrived, the transaction posts without a location.
            await captureLocationIfNeeded()
        }
        .onChange(of: attachLocation) { _, isOn in
            if isOn {
                Task { await captureLocationIfNeeded() }
            } else {
                capturedLocation = nil
                locationStatus = .idle
            }
        }
    }

    // MARK: - Location (beta)

    @ViewBuilder
    private var locationRow: some View {
        Toggle(isOn: $attachLocation) {
            HStack(spacing: 6) {
                Text("Attach Location")
                Image(systemName: "testtube.2")
                    .foregroundStyle(.orange)
                    .accessibilityLabel("Beta feature")
            }
        }
        .disabled(locationProvider.isDenied)

        switch locationStatus {
        case .idle:
            EmptyView()

        case .locating:
            Label("Finding your location…", systemImage: "location")
                .font(.caption)
                .foregroundStyle(.secondary)

        case .captured:
            Label(capturedLocation?.name ?? "Location recorded", systemImage: "location.fill")
                .font(.caption)
                .foregroundStyle(.secondary)

        case .denied:
            VStack(alignment: .leading, spacing: 6) {
                Text("Hotaru doesn't have permission to use your location.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Open Settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
                .font(.caption)
            }

        case .unavailable:
            Label("Couldn't get an accurate location", systemImage: "location.slash")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func captureLocationIfNeeded() async {
        guard locationFeatureEnabled, attachLocation, capturedLocation == nil else { return }

        locationStatus = .locating

        switch await locationProvider.capture() {
        case .success(let location):
            capturedLocation = location
            locationStatus = .captured

        case .denied:
            // Only offer the Settings shortcut if permission was actually refused — an
            // authorization request that resolved to something else shouldn't send the user there.
            locationStatus = locationProvider.isDenied ? .denied : .unavailable

        case .unavailable:
            locationStatus = .unavailable
        }
    }

    /// The location to send, honouring both the master setting and the per-transaction toggle.
    private var locationToAttach: TransactionLocation? {
        guard locationFeatureEnabled, attachLocation else { return nil }
        return capturedLocation
    }

    func submitTransaction() async throws {
        submitIsLoading = true
        do {
            let location = locationToAttach
            try await postTransaction(
                description: transactionDescription, amount: amount, date: date,
                category: selectedCategory, type: transactionType,
                sourceAccount: sourceAccount,
                destinationAccount: destinationAccount,
                notes: writeLocationToNotes
                    ? location?.appended(to: transactionNote) ?? transactionNote
                    : transactionNote,
                budgetID: selectedBudgetID,
                location: location
            )
            let impact = UINotificationFeedbackGenerator()

            toastParams = AlertToast(
                displayMode: .alert, type: .complete(Color.green), title: "Saved Successfully"
            )
            impact.notificationOccurred(.success)
            showToast = true
            NotificationCenter.default.post(name: AppNotifications.transactionCreated, object: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismiss()
            }
        } catch {
            let impact = UINotificationFeedbackGenerator()
            toastParams = AlertToast(
                displayMode: .alert, type: .error(Color.red), title: "Something went wrong"
            )
            impact.notificationOccurred(.error)
            showToast = true
        }
        submitIsLoading = false
    }

    func loadAutocomplete() {
        Task {
            do {
                // Categories
                let result = try await fetchCategoriesAutocomplete()
                DispatchQueue.main.async {
                    // Extract names from AutoCategoryElement and filter out nil values
                    self.categories = result.compactMap { $0.name }
                    if !self.categories.contains("Uncategorized") {
                        self.categories.insert("Uncategorized", at: 0)
                    }
                }
                // Accounts
                accounts = try await fetchAccountsAutocomplete()

                // Budgets
                budgets = try await fetchBudgetsAutocomplete()

                // Currencies

                // currencies = try await fetchCurrenciesAutoComplete()

                // Transactions (for Description Autocomplete)
                //        descriptions = try await fetchTransactionAutocomplete()

            } catch {
                AppLog.networkError("Failed to load autocomplete data", error)
            }
        }
    }

    func addNewCategory() {
        showingNewCategoryToast = true
        newCategoryName = "" // Reset the new category name
    }

    func confirmAddNewCategory() async throws {
        if !newCategoryName.isEmpty {
            categories.append(newCategoryName)
            selectedCategory = newCategoryName // Optionally select the new category
        }
        showingNewCategoryToast = false
    }

    private func accountPicker(title: String, binding: Binding<(id: String, name: String)>)
    -> some View {
        AccountSelectorRow(
            title: title, accounts: accounts,
            selectedID: Binding(
                get: { binding.wrappedValue.id },
                set: { id in
                    binding.wrappedValue = (
                        id: id, name: accounts.first { $0.id == id }?.name ?? ""
                    )
                }
            )
        )
    }
}

struct DescriptionInput: View {
    var bindingText: Binding<String>
    @FocusState private var focused: Bool
    @State private var showSuggestions = false
    @StateObject private var viewModel = DescriptionInputViewModel()
    //  var transactionsAutocomplete: [AutoTransactionElement]

    private var filteredAutocomplete: [AutoTransactionElement] {
        if bindingText.wrappedValue.isEmpty {
            return viewModel.transactionsAutocomplete
        } else {
            return viewModel.transactionsAutocomplete.filter {
                $0.description!.lowercased().contains(bindingText.wrappedValue.lowercased())
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                TextField("Description", text: bindingText)
                    .focused($focused)
                if !bindingText.wrappedValue.isEmpty && focused {
                    Button(
                        action: {
                            bindingText.wrappedValue = ""
                        },
                        label: {
                            Image(systemName: "xmark.circle.fill")
                                .buttonStyle(.borderless)
                                .foregroundStyle(.gray)
                        }
                    )
                }
            }

            if showSuggestions {
                VStack(alignment: .leading) {
                    Text("Suggestions").font(.caption).fontWeight(.light)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(filteredAutocomplete, id: \.id) {
                                data in
                                SuggestionChip(label: data.description ?? "Unknown")
                                    .onTapGesture {
                                        bindingText.wrappedValue = data.description ?? ""
                                        focused = false
                                    }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            // Initialize viewModel.text with the external binding value
            viewModel.text = bindingText.wrappedValue
        }

        .onChange(of: viewModel.text) { _, newValue in
            // Keep the external binding in sync with the ViewModel
            if bindingText.wrappedValue != newValue {
                bindingText.wrappedValue = newValue
            }
        }
        .onChange(of: bindingText.wrappedValue) { _, newValue in
            // Keep the ViewModel in sync with the external binding
            if viewModel.text != newValue {
                viewModel.text = newValue
            }
        }
        .onChange(of: viewModel.debouncedText) { _, _ in
            viewModel.fetch()
        }
        .onChange(of: focused) { _, newValue in
            withAnimation(.default) {
                showSuggestions = newValue
            }
        }
    }
}

struct SuggestionChip: View {
    let label: String
    var backgroundColor = Color.gray.opacity(0.2)
    var textColor: Color = .primary
    var borderColor: Color = .gray.opacity(0.5)
    var cornerRadius: CGFloat = 16
    var body: some View {
        Text(label)
            .font(.subheadline)
            .foregroundStyle(textColor)
            .padding(.vertical, 6)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
            )
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

/// Row showing the selected account; tapping opens a searchable list with balance and account type.
struct AccountSelectorRow: View {
    let title: String
    let accounts: AutoAccounts
    @Binding var selectedID: String

    @State private var showingList = false
    /// Applied in `onDismiss` so the parent's state change doesn't race the sheet closing.
    @State private var pendingID: String?

    private var selected: AutoAccount? {
        accounts.first { $0.id == selectedID }
    }

    var body: some View {
        Button {
            showingList = true
        } label: {
            HStack {
                Text(title).foregroundStyle(Color.primary)
                Spacer()
                Text(selected?.nameWithBalance ?? selected?.name ?? "Select")
                    .foregroundStyle(Color.secondary)
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
            }
        }
        .sheet(isPresented: $showingList, onDismiss: {
            if let id = pendingID {
                selectedID = id
                pendingID = nil
            }
        }) {
            AccountSelectorList(title: title, accounts: accounts, selectedID: selectedID) { id in
                pendingID = id
            }
            .presentationDetents([.medium, .large])
        }
    }
}

private struct AccountSelectorList: View {
    let title: String
    let accounts: AutoAccounts
    let selectedID: String
    let onSelect: (String) -> Void

    @State private var query = ""
    @Environment(\.dismiss) private var dismiss

    private var filtered: AutoAccounts {
        let valid = accounts.filter { $0.id != nil }
        guard !query.isEmpty else { return valid }
        return valid.filter {
            ($0.name ?? "").localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered, id: \.id) { account in
                Button {
                    if let id = account.id {
                        onSelect(id)
                        dismiss()
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.nameWithBalance ?? account.name ?? "Unnamed Account")
                                .foregroundStyle(Color.primary)
                            if let type = account.type {
                                Text(type)
                                    .font(.subheadline)
                                    .foregroundStyle(Color.secondary)
                            }
                        }
                        Spacer()
                        if account.id == selectedID {
                            Image(systemName: "checkmark").foregroundStyle(.tint)
                        }
                    }
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search accounts")
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct AutocompleteSelectionPicker<T: Identifiable>: View {
    let title: String
    let items: [T]
    let itemLabel: (T) -> String
    let onSelection: (T) -> Void

    @State private var selectedID: T.ID?

    init(
        title: String,
        items: [T],
        itemLabel: @escaping (T) -> String,
        onSelection: @escaping (T) -> Void
    ) {
        self.title = title
        self.items = items
        self.itemLabel = itemLabel
        self.onSelection = onSelection
    }

    var body: some View {
        Picker(title, selection: $selectedID) {
            Text("Select an item").tag(nil as T.ID?)
            ForEach(items) { item in
                Text(itemLabel(item))
                    .tag(item.id as T.ID?)
            }
        }
        .onChange(of: selectedID) { _, newValue in
            if let newId = newValue,
               let selectedItem = items.first(where: { $0.id == newId }) {
                onSelection(selectedItem)
            }
        }
    }
}

struct CurrencyPicker: View {
    let currencies: AutoCurrency
    let onSelection: (String, String) -> Void

    @State private var selectedCurrencyID: String?

    init(
        currencies: AutoCurrency,
        onSelection: @escaping (String, String) -> Void
    ) {
        self.currencies = currencies
        self.onSelection = onSelection
    }

    var body: some View {
        Picker(selection: $selectedCurrencyID, label: EmptyView()) {
            ForEach(currencies, id: \.id) { currency in
                Text(currency.name ?? "Unknown currency")
                    .tag(currency.id as String?)
            }
        }
        .onChange(of: selectedCurrencyID) { _, newValue in
            if let newId = newValue,
               let selectedCurrency = currencies.first(where: { $0.id == newId }) {
                onSelection(newId, selectedCurrency.name ?? "Unknown Currency")
            }
        }
    }
}

// struct TransactionCreate_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionCreate()
//    }
// }
