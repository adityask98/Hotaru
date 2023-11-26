//
//  Menu.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2023/11/26.
//

import SwiftUI

struct Menu: View {
    var body: some View {
        NavigationView{
        VStack {
            List {
                NavigationLink(destination: AboutView()){
                    HStack {
                        Image(systemName: "person.crop.circle")
                        Text("Account Info")
                    }
                }
               
                HStack {
                    Image(systemName: "dollarsign.circle")
                    Text("Transactions")
                }
                HStack {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
            }
            .navigationTitle("Welcome to Firefly")
        }
    }
    }
}

#Preview {
    Menu()
}
