//
//  Menu.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2023/11/26.
//

import SwiftUI
import AlertToast

struct Menu: View {
    
    @State private var showToast = true
//    @ObservedObject var toastHandler: ToastHandlerModel
    
    var body: some View {
        TabView(selection: .constant(2)) {
            AboutView()
                .tabItem { Image(systemName: "house") }
                .tag(1)
            TransactionsView()
                .tabItem { Label("Transactions", systemImage: "list.bullet.circle.fill") }
                .tag(2)
            AuthInfo()
                .tabItem {
                    Label("Counter", systemImage: "number.circle.fill")
                }
            Settings()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                

        }
        .toast(isPresenting: $showToast, tapToDismiss: true) {
            AlertToast( displayMode: .hud, type: .regular, title: "TEST")
        }
    }
        
}

//#Preview {
//    Menu()
//}
