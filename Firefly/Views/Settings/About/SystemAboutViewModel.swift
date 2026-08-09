import Foundation

struct SystemInfo: Codable {
    let data: SystemInfoDataClass?
}

struct SystemInfoDataClass: Codable {
    let version: String?
    let apiVersion: String?
    let phpVersion: String?
    let os: String?
    let driver: String?

    enum CodingKeys: String, CodingKey {
        case version
        case apiVersion = "api_version"
        case phpVersion = "php_version"
        case os, driver
    }
}

enum SystemAboutError: LocalizedError {
    case invalidResponse
    case invalidData

    var errorDescription: String? {
        switch self {
        case .invalidResponse: "Couldn't reach the Firefly III server."
        case .invalidData: "Couldn't read the server's response."
        }
    }
}

/// Hotaru's own version/build — read once from the app bundle, not the network.
struct AppBuildInfo {
    let version: String
    let build: String

    static let current = AppBuildInfo(
        version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "-",
        build: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "-"
    )
}

@MainActor
class SystemAboutViewModel: ObservableObject {
    @Published var systemInfo: SystemInfoDataClass?
    @Published var isLoading = true
    @Published var errorMessage: String?

    let appInfo = AppBuildInfo.current
    /// The resolved server URL saved by `TokenSettings`, shown as-is (already normalized
    /// there). Reading it directly instead of re-deriving it keeps this in sync with
    /// whatever the user actually saved, including their chosen http/https scheme.
    let connectedURL = UserDefaults.standard.string(forKey: UserDefaultKeys.baseURLKey)

    private var fetchTask: Task<Void, Never>?

    func fetchSystemInfo() {
        errorMessage = nil
        fetchTask?.cancel()
        isLoading = true
        fetchTask = Task {
            do {
                try await performFetch()
                if Task.isCancelled { return }
            } catch {
                if Task.isCancelled { return }
                AppLog.networkError("Failed to fetch system info", error)
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    func performFetch() async throws {
        let request = try RequestBuilder(apiURL: ApiPaths.systemAbout)
        let (data, response) = try await AppNetworking.session.data(for: request)

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw SystemAboutError.invalidResponse
        }

        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(SystemInfo.self, from: data)
            systemInfo = result.data
            isLoading = false
        } catch {
            throw SystemAboutError.invalidData
        }
    }

    /// Plain-text summary for the "Copy Debug Info" button — useful when reporting a bug
    /// against a self-hosted server whose exact version/PHP/OS combo matters.
    var debugInfoText: String {
        """
        Hotaru \(appInfo.version) (\(appInfo.build))
        Firefly III \(systemInfo?.version ?? "-")
        PHP \(systemInfo?.phpVersion ?? "-")
        OS \(systemInfo?.os ?? "-")
        Driver \(systemInfo?.driver ?? "-")
        Server \(connectedURL ?? "-")
        """
    }
}
