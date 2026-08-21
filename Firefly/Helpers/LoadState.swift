import Foundation

/// Load state for one independently-fetched piece of a screen.
///
/// Screens that fetch several things at once (the Home dashboard) keep one of
/// these per section, so a single failed call renders one section's error rather
/// than blanking the whole page.
enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(String)

    var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var errorMessage: String? {
        if case .failed(let message) = self { return message }
        return nil
    }

    /// True before anything has ever loaded — used to decide between a spinner
    /// and keeping stale content on screen during a refresh.
    var hasValue: Bool {
        value != nil
    }
}
