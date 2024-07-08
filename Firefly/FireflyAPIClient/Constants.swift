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
    static func accountTransactions() -> String {
        return "api/v1/transactions"
    }
    static let accounts = "api/v1/accounts"
}

struct autocompleteApiPaths {
    static let categories = "api/v1/autocomplete/categories"
}

struct keychainConsts {
    static let account = "swiftFirefly"
    static let accessToken = "accessToken"
}
