//
//  TransactionCreate.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/05.
//

import AlertToast
import SwiftUI
import UIKit

struct TransactionCreate: View {
  @Environment(\.dismiss) var dismiss
  @Binding var shouldRefresh: Bool?

  @State private var transactionData: PostTransaction = defaultTransactionData()

  //To populate
  var transactionTypes = ["Withdrawal", "Income", "Transfer"]
  @State private var categories: [String] = ["Default"]
  @State private var budgets: AutoBudget = AutoBudget()
  @State private var accounts: AutoAccounts = AutoAccounts()
  @State private var currencies: AutoCurrency = AutoCurrency()
  @State private var descriptions: AutoTransactions = AutoTransactions()

  //Selections
  @State private var transactionDescription: String = ""
  @State private var amount: String = ""
  @State private var date: Date = Date()
  @State private var selectedCategory: String = ""
  @State private var selectedBudget: String = ""
  @State private var transactionType = "Withdrawal"
  @State private var sourceAccount: (id: String, name: String) = ("", "")
  @State private var destinationAccount: (id: String, name: String) = ("", "")
  @State private var transactionNote: String = ""

  //Toasts and controllers
  @State private var showToast = false
  @State private var toastParams: AlertToast = AlertToast(displayMode: .alert, type: .regular)
  @State private var showingNewCategoryToast = false
  @State private var newCategoryName: String = ""
  @State private var submitIsLoading = false

  var body: some View {
    NavigationView {
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
              TextField("Amount", text: $amount)
                .font(.largeTitle)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
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
              bindingText: $transactionDescription,
              transactionsAutocomplete: descriptions)

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

            //                        AutocompleteSelectionPicker(
            //                            title: "Budget", items: budgets,
            //                            itemLabel: { $0.name ?? "Unnamed budget" },
            //                            onSelection: { id, name in
            //                                selectedBudget = (id: id, name: name)
            //                            })

          }

          Section("Accounts") {
            switch transactionType {
            case "Withdrawal":
              accountPicker(title: "Source Account", binding: $sourceAccount)
            case "Income":
              accountPicker(
                title: "Destination Account", binding: $destinationAccount)
            case "Transfer":
              accountPicker(title: "Source Account", binding: $sourceAccount)
              accountPicker(
                title: "Destination Account", binding: $destinationAccount)
            default:
              EmptyView()
            }
          }

