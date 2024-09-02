//
//  CommonFunctions.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/11.
//

import Foundation
import SwiftUI

func formatAmount(_ amount: String, symbol: String?) -> String {
    guard let doubleAmount = Double(amount) else {
        return "Unknown Amount"
    }
    return formatAmount(Decimal(doubleAmount), symbol: symbol)
}

func formatAmount(_ amount: Decimal, symbol: String?) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencySymbol = symbol ?? "¥"
    return formatter.string(from: amount as NSNumber) ?? "Unknown Amount"
}

//Check if a transaction is a split transaction by counting the number of attributes.transactions
func isSplitTransaction(_ transaction: TransactionsDatum) -> Bool {
    return transaction.attributes?.transactions?.count ?? 1 > 1
}

func isSplitTransaction(_ postTransaction: PostTransaction) -> Bool {
    return postTransaction.transactions?.count ?? 1 > 1
}

//Title for the transaction.
func transactionMainTitle(_ transaction: TransactionsDatum) -> String {
    if isSplitTransaction(transaction) {
        if let groupTitle = transaction.attributes?.groupTitle, !groupTitle.isEmpty {
            return groupTitle
        }
    }

    return transaction.attributes?.transactions?.first?.description ?? "Unknown Description"
}

func calculateTransactionTotalAmount(_ transaction: TransactionsDatum) -> Decimal {
    guard let transactions = transaction.attributes?.transactions else {
        return 0
    }

    let total = transactions.reduce(Decimal.zero) { sum, transaction in
        sum + (Decimal(string: transaction.amount ?? "0") ?? 0)
    }

    return total
}

func transactionTypeIcon(_ type: String) -> String {
    switch type {
    case "withdrawal":
        return "arrowshape.down.circle.fill"
    case "transfer":
        return "arrow.left.arrow.right.circle.fill"
    case "deposit":
        return "arrowshape.up.circle.fill"
    default:
        return "circle.badge.questionmark.fill"
    }
}
func transactionTypeStyle(_ type: String) -> LinearGradient {
    switch type {
    case "withdrawal":
        return LinearGradient(
            gradient: Gradient(colors: [Color.red.opacity(0.6), .red]),
            startPoint: .leading, endPoint: .trailing)
    case "deposit":
        return LinearGradient(
            gradient: Gradient(colors: [Color.green.opacity(0.6), .green]),
            startPoint: .leading, endPoint: .trailing)
    case "transfer":
        return LinearGradient(
            gradient: Gradient(colors: [Color.blue.opacity(0.6), .blue]),
            startPoint: .leading, endPoint: .trailing)
    default:
        return LinearGradient(
            gradient: Gradient(colors: [Color.gray.opacity(0.6), .gray]),
            startPoint: .leading, endPoint: .trailing)
    }
}

func transactionTypeColor(type: String) -> Color {
    switch type {
    case "withdrawal":
        return .red
    case "deposit":
        return .green
    case "transfer":
        return .blue
    default:
        return .gray
    }
}

func doThisAfter(_ seconds: CGFloat, callback: @escaping () -> Void) {
    return DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        callback()
    }
}

func formatAmountForTextField(_ amountString: String, decimalPlace: Int) -> String {
    guard let amount = Double(amountString) else {
     return ""
    }
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = decimalPlace
    return formatter.string(from: NSNumber(value: amount)) ?? ""
}
