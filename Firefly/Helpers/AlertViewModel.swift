import AlertToast
import Foundation
import SwiftUI

class AlertViewModel: ObservableObject {
    @Published var show = false
    @Published var alertToast = AlertToast(type: .regular, title: "SOME TITLE")

    init() {
        setupAllNotificationListeners()
    }

    // MARK: - Notification Setup

    /// Sets up all notification listeners for the app
    /// To add a new listener:
    /// 1. Create notification constant in your helper file (e.g., let MyFeatureErrorNotification =
    /// Notification.Name("MyFeatureErrorNotification"))
    /// 2. Add a new addObserver call below with a unique selector
    /// 3. Create the corresponding @objc handler method
    /// 4. Call setupMyFeatureNotificationListeners() from this method
    private func setupAllNotificationListeners() {
        setupSafariNotificationListeners()
        // Add more notification listeners here as features grow:
        // setupMyFeatureNotificationListeners()
        // setupAnotherFeatureNotificationListeners()
    }

    // MARK: - Safari Notifications

    /// Listens for Safari-related errors and success notifications
    /// Notifications defined in: Firefly/Helpers/SafariHelper.swift
    private func setupSafariNotificationListeners() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSafariError(_:)),
            name: SafariErrorNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSafariSuccess(_:)),
            name: SafariSuccessNotification,
            object: nil
        )
    }

    @objc
    private func handleSafariError(_ notification: Notification) {
        if let message = notification.userInfo?["message"] as? String {
            showWarning(message: message)
        }
    }

    @objc
    private func handleSafariSuccess(_ notification: Notification) {
        if let message = notification.userInfo?["message"] as? String {
            showSuccess(message: message)
        }
    }

    // MARK: - Example: Adding a New Feature's Notifications

    /// To add notifications from another source, follow this pattern:
    ///
    /// 1. In your helper file (e.g., MyFeatureHelper.swift), define:
    ///    let MyFeatureErrorNotification = Notification.Name("MyFeatureErrorNotification")
    ///    let MyFeatureSuccessNotification = Notification.Name("MyFeatureSuccessNotification")
    ///
    /// 2. Post the notification from your helper:
    ///    NotificationCenter.default.post(name: MyFeatureErrorNotification, object: nil, userInfo: ["message": "Error
    /// occurred"])
    ///
    /// 3. Add a setup function here:
    ///    private func setupMyFeatureNotificationListeners() {
    ///        NotificationCenter.default.addObserver(
    ///            self,
    ///            selector: #selector(handleMyFeatureError(_:)),
    ///            name: MyFeatureErrorNotification,
    ///            object: nil
    ///        )
    ///        // ... more observers
    ///    }
    ///
    /// 4. Add the handler method:
    ///    @objc private func handleMyFeatureError(_ notification: Notification) {
    ///        if let message = notification.userInfo?["message"] as? String {
    ///            showWarning(message: message)
    ///        }
    ///    }
    ///
    /// 5. Call it from setupAllNotificationListeners()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Alert Display Methods

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
