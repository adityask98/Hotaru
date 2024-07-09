//
//  TransactionCreate.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/05.
//

import AlertToast
import SwiftUI

struct TransactionCreate: View {
    @Environment(\.dismiss) var dismiss

    @State private var transactionData: PostTransaction = defaultTransactionData()

    //To populate
    var transactionTypes = ["Expenses", "Income", "Transfer"]
    @State private var categories: [String] = ["Default"]
    @State private var accounts: AutoAccounts = AutoAccounts()

    //Selections
    @State private var transactionDescription: String = ""
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var selectedCategory: String = "Uncategorized"
    @State private var transactionType = "Expenses"
    @State private var sourceAccount: (id: String, name: String) = ("", "")
    @State private var destinationAccount: (id: String, name: String) = ("", "")

    //Toasts and controllers
    @State private var showToast = false
    @State private var toastParams: AlertToast = AlertToast(displayMode: .alert, type: .regular)
    @State private var showingNewCategoryToast = false
    @State private var newCategoryName: String = ""

    var body: some View {
        NavigationView {
            Form {
                VStack {
                    Picker("", selection: $transactionType) {
                        ForEach(transactionTypes, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(.segmented)
                    HStack {
                        Spacer()
                        //                        Text("$")
                        //                            .font(.largeTitle)
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
                    TextField("Description", text: $transactionDescription)
                    Picker("Category", selection: $selectedCategory) {
                        Text("Uncategorized").tag("Uncategorized")
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

                }

                Section("Accounts") {
                    switch transactionType {
                    case "Expenses":
                        accountPicker(title: "Source Account", binding: $sourceAccount)
                    case "Income":
                        accountPicker(title: "Destination Account", binding: $destinationAccount)
                    case "Transfer":
                        accountPicker(title: "Source Account", binding: $sourceAccount)
                        accountPicker(title: "Destination Account", binding: $destinationAccount)
                    default:
                        EmptyView()
                    }
                }

                Button(action: {
                    Task {
                        do {
                            try await submitTransaction()
                        } catch {
                            print("Error submitting transaction: \(error)")
                            // Handle the error appropriately
                        }
                    }
                }) {
                    Text("Add Transaction")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(.capsule)
                }

            }
            .toast(isPresenting: $showToast, tapToDismiss: false) {
                toastParams
            }
            .navigationTitle("Add Expense")
            .allowsHitTesting(!showToast)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
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
        // Implement your submission logic here
        //        print(
        //            "Transaction submitted: \(transactionDescription), Amount: \(amount), Date: \(date), Category: \(selectedCategory)"
        //        )
        do {
            try await postTransaction(
                description: transactionDescription, amount: amount, date: date,
                category: selectedCategory, type: transactionType,
                sourceAccount: sourceAccount,
                destinationAccount: destinationAccount)
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
        }
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
                accounts = try await fetchAccountsAutocomplete()
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

//struct TransactionCreate_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionCreate()
//    }
//}
