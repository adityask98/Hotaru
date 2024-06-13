//
//  Settings.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/06/13.
//

import SwiftUI

struct Settings: View {
    var body: some View {
        NavigationStack {
            List {
                Group {
                    Section {
                        NavigationLink(destination: TokenSettings()) {
                            Text("Token")
                        }
                        NavigationLink(destination: TokenSettings()) {
                            HStack {
                                Image(systemName: "gear")
                                Text("Credentials")
                                Spacer()
                                
                            }
                            .contentShape(Rectangle())
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    Settings()
}
