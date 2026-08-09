import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    var menuViewModel: MenuViewModel?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        updateShortcutItems()
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            handleShortcutItem(shortcutItem)
        }

        let sceneConfiguration = UISceneConfiguration(
            name: "Default Configuration",
            sessionRole: connectingSceneSession.role
        )
        sceneConfiguration.delegateClass = SceneDelegate.self
        return sceneConfiguration
    }

    private func handleShortcutItem(_ shortcutItem: UIApplicationShortcutItem) {
        if shortcutItem.type == "addTransaction" {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.5))
                self.menuViewModel?.openTransactionSheet()
            }
        }
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        if shortcutItem.type == "addTransaction" {
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                appDelegate.menuViewModel?.openTransactionSheet()
                completionHandler(true)
                return
            }
        }
        completionHandler(false)
    }
}

@main
struct FireflyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var alertViewModel = AlertViewModel()
    @StateObject private var menuViewModel = MenuViewModel()
    @StateObject private var pendingDeleteManager = PendingDeleteManager()
    @Environment(\.scenePhase) var scenePhase
    @AppStorage(UserDefaultKeys.selectedTheme) private var selectedTheme: ThemeMode = .system

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(colorScheme)
                .environmentObject(alertViewModel)
                .environmentObject(menuViewModel)
                .environmentObject(pendingDeleteManager)
                .toast(isPresenting: $alertViewModel.show, alert: { alertViewModel.alertToast })
                .onAppear {
                    appDelegate.menuViewModel = menuViewModel
                }
        }.onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                break
            case .inactive:
                break
            case .background:
                // Commit any pending delete so it isn't lost if the app is killed
                pendingDeleteManager.commitNow()
                updateShortcutItems()
            @unknown default:
                break
            }
        }
    }

    private var colorScheme: ColorScheme? {
        switch selectedTheme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}

func updateShortcutItems() {
    let addTransactionShortcut = UIApplicationShortcutItem(
        type: "addTransaction",
        localizedTitle: "Add Transaction",
        localizedSubtitle: "",
        icon: UIApplicationShortcutIcon(systemImageName: "plus.app.fill"),
        userInfo: [:]
    )
    UIApplication.shared.shortcutItems = [addTransactionShortcut]
}
