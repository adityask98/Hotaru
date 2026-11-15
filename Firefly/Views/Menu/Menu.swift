import AlertToast
import SwiftUI

struct RootView: View {
    //  init() {
    //    let appearance = UITabBarAppearance()
    //    appearance.configureWithTransparentBackground()
    //
    //    // If you want a blur effect
    //    appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial)
    //
    //    // Customize the color to make it more or less translucent
    //    appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.5)
    //
    //    // Use this appearance for both standard and scrolled content
    //    UITabBar.appearance().standardAppearance = appearance
    //    if #available(iOS 15.0, *) {
    //      UITabBar.appearance().scrollEdgeAppearance = appearance
    //    }
    //  }

    @EnvironmentObject private var alertViewModel: AlertViewModel
    @StateObject private var tokenSettingsValue = TokenSettingsViewModel()
    @EnvironmentObject var menuViewModel: MenuViewModel
    @EnvironmentObject var pendingDeleteManager: PendingDeleteManager
    //    @ObservedObject var toastHandler: ToastHandlerModel
    @State private var tokenSheetShown = false
    @State private var hasCheckedToken = false
    @State private var searchText = ""
    @AppStorage("tabViewLast") var tabViewLast = 1
    @AppStorage(UserDefaultKeys.minimizeTabBarOnScroll) private var minimizeTabBarOnScroll = true
    @AppStorage(UserDefaultKeys.hideTabTitles) private var hideTabTitles = true

    var body: some View {
        TabView(
            selection: $tabViewLast,
            content: {
                Tab(value: 1) {
                    HomeView()
                } label: {
                    tabLabel("Home", systemImage: "chart.bar.yaxis")
                }
                Tab(value: 2) {
                    TransactionsView()
                } label: {
                    tabLabel("Transactions", systemImage: "list.bullet.circle.fill")
                }
                Tab(value: 3) {
                    AccountsView()
                } label: {
                    tabLabel("Accounts", systemImage: "creditcard.fill")
                }
                Tab(value: 4) {
                    Settings()
                } label: {
                    tabLabel("Settings", systemImage: "gearshape.fill")
                }
                Tab(value: 5, role: .search) {
                    SearchPage()
                } label: {
                    // Explicit label so "Hide tab titles" applies here too; without one
                    // the system supplies its own "Search" title.
                    tabLabel("Search", systemImage: "magnifyingglass")
                }
            }
        )
        // Rebuild the tab bar when "Hide tab titles" changes: switching a Tab's label from
        // Label back to a bare Image doesn't clear the title the bar item already has.
        // Resets each tab's navigation state; the selected tab persists via `tabViewLast`.
        .id(hideTabTitles)
            // .searchable(text: $searchText, prompt: "Search transactions")
            .tabBarMinimizeBehavior(minimizeTabBarOnScroll ? .onScrollDown : .never)
            .sheet(isPresented: $tokenSheetShown) {
                // Only lock the sheet when credentials are genuinely missing — a failed
                // check against a server that's merely unreachable must stay dismissable.
                TokenSettings(requiresCredentials: credentialsMissing)
                    .environmentObject(AlertViewModel())
            }
            .sheet(isPresented: $menuViewModel.transactionSheetShown) {
                TransactionCreate().background(.ultraThinMaterial)
            }
            //    .sheet(isPresented: $menuViewModel.searchSheetShown) {
            //      SearchPage()
            //    }
            .sheet(isPresented: $menuViewModel.transactionAddSheetShown) {
                TransactionAdd()
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

            .transition(.opacity)
            .ignoresSafeArea(.all)
            .overlay(alignment: .bottom) {
                if let pending = pendingDeleteManager.pending {
                    UndoSnackbar(title: pending.title) {
                        pendingDeleteManager.undo()
                    }
                    .padding(.bottom, 70) // keep clear of the tab bar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.35), value: pendingDeleteManager.pending)
    }

    /// Icon-only when "Hide tab titles" is on; the title stays as the VoiceOver label.
    @ViewBuilder
    private func tabLabel(_ title: String, systemImage: String) -> some View {
        if hideTabTitles {
            Image(systemName: systemImage)
                .accessibilityLabel(title)
        } else {
            Label(title, systemImage: systemImage)
        }
    }

    private var credentialsMissing: Bool {
        let token = KeychainHelper.standard.read(
            service: KeychainConsts.accessToken,
            account: KeychainConsts.account,
            type: TokenObject.self
        )?.accessToken ?? ""
        let baseURL = UserDefaults.standard.string(forKey: UserDefaultKeys.baseURLKey) ?? ""
        return token.isEmpty || baseURL.isEmpty
    }

    private func checkToken() async throws {
        do {
            try await tokenSettingsValue.testUserAccessInfo()
        } catch CredentialSaveError.accessError {
            tokenSheetShown = true
        }
    }
}

// #Preview {
//    Menu()
// }
