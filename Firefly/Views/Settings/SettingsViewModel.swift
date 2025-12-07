import Foundation
import SwiftUI

class SettingsViewModel: ObservableObject {
    @AppStorage(UserDefaultKeys.webviewsInline) var webviewsInline = false

    // MARK: - Settings Management

    /// Toggle webview settings - automatically persists to UserDefaults via @AppStorage
    func toggleWebviewSettings() {
        webviewsInline.toggle()
    }
}
