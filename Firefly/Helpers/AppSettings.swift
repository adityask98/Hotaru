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

    /// Whether "load more" fetches additional pages when scrolling transaction lists.
    /// Some self-hosted servers report the wrong scheme/host in pagination links (e.g. a
    /// reverse proxy that isn't configured to report HTTPS to Firefly), which breaks
    /// load-more with an auth error. Defaults to on; disable as a stopgap until the
    /// server side is fixed.
    static var paginationEnabled: Bool {
        get {
            UserDefaults.standard.object(forKey: UserDefaultKeys.paginationEnabled) as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultKeys.paginationEnabled)
        }
    }

    /// Whether new transactions record where they were created (beta).
    ///
    /// Firefly III has no supported way to set a transaction's location, so this stores it as a
    /// marker line inside the notes field instead — see `docs/LOCATION_IN_NOTES.md`. Defaults to on;
    /// turning it off hides the option on the create screen entirely and stops any location capture.
    /// Note this is only the master switch — the create screen still needs the system location
    /// permission, and offers a per-transaction toggle on top of this.
    static var attachLocationToTransactions: Bool {
        get {
            UserDefaults.standard.object(forKey: UserDefaultKeys.attachLocationToTransactions)
                as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(
                newValue, forKey: UserDefaultKeys.attachLocationToTransactions
            )
        }
    }
}
