//
//  AboutView.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2023/10/09.
//

import SwiftUI

struct AboutView: View {
    @StateObject var userAPIClient = UserAPIClient()
    @State private var isDataLoaded = false
    var body: some View {
        VStack {
            Text("Hello, world!")
            if let user = userAPIClient.user {
                Text("User Email: \(user.data.attributes.email)")
                Text("ID: \(user.data.id)")
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
        .onAppear() {
            if (!isDataLoaded) {
//                Task {
                //                    await userAPIClient.fetchData()
//                    isDataLoaded = true
//                }
            }
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
