//
//  TransactionAddViewModel.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2025/06/13.
//

import Foundation

class TransactionAddViewModel: ObservableObject {
  @Published var transactionStore: TransactionStore

  // Direct access to the single transaction
  var transaction: TransactionSplitStore {
    get { transactionStore.transactions[0] }
    set {
      transactionStore = TransactionStore(
        errorIfDuplicateHash: transactionStore.errorIfDuplicateHash,
        applyRules: transactionStore.applyRules,
        fireWebhooks: transactionStore.fireWebhooks,
        groupTitle: transactionStore.groupTitle,
        transactions: [newValue]
      )
    }
  }

  // Access to all transactions (for split transactions)
  var allTransactions: [TransactionSplitStore] {
    get { transactionStore.transactions }
    set {
      transactionStore = TransactionStore(
        errorIfDuplicateHash: transactionStore.errorIfDuplicateHash,
        applyRules: transactionStore.applyRules,
        fireWebhooks: transactionStore.fireWebhooks,
        groupTitle: transactionStore.groupTitle,
        transactions: newValue
      )
    }
  }

  // MARK: - Initialization

  init() {
    let defaultTransaction = TransactionSplitStore(
      type: .withdrawal,
      date: ISO8601DateFormatter().string(from: Date()),
      amount: "",
      description: ""
    )

    self.transactionStore = TransactionStore(transactions: [defaultTransaction])
  }

  // Initialize with preset category
  init(categoryID: String? = nil, categoryName: String? = nil) {
    let defaultTransaction = TransactionSplitStore(
      type: .withdrawal,
      date: ISO8601DateFormatter().string(from: Date()),
      amount: "",
      description: "",
      categoryID: categoryID,
      categoryName: categoryName
    )

    self.transactionStore = TransactionStore(transactions: [defaultTransaction])
  }

  // MARK: - Helper Methods

  func updateTransaction(_ updater: (inout TransactionSplitStore) -> Void) {
    var updated = transaction
    updater(&updated)
    transaction = updated
  }

  func addSplit() {
    let newSplit = TransactionSplitStore(
      type: transaction.type,  // Use same type as main transaction
      date: transaction.date,  // Use same date as main transaction
      amount: "",
      description: ""
    )

    var updatedTransactions = allTransactions
    updatedTransactions.append(newSplit)
    allTransactions = updatedTransactions

    // Set group title if this is the first split
    if updatedTransactions.count == 2 && transactionStore.groupTitle == nil {
      setGroupTitle("Split Transaction")
    }
  }

  func removeSplit(at index: Int) {
    guard index < allTransactions.count && index > 0 else { return }  // Don't allow removing the first transaction

    var updatedTransactions = allTransactions
    updatedTransactions.remove(at: index)
    allTransactions = updatedTransactions

    // Clear group title if we're back to a single transaction
    if updatedTransactions.count == 1 {
      setGroupTitle(nil)
    }
  } 

  func updateSplit(at index: Int, with updater: (inout TransactionSplitStore) -> Void) {
    guard index < allTransactions.count else { return }

    var updatedTransactions = allTransactions
    updater(&updatedTransactions[index])
    allTransactions = updatedTransactions
  }

  func getSplit(at index: Int) -> TransactionSplitStore? {
    guard index < allTransactions.count else { return nil }
    return allTransactions[index]
  }

  func setGroupTitle(_ title: String?) {
    transactionStore = TransactionStore(
      errorIfDuplicateHash: transactionStore.errorIfDuplicateHash,
      applyRules: transactionStore.applyRules,
      fireWebhooks: transactionStore.fireWebhooks,
      groupTitle: title,
      transactions: transactionStore.transactions
    )
  }

  // MARK: - Validation

  var isValid: Bool {
    !transaction.amount.isEmpty && !transaction.description.isEmpty && !transaction.date.isEmpty
      && Double(transaction.amount) != nil && Double(transaction.amount)! > 0
  }

  // Check if this is a split transaction
  var isSplitTransaction: Bool {
    transactionStore.transactions.count > 1
  }

}
