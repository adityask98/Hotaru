import Foundation

// MARK: - TransactionStore

struct TransactionStore: Codable {
    var errorIfDuplicateHash: Bool?
    var applyRules: Bool?
    var fireWebhooks: Bool?
    var groupTitle: String?
    var transactions: [TransactionSplitStore]

    enum CodingKeys: String, CodingKey {
        case errorIfDuplicateHash = "error_if_duplicate_hash"
        case applyRules = "apply_rules"
        case fireWebhooks = "fire_webhooks"
        case groupTitle = "group_title"
        case transactions
    }

    init(
        errorIfDuplicateHash: Bool? = false,
        applyRules: Bool? = false,
        fireWebhooks: Bool? = true,
        groupTitle: String? = nil,
        transactions: [TransactionSplitStore]
    ) {
        self.errorIfDuplicateHash = errorIfDuplicateHash
        self.applyRules = applyRules
        self.fireWebhooks = fireWebhooks
        self.groupTitle = groupTitle
        self.transactions = transactions
    }
}

// MARK: - TransactionSplitStore

struct TransactionSplitStore: Codable {
    // Required properties
    var type: TransactionTypeProperty
    var date: String
    var amount: String
    var description: String

    // Optional properties
    var order: Int?
    var currencyID: String?
    var currencyCode: String?
    var foreignAmount: String?
    var foreignCurrencyID: String?
    var foreignCurrencyCode: String?
    var budgetID: String?
    var budgetName: String?
    var categoryID: String?
    var categoryName: String?
    var sourceID: String?
    var sourceName: String?
    var destinationID: String?
    var destinationName: String?
    var reconciled: Bool?
    var piggyBankID: Int?
    var piggyBankName: String?
    var billID: String?
    var billName: String?
    var tags: [String]?
    var notes: String?
    var internalReference: String?
    var externalID: String?
    var externalURL: String?
    var bunqPaymentID: String?
    var sepaCC: String?
    var sepaCTOP: String?
    var sepaCTID: String?
    var sepaDB: String?
    var sepaCountry: String?
    var sepaEP: String?
    var sepaCI: String?
    var sepaBatchID: String?
    var interestDate: String?
    var bookDate: String?
    var processDate: String?
    var dueDate: String?
    var paymentDate: String?
    var invoiceDate: String?

    enum CodingKeys: String, CodingKey {
        case type, date, amount, description, order, reconciled, tags, notes
        case currencyID = "currency_id"
        case currencyCode = "currency_code"
        case foreignAmount = "foreign_amount"
        case foreignCurrencyID = "foreign_currency_id"
        case foreignCurrencyCode = "foreign_currency_code"
        case budgetID = "budget_id"
        case budgetName = "budget_name"
        case categoryID = "category_id"
        case categoryName = "category_name"
        case sourceID = "source_id"
        case sourceName = "source_name"
        case destinationID = "destination_id"
        case destinationName = "destination_name"
        case piggyBankID = "piggy_bank_id"
        case piggyBankName = "piggy_bank_name"
        case billID = "bill_id"
        case billName = "bill_name"
        case internalReference = "internal_reference"
        case externalID = "external_id"
        case externalURL = "external_url"
        case bunqPaymentID = "bunq_payment_id"
        case sepaCC = "sepa_cc"
        case sepaCTOP = "sepa_ct_op"
        case sepaCTID = "sepa_ct_id"
        case sepaDB = "sepa_db"
        case sepaCountry = "sepa_country"
        case sepaEP = "sepa_ep"
        case sepaCI = "sepa_ci"
        case sepaBatchID = "sepa_batch_id"
        case interestDate = "interest_date"
        case bookDate = "book_date"
        case processDate = "process_date"
        case dueDate = "due_date"
        case paymentDate = "payment_date"
        case invoiceDate = "invoice_date"
    }