          Section("Notes") {
            TextField("Notes", text: $transactionNote, axis: .vertical)
              .lineLimit(5)
          }

        }
        .safeAreaInset(
          edge: .bottom,
          content: {
            MasterButton(
              icon: "plus.circle.fill", label: "Add Transaction", fullWidth: true,
              disabled: submitIsLoading,
              action: {
                Task {
                  do {
                    try await submitTransaction()
                  } catch {
                    print("Error submitting transaction: \(error)")
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
      .navigationBarItems(trailing: Button("Cancel") { dismiss() })
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
              print(error)
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
    }
  }

  func submitTransaction() async throws {
    submitIsLoading = true
    do {
      try await postTransaction(
        description: transactionDescription, amount: amount, date: date,
        category: selectedCategory, type: transactionType,
        sourceAccount: sourceAccount,
        destinationAccount: destinationAccount, notes: transactionNote)
      let impact = await UINotificationFeedbackGenerator()

      toastParams = AlertToast(
        displayMode: .alert, type: .complete(Color.green), title: "Saved Successfully")
      await impact.notificationOccurred(.success)
      showToast = true
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        shouldRefresh? = true
        dismiss()
      }
    } catch {
      let impact = await UINotificationFeedbackGenerator()
      toastParams = AlertToast(
        displayMode: .alert, type: .error(Color.red), title: "Something went wrong")
      await impact.notificationOccurred(.error)
      showToast = true
    }
    submitIsLoading = false
  }

  func loadAutocomplete() {
    Task {
      do {
        //Categories
        let result = try await fetchCategoriesAutocomplete()
        DispatchQueue.main.async {
          // Extract names from AutoCategoryElement and filter out nil values
          self.categories = result.compactMap { $0.name }
          if !self.categories.contains("Uncategorized") {
            self.categories.insert("Uncategorized", at: 0)
          }
        }
        //Accounts
        accounts = try await fetchAccountsAutocomplete()

        //Budgets
        budgets = try await fetchBudgetsAutocomplete()

        //Currencies

        //currencies = try await fetchCurrenciesAutoComplete()

        //Transactions (for Description Autocomplete)
        descriptions = try await fetchTransactionAutocomplete()

      } catch {
        print("Error loading categories: \(error)")
      }
    }
  }

  func addNewCategory() {
    showingNewCategoryToast = true
    newCategoryName = ""  // Reset the new category name
  }

  func confirmAddNewCategory() async throws {
    if !newCategoryName.isEmpty {
      categories.append(newCategoryName)
      selectedCategory = newCategoryName  // Optionally select the new category

    }
    showingNewCategoryToast = false
  }
  private func accountPicker(title: String, binding: Binding<(id: String, name: String)>)
    -> some View
  {
    AccountsSelectionPicker(title: title, accounts: accounts) { id, name in
      binding.wrappedValue = (id: id, name: name)
    }
  }

}

struct DescriptionInput: View {

  var bindingText: Binding<String>
  @FocusState private var focused: Bool
  @State private var showSuggestions = false
  @StateObject private var viewModel = DescriptionInputViewModel()
  var transactionsAutocomplete: [AutoTransactionElement]

  private var filteredAutocomplete: [AutoTransactionElement] {
    if bindingText.wrappedValue.isEmpty {
      return transactionsAutocomplete
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
            })
        }
      }

      if showSuggestions {
        VStack(alignment: .leading) {
          Text("Suggestions").font(.caption).fontWeight(.light)

          ScrollView(.horizontal, showsIndicators: false) {
            HStack {
              ForEach(filteredAutocomplete, id: \.id) {
                data in
                SuggestionChip(label: data.description ?? "Unknown").onTapGesture {
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
    .onChange(of: viewModel.debouncedText) { oldValue, newValue in
      viewModel.fetch()
      print("fetching description autocomplete")
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
  var body: some View {
    Text(label)
      .font(.subheadline).foregroundStyle(.white).padding(.vertical, 1)
      .padding(.horizontal, 10).background(.gray)
      .clipShape(RoundedRectangle(cornerSize: CGSize(width: 5, height: 10)))
  }

}

struct AccountsSelectionPicker: View {
  let title: String
  let accounts: AutoAccounts
  let onSelection: (String, String) -> Void  //Callback for (id, name)

  @State private var selectedAccountID: String?

  init(
    title: String = "Account", accounts: AutoAccounts,
    onSelection: @escaping (String, String) -> Void
  ) {
    self.title = title
    self.accounts = accounts
    self.onSelection = onSelection
  }

  var body: some View {
    Picker(title, selection: $selectedAccountID) {
      Text("Select an account").tag(nil as String?)
      ForEach(accounts, id: \.id) { account in
        Text(account.name ?? "Unnamed Account")
          .tag(account.id as String?)
      }
    }
    .onChange(of: selectedAccountID) { oldValue, newValue in
      if let newId = newValue,
        let selectedAccount = accounts.first(where: { $0.id == newId })
      {
        onSelection(newId, selectedAccount.name ?? "Unnamed Account")
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
    .onChange(of: selectedID) { oldValue, newValue in
      if let newId = newValue,
        let selectedItem = items.first(where: { $0.id == newId })
      {
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
    .onChange(of: selectedCurrencyID) { oldValue, newValue in
      if let newId = newValue,
        let selectedCurrency = currencies.first(where: { $0.id == newId })
      {
        onSelection(newId, selectedCurrency.name ?? "Unknown Currency")
      }
    }
  }
}

//struct TransactionCreate_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionCreate()
//    }
//}
