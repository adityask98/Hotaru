//
//  TransactionDetailViewModel.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/07/28.
//

import AlertToast
import Foundation
import SwiftUI

struct TransactionDetailDatum: Codable {
  var data: TransactionsDatum?
}

final class TransactionDetailViewModel: ObservableObject {
  @Published var transaction: TransactionDetailDatum?
  @Published var isLoading: Bool = true
  @Published var isError: Bool = false
  @Published var errorMessage: String?
  @Published var showDeleteAlert = false
  @Published var showToast: Bool = false
  @Published var toastParams: AlertToast = AlertToast(displayMode: .hud, type: .error(Color.red))

  let transactionId: String

  init(transactionId: String) {
    self.transactionId = transactionId
  }

  func fetchTransaction() async {
    self.isLoading = true

    //Fetch single transaction
    do {
      self.transaction = try await getTransaction(transactionID: transactionId)
      self.isError = false
    } catch {
      self.isError = true
      self.errorMessage = error.localizedDescription
    }
    self.isLoading = false
  }

  func fetchTransactionOld(transactionID: String) async {
    self.isLoading = true
    do {
      self.transaction = try await getTransaction(transactionID: transactionID)
    } catch {
      toastParams = AlertToast(
        displayMode: .alert,
        type: .systemImage("exclamationmark.triangle.fill", Color.red),
        title: self.errorMessage)
      showToast = true
      print(error)
    }
    self.isLoading = false
  }

  func refreshTransaction() async {
    do {
      self.transaction = try await getTransaction(transactionID: transactionId)
      self.isError = false
    } catch {
      self.isError = true
      self.errorMessage = error.localizedDescription
    }
  }

  func refreshTransaction(transactionID: String) async {
    await fetchTransactionOld(transactionID: transactionID)
  }

  func deleteTransaction(transactionID: String) async throws {
    let request = try RequestBuilder(
      apiURL: apiPaths.transaction(transactionID), httpMethod: "DELETE")
    let (data, response) = try await URLSession.shared.data(for: request)
    //printResponse(data)

    guard let response = response as? HTTPURLResponse, response.statusCode == 204 else {
      let commonError = try ErrorDecoder(data)
      errorMessage = commonError.message ?? "Something went wrong"
      print(errorMessage as Any)
      throw TransactionsModelError.invalidResponse
    }
    print(response)
  }

  func getTransaction(transactionID: String) async throws -> TransactionDetailDatum {
    let request = try RequestBuilder(apiURL: apiPaths.transaction(transactionID))
    let (data, response) = try await URLSession.shared.data(for: request)

    guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
      throw TransactionsModelError.invalidResponse
    }

    do {
      let decoder = JSONDecoder()
      let result = try decoder.decode(TransactionDetailDatum.self, from: data)
      //            if let str = String(data: data, encoding: .utf8) {
      //                print("Successfully decoded: \(str)")
      //            }
      //print(result)
      return result
    } catch {
      print(error)
      throw TransactionsModelError.invalidData
    }
  }
}
