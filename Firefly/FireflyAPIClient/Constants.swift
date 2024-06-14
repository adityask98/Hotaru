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
    static func accountTransactions(id: String) -> String {
           return "api/v1/accounts/\(id)/transactions"
       }
}

struct keychainConsts {
    static let account = "swiftFirefly"
    static let accessToken = "accessToken"
}
