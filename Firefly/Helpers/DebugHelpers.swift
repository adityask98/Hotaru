import Foundation
import os

/// Central loggers for the app.
///
/// Use these instead of `print` so nothing sensitive lands in the device console:
/// values interpolated with `privacy: .private` are redacted in release/console
/// output but fully visible while attached to the Xcode debugger.
enum AppLog {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.adityask.hotaru"

    static let network = Logger(subsystem: subsystem, category: "network")
    static let app = Logger(subsystem: subsystem, category: "app")

    /// Logs a network/API failure. The error detail (which can contain URLs,
    /// decoding key paths, or response fragments) is redacted outside the debugger.
    static func networkError(_ message: String, _ error: Error) {
        network.error("\(message): \(String(describing: error), privacy: .private)")
    }

    /// Logs an app-level (non-network) failure with redacted detail.
    static func appError(_ message: String, _ error: Error) {
        app.error("\(message): \(String(describing: error), privacy: .private)")
    }
}
