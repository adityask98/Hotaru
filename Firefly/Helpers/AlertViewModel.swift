import AlertToast
import Combine
import Foundation
import SwiftUI

@MainActor
class AlertViewModel: ObservableObject {
    @Published var show = false
    @Published var alertToast = AlertToast(type: .regular, title: "SOME TITLE")

    private var cancellables: Set<AnyCancellable> = []

    init() {
        setupAllNotificationListeners()
    }

    // MARK: - Notification Setup

    /// Sets up all notification listeners for the app.
    /// To add a new listener, call `listen(for:style:)` below with the
    /// notification name; the notification's userInfo["message"] is shown as a toast.
    private func setupAllNotificationListeners() {
        // Safari notifications (defined in Firefly/Helpers/SafariHelper.swift)
        listen(for: SafariErrorNotification, style: .warning)
        listen(for: SafariSuccessNotification, style: .success)

        // Transaction notifications (defined in Firefly/Helpers/NotificationConstants.swift)
        listen(for: AppNotifications.transactionUpdated, style: .success)

        // Generic failures (e.g. a scheduled delete that failed server-side)
        listen(for: AppNotifications.operationFailed, style: .warning)
    }

    private enum ToastStyle {
        case success
        case warning
    }

    /// Shows a toast whenever `name` is posted with a userInfo["message"] string.
    /// The message is extracted before hopping to the main actor so the listener
    /// is safe regardless of which thread posts the notification.
    private func listen(for name: Notification.Name, style: ToastStyle) {
        NotificationCenter.default.publisher(for: name)
            .sink { [weak self] notification in
                guard let message = notification.userInfo?["message"] as? String else { return }
                Task { @MainActor [weak self] in
                    switch style {
                    case .success:
                        self?.showSuccess(message: message)
                    case .warning:
                        self?.showWarning(message: message)
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Alert Display Methods

    /// Show Success Message
    func showSuccess(
        message: String,
        displayMode: AlertToast.DisplayMode? = .alert,
        type: AlertToast.AlertType? = .complete(Color.green),
        subtitle: String? = nil
    ) {
        alertToast = AlertToast(
            displayMode: displayMode ?? .alert,
            type: type ?? .complete(Color.green),
            title: message,
            subTitle: subtitle
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
