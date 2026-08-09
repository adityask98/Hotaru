import Foundation

/// Preserves the `Authorization` header across HTTP redirects to the same host.
///
/// `URLSession`'s default redirect handling strips sensitive headers (including
/// `Authorization`) whenever the redirect target's scheme or host differs from the
/// original request — by design, so credentials aren't leaked to an unintended host.
/// Some reverse-proxy setups redirect http -> https for the *same* host (e.g. when a
/// self-hosted Firefly III server's self-reported links don't match the scheme the
/// client actually used), which trips this safeguard and turns a valid token into a
/// 401. Re-attaching the header only when the host is unchanged keeps the safeguard
/// intact for redirects to a genuinely different host.
private final class AuthPreservingRedirectDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest
    ) async -> URLRequest? {
        guard let originalRequest = task.originalRequest,
              originalRequest.url?.host == request.url?.host,
              let authHeader = originalRequest.value(forHTTPHeaderField: "Authorization") else {
            return request
        }

        var redirectedRequest = request
        redirectedRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
        return redirectedRequest
    }
}

enum AppNetworking {
    /// Use this instead of `URLSession.shared` for Firefly API requests so a same-host
    /// scheme redirect (http -> https) doesn't silently drop the bearer token.
    static let session: URLSession = {
        let delegate = AuthPreservingRedirectDelegate()
        return URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
    }()
}
