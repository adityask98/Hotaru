import Foundation

// MARK: - Transactions
struct Transactions: Codable {
    var data: [TransactionsDatum]?
    var meta: TransactionsMeta?
    var links: TransactionsLinks?
}

// MARK: - TransactionsDatum
struct TransactionsDatum: Codable {
    let type, id: String?
    let attributes: TransactionsAttributes?
    let links: TransactionsDatumLinks?
}

// MARK: - TransactionsAttributes
struct TransactionsAttributes: Codable {
    let createdAt, updatedAt, user: String?
    let groupTitle: String?
    let transactions: [TransactionsTransaction]?

    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
        case groupTitle = "group_title"
        case transactions
    }
}

// MARK: - TransactionsTransaction
struct TransactionsTransaction: Codable {
    let user, transactionJournalID, type, date: String?
    let order: Int?
    let currencyID, currencyCode, currencyName, currencySymbol: String?
    let currencyDecimalPlaces: Int?
    let foreignCurrencyID, foreignCurrencyCode, foreignCurrencySymbol: JSONNull?
    let foreignCurrencyDecimalPlaces: Int?
    let amount: String?
    let foreignAmount: JSONNull?
    let description, sourceID, sourceName: String?
    let sourceIban: String?
    let sourceType, destinationID, destinationName: String?
    let destinationIban: String?
    let destinationType: String?
    let budgetID, budgetName: String?
    let categoryID, categoryName: String?
    let billID, billName: String?
    let reconciled: Bool?
    let notes: String?
    let tags: [String]?
    let internalReference, externalID: JSONNull?
    let originalSource: String?
    let recurrenceID: String?
    let recurrenceTotal, recurrenceCount, bunqPaymentID: Int?
    let externalURL: String?
    let importHashV2: String?
    let sepaCc, sepaCTOp, sepaCTID, sepaDB: JSONNull?
    let sepaCountry, sepaEp, sepaCi, sepaBatchID: JSONNull?
    let interestDate, bookDate, processDate, dueDate: JSONNull?
    let paymentDate, invoiceDate, longitude, latitude: JSONNull?
    let zoomLevel: JSONNull?
    let hasAttachments: Bool?

    enum CodingKeys: String, CodingKey {
        case user
        case transactionJournalID = "transaction_journal_id"
        case type, date, order
        case currencyID = "currency_id"
        case currencyCode = "currency_code"
        case currencyName = "currency_name"
        case currencySymbol = "currency_symbol"
        case currencyDecimalPlaces = "currency_decimal_places"
        case foreignCurrencyID = "foreign_currency_id"
        case foreignCurrencyCode = "foreign_currency_code"
        case foreignCurrencySymbol = "foreign_currency_symbol"
        case foreignCurrencyDecimalPlaces = "foreign_currency_decimal_places"
        case amount
        case foreignAmount = "foreign_amount"
        case description
        case sourceID = "source_id"
        case sourceName = "source_name"
        case sourceIban = "source_iban"
        case sourceType = "source_type"
        case destinationID = "destination_id"
        case destinationName = "destination_name"
        case destinationIban = "destination_iban"
        case destinationType = "destination_type"
        case budgetID = "budget_id"
        case budgetName = "budget_name"
        case categoryID = "category_id"
        case categoryName = "category_name"
        case billID = "bill_id"
        case billName = "bill_name"
        case reconciled, notes, tags
        case internalReference = "internal_reference"
        case externalID = "external_id"
        case originalSource = "original_source"
        case recurrenceID = "recurrence_id"
        case recurrenceTotal = "recurrence_total"
        case recurrenceCount = "recurrence_count"
        case bunqPaymentID = "bunq_payment_id"
        case externalURL = "external_url"
        case importHashV2 = "import_hash_v2"
        case sepaCc = "sepa_cc"
        case sepaCTOp = "sepa_ct_op"
        case sepaCTID = "sepa_ct_id"
        case sepaDB = "sepa_db"
        case sepaCountry = "sepa_country"
        case sepaEp = "sepa_ep"
        case sepaCi = "sepa_ci"
        case sepaBatchID = "sepa_batch_id"
        case interestDate = "interest_date"
        case bookDate = "book_date"
        case processDate = "process_date"
        case dueDate = "due_date"
        case paymentDate = "payment_date"
        case invoiceDate = "invoice_date"
        case longitude, latitude
        case zoomLevel = "zoom_level"
        case hasAttachments = "has_attachments"
    }
}

// MARK: - TransactionsDatumLinks
struct TransactionsDatumLinks: Codable {
    let the0: TransactionsThe0?
    let linksSelf: String?

    enum CodingKeys: String, CodingKey {
        case the0 = "0"
        case linksSelf = "self"
    }
}

// MARK: - TransactionsThe0
struct TransactionsThe0: Codable {
    let rel, uri: String?
}

// MARK: - TransactionsLinks
struct TransactionsLinks: Codable {
    let linksSelf, first, next, last: String?

    enum CodingKeys: String, CodingKey {
        case linksSelf = "self"
        case first, next, last
    }
}

