//
//  ToastHandler.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/06/14.
//

import AlertToast
import Foundation
import SwiftUI

class AlertViewModel: ObservableObject {
  @Published var show: Bool = false
  @Published var alertToast = AlertToast(type: .regular, title: "SOME TITLE")

  // Show Success Message
  func showSuccess(message: String) {
    alertToast = AlertToast(
      displayMode: .alert,
      type: .complete(Color.green),
      title: message
    )
    show = true
  }

  func showWarning(message: String) {
    alertToast = AlertToast(
      displayMode: .alert,
      type: .systemImage("exclamationmark.triangle", Color.orange),
      title: message
    )
    show = true
  }
}
