//
//  Constants.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2023/10/20.
//

import Foundation

let API_TOKEN = "dummy"

let baseURL = "dummy.com"

struct UserDefaultKeys {
    static let apiTokenKey = "APIToken"
    static let baseURLKey = "DefaultURL"
}

struct apiPaths {
    static let userAbout = "api/v1/about/user"
    static let transactions = "api/v1/transactions"
    static let accounts = "api/v1/accounts"
    static func accountTransactions(_ id: String) -> String {
        return "api/v1/accounts/\(id)/transactions"
    }
    static let charts = "api/v1/chart/account/overview"
}

struct postApiPaths {
    static let addCategory = "api/v1/categories"
    static let addTransactions = "api/v1/transactions"
}

struct autocompleteApiPaths {
    static let categories = "api/v1/autocomplete/categories"
    static let accounts = "api/v1/autocomplete/accounts"
    static let budgets = "api/v1/autocomplete/budgets"
}

struct keychainConsts {
    static let account = "swiftFirefly"
    static let accessToken = "accessToken"
}
