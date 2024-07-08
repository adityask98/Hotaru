//
//  TransactionCreate.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/05.
//

import SwiftUI

struct TransactionCreate: View {
    @Environment(\.dismiss) var dismiss
    @State private var transactionName: String = ""
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var selectedCategory: String = "Uncategorized"
    @State private var transactionType = "Expenses"
    @State private var categories: [String] = ["Default"]

    var transactionTypes = ["Expenses", "Income"]

    //    var categories = ["Food", "Transport", "Entertainment", "Utilities", "Uncategorized"]

    var body: some View {
        NavigationView {
            Form {
                //                Section(header: Text("Transaction Details")) {
                //                    TextField("Transaction Name", text: $transactionName)
                //
                //                    HStack {
                //                        Text("$")
                //                        TextField("Amount", value: $amount, formatter: NumberFormatter())
                //                            .keyboardType(.decimalPad)
                //                    }
                //
                //                    DatePicker("Date", selection: $date, displayedComponents: .date)
                //                }

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

                    //Description box
                    //                    HStack {
                    //                        Spacer()
                    //                        TextField("Description", text: $transactionName)
                    //                            .font(.subheadline)
                    //                            .padding()
                    //                            //.background(Color.gray.opacity(0.2))
                    //                            .background(.ultraThinMaterial)
                    //                            .clipShape(
                    //                                RoundedRectangle(
                    //                                    cornerRadius: 10.0
                    //                                )
                    //                            )
                    //                            .multilineTextAlignment(.center)
                    //                            .frame(maxWidth: 150)  // Adjust this value as needed
                    //                        Spacer()
                    //                    }

                    HStack {
                        Spacer()
                        DatePicker("", selection: $date).pickerStyle(.inline).labelsHidden()
                        Spacer()
                    }
                }

                Section("Details") {
                    TextField("Description", text: $transactionName)
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { category in
                            Text(category)
                        }
                        Divider()
                        Button(action: addNewCategory) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Category")
                            }
                        }
                    }

                }

                Button("AUTOCOMPLETE") {
                    loadCategoryAutocomplete()
                }

                Button(action: submitTransaction) {
                    Text("Add Transaction")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .clipShape(.capsule)
                }

            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
        .onAppear {
            loadCategoryAutocomplete()
        }
    }

    func submitTransaction() {
        // Implement your submission logic here
        print(
            "Transaction submitted: \(transactionName), Amount: \(amount), Date: \(date), Category: \(selectedCategory)"
        )
        dismiss()
    }

    func loadCategoryAutocomplete() {
        Task {
            do {
                let result = try await fetchCategoriesAutocomplete()
                DispatchQueue.main.async {
                    // Extract names from AutoCategoryElement and filter out nil values
                    self.categories = result.compactMap { $0.name }
                    if !self.categories.contains("Uncategorized") {
                        self.categories.insert("Uncategorized", at: 0)
                    }
                }
            } catch {
                print("Error loading categories: \(error)")
                // Handle the error appropriately, set a default list of categories
                DispatchQueue.main.async {
                    self.categories = [
                        "Food", "Transport", "Entertainment", "Utilities", "Uncategorized",
                    ]
                }
            }
        }
    }

    func addNewCategory() {
        // Implement the logic to add a new category
        // This could open a new sheet or alert to input the category name
        print("Add new category tapped")
    }

}

//struct TransactionCreate_Previews: PreviewProvider {
//    static var previews: some View {
//        TransactionCreate()
//    }
//}