// MARK: - TransactionsMeta
struct TransactionsMeta: Codable {
    let pagination: TransactionsPagination?
}

// MARK: - TransactionsPagination
struct TransactionsPagination: Codable {
    let total, count, perPage, currentPage: Int?
    let totalPages: Int?

    enum CodingKeys: String, CodingKey {
        case total, count
        case perPage = "per_page"
        case currentPage = "current_page"
        case totalPages = "total_pages"
    }
}

// MARK: - Encode/decode helpers

class JSONNull: Codable, Hashable {

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }

    public var hashValue: Int {
        return 0
    }

    public init() {}

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(
                JSONNull.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

class JSONCodingKey: CodingKey {
    let key: String

    required init?(intValue: Int) {
        return nil
    }

    required init?(stringValue: String) {
        key = stringValue
    }

    var intValue: Int? {
        return nil
    }

    var stringValue: String {
        return key
    }
}

class JSONAny: Codable {

    let value: Any

    static func decodingError(forCodingPath codingPath: [CodingKey]) -> DecodingError {
        let context = DecodingError.Context(
            codingPath: codingPath, debugDescription: "Cannot decode JSONAny")
        return DecodingError.typeMismatch(JSONAny.self, context)
    }

    static func encodingError(forValue value: Any, codingPath: [CodingKey]) -> EncodingError {
        let context = EncodingError.Context(
            codingPath: codingPath, debugDescription: "Cannot encode JSONAny")
        return EncodingError.invalidValue(value, context)
    }

    static func decode(from container: SingleValueDecodingContainer) throws -> Any {
        if let value = try? container.decode(Bool.self) {
            return value
        }
        if let value = try? container.decode(Int64.self) {
            return value
        }
        if let value = try? container.decode(Double.self) {
            return value
        }
        if let value = try? container.decode(String.self) {
            return value
        }
        if container.decodeNil() {
            return JSONNull()
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(from container: inout UnkeyedDecodingContainer) throws -> Any {
        if let value = try? container.decode(Bool.self) {
            return value
        }
        if let value = try? container.decode(Int64.self) {
            return value
        }
        if let value = try? container.decode(Double.self) {
            return value
        }
        if let value = try? container.decode(String.self) {
            return value
        }
        if let value = try? container.decodeNil() {
            if value {
                return JSONNull()
            }
        }
        if var container = try? container.nestedUnkeyedContainer() {
            return try decodeArray(from: &container)
        }
        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self) {
            return try decodeDictionary(from: &container)
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decode(
        from container: inout KeyedDecodingContainer<JSONCodingKey>, forKey key: JSONCodingKey
    ) throws -> Any {
        if let value = try? container.decode(Bool.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Int64.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Double.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(String.self, forKey: key) {
            return value
        }
        if let value = try? container.decodeNil(forKey: key) {
            if value {
                return JSONNull()
            }
        }
        if var container = try? container.nestedUnkeyedContainer(forKey: key) {
            return try decodeArray(from: &container)
        }
        if var container = try? container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
        {
            return try decodeDictionary(from: &container)
        }
        throw decodingError(forCodingPath: container.codingPath)
    }

    static func decodeArray(from container: inout UnkeyedDecodingContainer) throws -> [Any] {
        var arr: [Any] = []
        while !container.isAtEnd {
            let value = try decode(from: &container)
            arr.append(value)
        }
        return arr
    }

    static func decodeDictionary(from container: inout KeyedDecodingContainer<JSONCodingKey>) throws
        -> [String: Any]
    {
        var dict = [String: Any]()
        for key in container.allKeys {
            let value = try decode(from: &container, forKey: key)
            dict[key.stringValue] = value
        }
        return dict
    }

    static func encode(to container: inout UnkeyedEncodingContainer, array: [Any]) throws {
        for value in array {
            if let value = value as? Bool {
                try container.encode(value)
            } else if let value = value as? Int64 {
                try container.encode(value)
            } else if let value = value as? Double {
                try container.encode(value)
            } else if let value = value as? String {
                try container.encode(value)
            } else if value is JSONNull {
                try container.encodeNil()
            } else if let value = value as? [Any] {
                var container = container.nestedUnkeyedContainer()
                try encode(to: &container, array: value)
            } else if let value = value as? [String: Any] {
                var container = container.nestedContainer(keyedBy: JSONCodingKey.self)
                try encode(to: &container, dictionary: value)
            } else {
                throw encodingError(forValue: value, codingPath: container.codingPath)
            }
        }
    }

    static func encode(
        to container: inout KeyedEncodingContainer<JSONCodingKey>, dictionary: [String: Any]
    ) throws {
        for (key, value) in dictionary {
            let key = JSONCodingKey(stringValue: key)!
            if let value = value as? Bool {
                try container.encode(value, forKey: key)
            } else if let value = value as? Int64 {
                try container.encode(value, forKey: key)
            } else if let value = value as? Double {
                try container.encode(value, forKey: key)
            } else if let value = value as? String {
                try container.encode(value, forKey: key)
            } else if value is JSONNull {
                try container.encodeNil(forKey: key)
            } else if let value = value as? [Any] {
                var container = container.nestedUnkeyedContainer(forKey: key)
                try encode(to: &container, array: value)
            } else if let value = value as? [String: Any] {
                var container = container.nestedContainer(keyedBy: JSONCodingKey.self, forKey: key)
                try encode(to: &container, dictionary: value)
            } else {
                throw encodingError(forValue: value, codingPath: container.codingPath)
            }
        }
    }

    static func encode(to container: inout SingleValueEncodingContainer, value: Any) throws {
        if let value = value as? Bool {
            try container.encode(value)
        } else if let value = value as? Int64 {
            try container.encode(value)
        } else if let value = value as? Double {
            try container.encode(value)
        } else if let value = value as? String {
            try container.encode(value)
        } else if value is JSONNull {
            try container.encodeNil()
        } else {
            throw encodingError(forValue: value, codingPath: container.codingPath)
        }
    }

    public required init(from decoder: Decoder) throws {
        if var arrayContainer = try? decoder.unkeyedContainer() {
            self.value = try JSONAny.decodeArray(from: &arrayContainer)
        } else if var container = try? decoder.container(keyedBy: JSONCodingKey.self) {
            self.value = try JSONAny.decodeDictionary(from: &container)
        } else {
            let container = try decoder.singleValueContainer()
            self.value = try JSONAny.decode(from: container)
        }
    }

    public func encode(to encoder: Encoder) throws {
        if let arr = self.value as? [Any] {
            var container = encoder.unkeyedContainer()
            try JSONAny.encode(to: &container, array: arr)
        } else if let dict = self.value as? [String: Any] {
            var container = encoder.container(keyedBy: JSONCodingKey.self)
            try JSONAny.encode(to: &container, dictionary: dict)
        } else {
            var container = encoder.singleValueContainer()
            try JSONAny.encode(to: &container, value: self.value)
        }
    }
}
// MARK: - PostTransaction
struct PostTransaction: Codable {
    var errorIfDuplicateHash, applyRules, fireWebhooks: Bool?
    var groupTitle: String?
    var transactions: [PostTransactionElement]?

    enum CodingKeys: String, CodingKey {
        case errorIfDuplicateHash = "error_if_duplicate_hash"
        case applyRules = "apply_rules"
        case fireWebhooks = "fire_webhooks"
        case groupTitle = "group_title"
        case transactions
    }
}

// MARK: - PostTransactionElement
struct PostTransactionElement: Codable {
    var type, date, amount, description: String?
    var order: Int?
    var currencyID, currencyCode, foreignAmount, foreignCurrencyID: String?
    var foreignCurrencyCode, budgetID, categoryID, categoryName: String?
    var sourceID, sourceName, destinationID, destinationName: String?
    var reconciled: Bool?
    var piggyBankID: Int?
    var piggyBankName, billID, billName: String?
    var tags: JSONNull?
    var notes, internalReference, externalID, externalURL: String?
    var bunqPaymentID, sepaCc, sepaCTOp, sepaCTID: String?
    var sepaDB, sepaCountry, sepaEp, sepaCi: String?
    var sepaBatchID, interestDate, bookDate, processDate: String?
    var dueDate, paymentDate, invoiceDate: String?
    var latitude, longitude: String?

    enum CodingKeys: String, CodingKey {
        case type, date, amount, description, order
        case currencyID = "currency_id"
        case currencyCode = "currency_code"
        case foreignAmount = "foreign_amount"
        case foreignCurrencyID = "foreign_currency_id"
        case foreignCurrencyCode = "foreign_currency_code"
        case budgetID = "budget_id"
        case categoryID = "category_id"
        case categoryName = "category_name"
        case sourceID = "source_id"
        case sourceName = "source_name"
        case destinationID = "destination_id"
        case destinationName = "destination_name"
        case reconciled
        case piggyBankID = "piggy_bank_id"
        case piggyBankName = "piggy_bank_name"
        case billID = "bill_id"
        case billName = "bill_name"
        case tags, notes
        case internalReference = "internal_reference"
        case externalID = "external_id"
        case externalURL = "external_url"
        case bunqPaymentID = "bunq_payment_id"
        case sepaCc = "sepa_cc"
        case sepaCTOp = "sepa_ct_op"
        case sepaCTID = "sepa_ct_id"
        case sepaDB = "sepa_db"
        case sepaCountry = "sepa_country"
        case sepaEp = "sepa_ep"
        case sepaCi = "sepa_ci"
        case sepaBatchID = "sepa_batch_id"
        case interestDate = "interest_date"
        case bookDate = "book_date"
        case processDate = "process_date"
        case dueDate = "due_date"
        case paymentDate = "payment_date"
        case invoiceDate = "invoice_date"
        case latitude, longitude
    }
}

func defaultTransactionData() -> PostTransaction {
    return PostTransaction(transactions: [PostTransactionElement()])
}
