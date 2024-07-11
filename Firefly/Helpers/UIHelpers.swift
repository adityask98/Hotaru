//
//  CommonFunctions.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/11.
//

import Foundation
import SwiftUI

func formatAmount(_ amountString: String?, symbol: String?) -> String {
    guard let amountString = amountString,
        let amount = Double(amountString)
    else {
        return "Unknown Amount"
    }
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencySymbol = symbol ?? "¥"
    return formatter.string(from: NSNumber(value: amount)) ?? "Unknown Amount"
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
