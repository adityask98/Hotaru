//
//  Menu.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2023/11/26.
//

import AlertToast
import SwiftUI

struct Menu: View {

  init() {
    let appearance = UITabBarAppearance()
    appearance.configureWithTransparentBackground()

    // If you want a blur effect
    appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)

    // Customize the color to make it more or less translucent
    appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.5)

    // Use this appearance for both standard and scrolled content
    UITabBar.appearance().standardAppearance = appearance
    if #available(iOS 15.0, *) {
      UITabBar.appearance().scrollEdgeAppearance = appearance
    }
  }

  #if DEBUG
    @ObserveInjection var redraw
  #endif

  @EnvironmentObject private var alertViewModel: AlertViewModel
  @StateObject private var tokenSettingsValue = TokenSettingsViewModel()
  @EnvironmentObject var menuViewModel: MenuViewModel
  //    @ObservedObject var toastHandler: ToastHandlerModel
  @State private var tokenSheetShown = false
  @State private var hasCheckedToken = false
  @State private var shouldRefresh: Bool? = false  //Used to refresh after the create page is dismissed.
  @AppStorage("tabViewLast") var tabViewLast: Int = 1

  var body: some View {
    TabView(selection: $tabViewLast) {
      AboutView()
        .tabItem { Label("Home", systemImage: "house") }
        .tag(1)
      TransactionsView()
        .tabItem { Label("Transactions", systemImage: "list.bullet.circle.fill") }
        .tag(2)
      AccountsView()
        .tabItem {
          Label("Accounts", systemImage: "banknote.fill")
        }
        .tag(3)
      Settings()
        .tabItem {
          Label("Settings", systemImage: "gearshape.fill")
        }
        .tag(4)
    }
    .sheet(isPresented: $tokenSheetShown) {
      TokenSettings().environmentObject(AlertViewModel())

    }
    .sheet(isPresented: $menuViewModel.transactionSheetShown) {
      TransactionCreate(shouldRefresh: $shouldRefresh).background(.ultraThinMaterial)
    }
    .sheet(isPresented: $menuViewModel.searchSheetShown) {
      SearchPage()
    }
    .onContinueUserActivity("addTransaction") { _ in
      print("Add transactions shortcut")
      menuViewModel.openTransactionSheet()
    }
    .task {
      if !hasCheckedToken {
        do {
          try await checkToken()
        } catch {
          tokenSheetShown = true
        }
      }
    }
    #if DEBUG
      .eraseToAnyView()
    #endif
    .transition(.opacity)
    .ignoresSafeArea(.all)

  }
  private func checkToken() async throws {
    do {
      try await tokenSettingsValue.testUserAccessInfo()
    } catch CredentialSaveError.accessError {
      tokenSheetShown = true
    }
  }
}

//#Preview {
//    Menu()
//}
