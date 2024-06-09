//
//  AboutView.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2023/10/09.
//

import SwiftUI

struct AboutView: View {
    @State private var user: UserModel?
//    @StateObject var userAPIClient = UserAPIClient()
//    @State private var isDataLoaded = false
    var body: some View {
        NavigationView {
            VStack {
                //            if let user = userAPIClient.user {
                //                Text("User Email: \(user.data.attributes.email)")
                //                Text("ID: \(user.data.id)")
                //            } else {
                //                Text("Loading")
                //            }
                //            Button("Fetch") {
                //                Task {
                //                    await userAPIClient.fetchData()
                //                }
                //            }
                List {
                    HStack {
                        Text("Email:")
                        Spacer()
                        Text(user?.data?.attributes?.email ?? "Email Placeholder")
                    }
                    NavigationLink(destination: TokenSettings()) {
                        Text("Token")
                    }
                }
            }
            .padding()
            //            .onAppear {
            //                if !isDataLoaded {
            //                    //                Task {
            //                    //                    await userAPIClient.fetchData()
            //                    //                    isDataLoaded = true
            //                    //                }
            //                }
            //            }

            .frame(width: .infinity, height: .infinity)
            .task {
                do {
                    user = try await getUser()
                } catch {
                    // Handle the error here
                    print("Error: \(error)")
                }
            }
        }
    }

}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