    init(
        type: TransactionTypeProperty,
        date: String,
        amount: String,
        description: String,
        order: Int? = nil,
        currencyID: String? = nil,
        currencyCode: String? = nil,
        foreignAmount: String? = nil,
        foreignCurrencyID: String? = nil,
        foreignCurrencyCode: String? = nil,
        budgetID: String? = nil,
        budgetName: String? = nil,
        categoryID: String? = nil,
        categoryName: String? = nil,
        sourceID: String? = nil,
        sourceName: String? = nil,
        destinationID: String? = nil,
        destinationName: String? = nil,
        reconciled: Bool? = nil,
        piggyBankID: Int? = nil,
        piggyBankName: String? = nil,
        billID: String? = nil,
        billName: String? = nil,
        tags: [String]? = nil,
        notes: String? = nil,
        internalReference: String? = nil,
        externalID: String? = nil,
        externalURL: String? = nil,
        bunqPaymentID: String? = nil,
        sepaCC: String? = nil,
        sepaCTOP: String? = nil,
        sepaCTID: String? = nil,
        sepaDB: String? = nil,
        sepaCountry: String? = nil,
        sepaEP: String? = nil,
        sepaCI: String? = nil,
        sepaBatchID: String? = nil,
        interestDate: String? = nil,
        bookDate: String? = nil,
        processDate: String? = nil,
        dueDate: String? = nil,
        paymentDate: String? = nil,
        invoiceDate: String? = nil
    ) {
        self.type = type
        self.date = date
        self.amount = amount
        self.description = description
        self.order = order
        self.currencyID = currencyID
        self.currencyCode = currencyCode
        self.foreignAmount = foreignAmount
        self.foreignCurrencyID = foreignCurrencyID
        self.foreignCurrencyCode = foreignCurrencyCode
        self.budgetID = budgetID
        self.budgetName = budgetName
        self.categoryID = categoryID
        self.categoryName = categoryName
        self.sourceID = sourceID
        self.sourceName = sourceName
        self.destinationID = destinationID
        self.destinationName = destinationName
        self.reconciled = reconciled
        self.piggyBankID = piggyBankID
        self.piggyBankName = piggyBankName
        self.billID = billID
        self.billName = billName
        self.tags = tags
        self.notes = notes
        self.internalReference = internalReference
        self.externalID = externalID
        self.externalURL = externalURL
        self.bunqPaymentID = bunqPaymentID
        self.sepaCC = sepaCC
        self.sepaCTOP = sepaCTOP
        self.sepaCTID = sepaCTID
        self.sepaDB = sepaDB
        self.sepaCountry = sepaCountry
        self.sepaEP = sepaEP
        self.sepaCI = sepaCI
        self.sepaBatchID = sepaBatchID
        self.interestDate = interestDate
        self.bookDate = bookDate
        self.processDate = processDate
        self.dueDate = dueDate
        self.paymentDate = paymentDate
        self.invoiceDate = invoiceDate
    }
}

// MARK: - TransactionTypeProperty

enum TransactionTypeProperty: String, Codable, CaseIterable {
    case withdrawal
    case deposit
    case transfer
    case reconciliation
    case openingBalance = "opening balance"

    var displayName: String {
        switch self {
        case .withdrawal:
            return "Withdrawal"
        case .deposit:
            return "Deposit"
        case .transfer:
            return "Transfer"
        case .reconciliation:
            return "Reconciliation"
        case .openingBalance:
            return "Opening Balance"
        }
    }

    static var commonTypes: [Self] {
        [.withdrawal, .deposit, .transfer]
    }
}

// MARK: - Convenience Extensions

extension TransactionStore {
    static func createSingle(
        type: TransactionTypeProperty,
        date: String,
        amount: String,
        description: String,
        sourceID: String? = nil,
        sourceName: String? = nil,
        destinationID: String? = nil,
        destinationName: String? = nil,
        categoryID: String? = nil,
        categoryName: String? = nil
    ) -> TransactionStore {
        var split = TransactionSplitStore(
            type: type,
            date: date,
            amount: amount,
            description: description,
            categoryID: categoryID,
            categoryName: categoryName,
            sourceID: sourceID,
            sourceName: sourceName,
            destinationID: destinationID,
            destinationName: destinationName
        )

        return TransactionStore(transactions: [split])
    }
}

extension TransactionSplitStore {
    var isValid: Bool {
        !type.rawValue.isEmpty && !date.isEmpty && !amount.isEmpty && !description.isEmpty
    }
}
