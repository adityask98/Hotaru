//
//  TokenSettings.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/06/05.
//

import SwiftUI

struct TokenSettings: View {
    @AppStorage(UserDefaultKeys.apiTokenKey) private var apiToken = ""
    @AppStorage(UserDefaultKeys.baseURLKey) private var defaultURL = ""

    var body: some View {
        VStack {
            Text("Enter API Token and Default URL")
                .font(.title)
                .padding()

            VStack(spacing: 20) {
                HStack {
                    TextField("Token", text: $apiToken)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading)

                    Button(action: {
                        // Store the value in AppStorage when the send button is tapped
                        UserDefaults.standard.set(apiToken, forKey: "APIToken")
                    }) {
                        Image(systemName: "paperplane")
                            .foregroundColor(.blue)
                    }
                    .padding(.trailing)
                }

                HStack {
                    TextField("Default URL", text: $defaultURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading)

                    Button(action: {
                        // Store the value in AppStorage when the send button is tapped
                        UserDefaults.standard.set(defaultURL, forKey: "DefaultURL")
                    }) {
                        Image(systemName: "paperplane")
                            .foregroundColor(.blue)
                    }
                    .padding(.trailing)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.gray.opacity(0.3), radius: 5, x: 0, y: 2)
            .padding()
        }
    }
}

struct TokenSettings_Previews: PreviewProvider {
    static var previews: some View {
        TokenSettings()
    }
}
