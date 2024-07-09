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

    var body: some Scene {
        WindowGroup {
            Menu()
                .preferredColorScheme(.dark)
                .environmentObject(alertViewModel)
                .toast(isPresenting: $alertViewModel.show, alert: { alertViewModel.alertToast })
        }
    }
}
