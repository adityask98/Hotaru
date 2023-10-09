//
//  ContentView.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2023/10/09.
//

import SwiftUI

struct ContentView: View {
    @StateObject var userAPIClient = UserAPIClient()
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            if let user = userAPIClient.user {
                Text("User Email: \(user.data.attributes.email)")
            } else {
                Text("Loading")
            }
            Button("Fetch") {
                Task {
                    await userAPIClient.fetchData()
                }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
