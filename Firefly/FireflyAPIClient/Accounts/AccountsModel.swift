//
//  AccountsModel.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2023/10/16.
//

import Foundation 

struct AccountData: Codable {
    let data: AccountsDataClass
}

struct AccountsDataClass: Codable {
    let type, id: String
    let attributes: AccountsAttributes
}

struct AccountsAttributes: Codable {
    let createdAt, updatedAt: Date
    let active: Bool
    let order: Int
    let name, type, accountRole, currencyID: String
    let currencyCode, currencySymbol: String
    let currencyDecimalPlaces: Int
    let currentBalance: String
    let currentBalanceDate: Date
    let iban, bic, accountNumber, openingBalance: String
    let currentDebt: String
    let openingBalanceDate: Date
    let virtualBalance: String
    let includeNetWorth: Bool
    let creditCardType: String
    let monthlyPaymentDate: Date
    let liabilityType, liabilityDirection, interest, interestPeriod: String
    let notes: String
    let latitude, longitude: Double
    let zoomLevel: Int

    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case active, order, name, type
        case accountRole = "account_role"
        case currencyID = "currency_id"
        case currencyCode = "currency_code"
        case currencySymbol = "currency_symbol"
        case currencyDecimalPlaces = "currency_decimal_places"
        case currentBalance = "current_balance"
        case currentBalanceDate = "current_balance_date"
        case iban, bic
        case accountNumber = "account_number"
        case openingBalance = "opening_balance"
        case currentDebt = "current_debt"
        case openingBalanceDate = "opening_balance_date"
        case virtualBalance = "virtual_balance"
        case includeNetWorth = "include_net_worth"
        case creditCardType = "credit_card_type"
        case monthlyPaymentDate = "monthly_payment_date"
        case liabilityType = "liability_type"
        case liabilityDirection = "liability_direction"
        case interest
        case interestPeriod = "interest_period"
        case notes, latitude, longitude
        case zoomLevel = "zoom_level"
    }
}

struct AccountsMeta: Codable {
    let  pagination: AccountsPagination
}

struct AccountsPagination: Codable {
    let total, count, perPage, currentPage: Int
        let totalPages: Int

        enum CodingKeys: String, CodingKey {
            case total, count
            case perPage = "per_page"
            case currentPage = "current_page"
            case totalPages = "total_pages"
        }
}

