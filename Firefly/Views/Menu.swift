//
//  Menu.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2023/11/26.
//

import SwiftUI

struct Menu: View {
    var body: some View {
        TabView{
            AboutView()
                .tabItem { Image(systemName: "house") }
            AccountView()
                .tabItem { Image(systemName: "house") }
            AuthInfo()
                    .tabItem { Image(systemName: "house") }
       
        }
    }
}

#Preview {
    Menu()
}
