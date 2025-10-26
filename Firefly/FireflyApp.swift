import SwiftUI

@main
struct FireflyApp: App {
    @StateObject private var alertViewModel = AlertViewModel()
    @StateObject private var menuViewModel = MenuViewModel()
    @Environment(\.scenePhase) var scenePhase
    @AppStorage("selectedTheme") private var selectedTheme: ThemeMode = .system

    var body: some Scene {
        WindowGroup {
            Menu()
                .preferredColorScheme(colorScheme)
                .environmentObject(alertViewModel)
                .environmentObject(menuViewModel)
                .toast(isPresenting: $alertViewModel.show, alert: { alertViewModel.alertToast })
                .onOpenURL { url in
                    if url.scheme == "shortcut" && url.host == "addTransaction" {
                        menuViewModel.openTransactionSheet()
                    }
                }
        }.onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                break
            case .inactive:
                break
            case .background:
                print("Background phase")
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
