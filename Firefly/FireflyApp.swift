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
    @Environment(\.scenePhase) var scenePhase

    init() {
        #if DEBUG
            #if os(iOS)
                Bundle(
                    path: "/Applications/InjectionIII.app/Contents/Resources/iOSInjection.bundle")?
                    .load()
            #endif

            //for tvOS:
            #if os(tvOS)
                Bundle(
                    path: "/Applications/InjectionIII.app/Contents/Resources/tvOSInjection.bundle")?
                    .load()
                print("loading injection")
            #endif

            #if os(macOS)
                //Or for macOS:
                Bundle(
                    path: "/Applications/InjectionIII.app/Contents/Resources/macOSInjection.bundle")?
                    .load()
            #endif

        #endif
    }

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

#if canImport(HotSwiftUI)
    @_exported import HotSwiftUI
#elseif canImport(Inject)
    @_exported import Inject
#else
    // This code can be found in the Swift package:
    // https://github.com/johnno1962/HotSwiftUI

    #if DEBUG
        import Combine

        private var loadInjectionOnce: () = {
            guard objc_getClass("InjectionClient") == nil else {
                return
            }
            #if os(macOS) || targetEnvironment(macCatalyst)
                let bundleName = "macOSInjection.bundle"
            #elseif os(tvOS)
                let bundleName = "tvOSInjection.bundle"
            #elseif os(visionOS)
                let bundleName = "xrOSInjection.bundle"
            #elseif targetEnvironment(simulator)
                let bundleName = "iOSInjection.bundle"
            #else
                let bundleName = "maciOSInjection.bundle"
            #endif
            let bundlePath = "/Applications/InjectionIII.app/Contents/Resources/" + bundleName
            guard let bundle = Bundle(path: bundlePath), bundle.load() else {
                return print(
                    """
                    ⚠️ Could not load injection bundle from \(bundlePath). \
                    Have you downloaded the InjectionIII.app from either \
                    https://github.com/johnno1962/InjectionIII/releases \
                    or the Mac App Store?
                    """)
            }
        }()

        public let injectionObserver = InjectionObserver()

        public class InjectionObserver: ObservableObject {
            @Published var injectionNumber = 0
            var cancellable: AnyCancellable? = nil
            let publisher = PassthroughSubject<Void, Never>()
            init() {
                cancellable = NotificationCenter.default.publisher(
                    for:
                        Notification.Name("INJECTION_BUNDLE_NOTIFICATION")
                )
                .sink { [weak self] change in
                    self?.injectionNumber += 1
                    self?.publisher.send()
                }
            }
        }

        extension SwiftUI.View {
            public func eraseToAnyView() -> some SwiftUI.View {
                _ = loadInjectionOnce
                return AnyView(self)
            }
            public func enableInjection() -> some SwiftUI.View {
                return eraseToAnyView()
            }
            public func loadInjection() -> some SwiftUI.View {
                return eraseToAnyView()
            }
            public func onInjection(bumpState: @escaping () -> Void) -> some SwiftUI.View {
                return
                    self
                    .onReceive(injectionObserver.publisher, perform: bumpState)
                    .eraseToAnyView()
            }
        }

        @available(iOS 13.0, *)
        @propertyWrapper
        public struct ObserveInjection: DynamicProperty {
            @ObservedObject private var iO = injectionObserver
            public init() {}
            public private(set) var wrappedValue: Int {
                get { 0 }
                set {}
            }
        }
    #else
        extension SwiftUI.View {
            @inline(__always)
            public func eraseToAnyView() -> some SwiftUI.View { return self }
            @inline(__always)
            public func enableInjection() -> some SwiftUI.View { return self }
            @inline(__always)
            public func loadInjection() -> some SwiftUI.View { return self }
            @inline(__always)
            public func onInjection(bumpState: @escaping () -> Void) -> some SwiftUI.View {
                return self
            }
        }

        @available(iOS 13.0, *)
        @propertyWrapper
        public struct ObserveInjection {
            public init() {}
            public private(set) var wrappedValue: Int {
                get { 0 }
                set {}
            }
        }
    #endif
#endif
