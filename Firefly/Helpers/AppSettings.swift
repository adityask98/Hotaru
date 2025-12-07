import Foundation
import SwiftUI

/// Centralized app settings helper
/// Use this to read settings from anywhere in the app
enum AppSettings {
    /// Whether to open webviews inline (in-app) or in external Safari
    static var webviewsInline: Bool {
        get {
            UserDefaults.standard.bool(forKey: UserDefaultKeys.webviewsInline)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultKeys.webviewsInline)
        }
    }
}
