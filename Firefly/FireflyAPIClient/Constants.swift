import Foundation

let apiToken = "dummy"

let baseURL = "dummy.com"

enum UserDefaultKeys {
    static let apiTokenKey = "APIToken"
    static let baseURLKey = "DefaultURL"
    static let fireWebhooks = "FireWebhooks"
}

enum ApiPaths {
    static let systemAbout = "api/v1/about"
    static let userAbout = "api/v1/about/user"
    static let transactions = "api/v1/transactions"
    static let accounts = "api/v1/accounts"
    static let categories = "api/v1/categories"
    static func account(_ id: String) -> String {
        return "api/v1/accounts/\(id)"
    }

    static func accountTransactions(_ id: String) -> String {
        return "api/v1/accounts/\(id)/transactions"
    }

    static let charts = "api/v1/chart/account/overview"
    static func transaction(_ id: String) -> String {
        return "api/v1/transactions/\(id)"
    }

    static func category(_ id: String) -> String {
        return "api/v1/categories/\(id)"
    }

    static func categoryTransactions(_ id: String) -> String {
        return "api/v1/categories/\(id)/transactions"
    }

    static let searchTransactions = "api/v1/search/transactions"
}

enum PostApiPaths {
    static let addCategory = "api/v1/categories"
    static let addTransactions = "api/v1/transactions"
}

enum PutApiPaths {
    static func editTransaction(_ id: String) -> String {
        return "api/v1/transactions/\(id)"
    }
}

enum AutocompleteApiPaths {
    static let categories = "api/v1/autocomplete/categories"
    static let accounts = "api/v1/autocomplete/accounts"
    static let budgets = "api/v1/autocomplete/budgets"
    static let currencies = "api/v1/autocomplete/currencies"
    static let transactions = "api/v1/autocomplete/transactions"
}

enum KeychainConsts {
    static let account = "swiftFirefly"
    static let accessToken = "accessToken"
}

enum InsightsApiPaths {
    static let expenseCategories = "api/v1/insight/expense/category"
}

enum ChartsApiPaths {
    static let overview = "api/v1/chart/account/overview"
}

enum WebviewPaths {
    static func transaction(_ id: String) -> String {
        return "transactions/show/\(id)"
    }
}
