//
//  FireflyApp.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2023/10/09.
//

import SwiftUI

@main
struct FireflyApp: App {
    @StateObject private var alertViewModel = AlertViewModel()
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            Menu()
                .preferredColorScheme(.dark)
                .environmentObject(alertViewModel)
                .toast(isPresenting: $alertViewModel.show, alert: { alertViewModel.alertToast })
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
}

func updateShortcutItems() {
    let addTransactionShortcut = UIApplicationShortcutItem(
        type: "addTransation", localizedTitle: "Add Transaction", localizedSubtitle: "",
        icon: UIApplicationShortcutIcon(systemImageName: "plus.app.fill"), userInfo: [:])
    UIApplication.shared.shortcutItems = [addTransactionShortcut]
}
