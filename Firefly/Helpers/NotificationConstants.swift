import Foundation

/// Centralized notification constants for the app
/// Add new notifications here to keep them organized
enum AppNotifications {
    // Transaction notifications
    static let transactionDeleted = Notification.Name("transactionDeleted")
    static let transactionCreated = Notification.Name("transactionCreated")
    static let transactionUpdated = Notification.Name("transactionUpdated")

    /// Generic failure notification; AlertViewModel shows userInfo["message"] as a warning toast
    static let operationFailed = Notification.Name("operationFailed")

    // Safari notifications (defined in SafariHelper.swift)
    // - SafariErrorNotification
    // - SafariSuccessNotification
}
