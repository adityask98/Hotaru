import Foundation
import SafariServices
import SwiftUI

// MARK: - Settings Access

/// Access app settings via AppSettings.swift
/// AppSettings uses @AppStorage for automatic UserDefaults persistence

// MARK: - Notifications

let SafariErrorNotification = Notification.Name("SafariErrorNotification")
let SafariSuccessNotification = Notification.Name("SafariSuccessNotification")

/// Builds and opens a Safari URL by combining the saved base URL with the provided API path
/// Errors and success are broadcast via NotificationCenter for global error handling
/// - Parameters:
///   - apiURL: The API path to append to the base URL
///   - openURL: The SwiftUI environment action for opening URLs
/// - Returns: `true` if the URL was successfully opened, `false` otherwise
@discardableResult
func SafariBuilder(apiURL: String, openURL: OpenURLAction) -> Bool {
    guard let baseURL = UserDefaults.standard.string(forKey: UserDefaultKeys.baseURLKey) else {
        let errorMessage = "Failed to get baseURL from UserDefaults"
        NotificationCenter.default.post(
            name: SafariErrorNotification, object: nil, userInfo: ["message": errorMessage]
        )
        print(errorMessage)
        return false
    }

    let fullURLString = baseURL + apiURL

    // Read the webviewsInline setting - automatically synced via @AppStorage
    let prefersInApp = AppSettings.webviewsInline

    guard let url = URL(string: fullURLString) else {
        let errorMessage = "Failed to construct valid URL from: \(fullURLString)"
        NotificationCenter.default.post(
            name: SafariErrorNotification, object: nil, userInfo: ["message": errorMessage]
        )
        print(errorMessage)
        return false
    }

    openURL(url, prefersInApp: prefersInApp)
    return true
}

struct WebviewButton: View {
    @Environment(\.openURL) var openURL
    var label: String?
    var systemImage: String?
    var url: String?

    var body: some View {
        Button(label ?? "Open Webview", systemImage: systemImage ?? "safari") {
            if let url {
                SafariBuilder(apiURL: url, openURL: openURL)
            } else {
                NotificationCenter.default.post(
                    name: SafariErrorNotification, object: nil, userInfo: ["message": "Something went wrong."]
                )
            }
        }
    }
}
