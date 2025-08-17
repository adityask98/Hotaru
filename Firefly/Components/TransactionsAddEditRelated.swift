//
//  TransactionsAddEditRelated.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2025/06/13.
//

import SwiftUI

enum TransactionType: String, CaseIterable, Identifiable {
  case withdrawal = "Withdrawal"
  case income = "Income"
  case transfer = "Transfer"

  var id: Self { self }

  var displayName: String {
    switch self {
    case .withdrawal: return "Withdrawal"
    case .income: return "Income"
    case .transfer: return "Transfer"
    }
  }

  var iconName: String {
    switch self {
    case .withdrawal: return "arrow.up.circle"
    case .income: return "arrow.down.circle"
    case .transfer: return "arrow.left.and.right.circle"
    }
  }
}
