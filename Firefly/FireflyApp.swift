//
//  FireflyApp.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2023/10/09.
//

@_exported import HotSwiftUI
import SwiftUI

@main
struct FireflyApp: App {
  @StateObject private var alertViewModel = AlertViewModel()
  @StateObject private var menuViewModel = MenuViewModel()
  @Environment(\.scenePhase) var scenePhase

  init() {
    #if DEBUG
      Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle")?.load()
      //for tvOS:
      Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/tvOSInjection.bundle")?.load()
      //Or for macOS:
      Bundle(path: "/Applications/InjectionIII.app/Contents/Resources/macOSInjection.bundle")?
        .load()
    #endif
  }

  var body: some Scene {
    WindowGroup {
      Menu()
        .preferredColorScheme(.dark)
        .environmentObject(alertViewModel)
        .environmentObject(menuViewModel)
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
    type: "addTransaction", localizedTitle: "Add Transaction", localizedSubtitle: "",
    icon: UIApplicationShortcutIcon(systemImageName: "plus.app.fill"), userInfo: [:])
  UIApplication.shared.shortcutItems = [addTransactionShortcut]
}
