import Foundation
import SwiftUI

/// A finished export, ready to hand to the share sheet.
struct ExportedFile: Identifiable {
    let url: URL

    var id: URL {
        url
    }
}

@MainActor
class SettingsViewModel: ObservableObject {
    @AppStorage(UserDefaultKeys.webviewsInline) var webviewsInline = false

    @Published var isExportingTransactions = false
    @Published var exportedTransactions: ExportedFile?
    @Published var exportErrorMessage: String?

    // MARK: - Settings Management

    /// Toggle webview settings - automatically persists to UserDefaults via @AppStorage
    func toggleWebviewSettings() {
        webviewsInline.toggle()
    }

    // MARK: - Export

    func exportAllTransactions() async {
        guard !isExportingTransactions else { return }
        isExportingTransactions = true
        defer { isExportingTransactions = false }

        do {
            exportedTransactions = try await ExportedFile(url: downloadAllTransactionsExport())
        } catch {
            AppLog.networkError("Failed to export transactions", error)
            exportErrorMessage = Self.exportErrorMessage(for: error)
        }
    }

    private static func exportErrorMessage(for error: Error) -> String {
        switch error {
        case RequestBuilderError.missingBaseURL, RequestBuilderError.missingToken:
            return "Add your server address and access token in Credentials first."
        case ExportError.invalidResponse(statusCode: 401):
            return "Your access token was rejected. Check it in Credentials."
        case let urlError as URLError where urlError.code == .timedOut:
            return "The server took too long to build the export. Try again, or use Export in the Firefly III web interface."
        default:
            return "Couldn't download the export from your server. Try again later."
        }
    }
}
