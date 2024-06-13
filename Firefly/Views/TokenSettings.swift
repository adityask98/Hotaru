//
//  TokenSettings.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/06/05.
//

import SwiftUI

struct TokenSettings: View {

    let auth = TokenObject(accessToken: "")
    //@AppStorage(UserDefaultKeys.apiTokenKey) private var apiToken = ""
    @AppStorage(UserDefaultKeys.baseURLKey) private var defaultURL = ""
    @State private var apiToken = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Credentials")
                    .font(.title)
                    .padding()

                Link(
                    destination: URL(
                        string: "https://docs.firefly-iii.org/how-to/firefly-iii/features/api/")!
                ) {
                    HStack(spacing: 0) {
                        HStack(spacing: 8) {
                            Image(systemName: "book.closed.fill")
                            Text("Instructions")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .imageScale(.small)
                                .opacity(0.35)
                        }
                        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(.gray))
                    .padding()
                }

                VStack {

                    HStack {
                        TextField("Token", text: $apiToken)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.leading)
                            .autocorrectionDisabled()

                        //                        Button(action: {
                        //                            // Store the value in AppStorage when the send button is tapped
                        //                            UserDefaults.standard.set(apiToken, forKey: "APIToken")
                        //                        }) {
                        //                            Image(systemName: "paperplane")
                        //                                .foregroundColor(.blue)
                        //                        }
                        //                        .padding(.trailing)
                    }

                    HStack {
                        TextField("Default URL", text: $defaultURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.leading)

                        //                        Button(action: {
                        //                            // Store the value in AppStorage when the send button is tapped
                        //                            UserDefaults.standard.set(defaultURL, forKey: "DefaultURL")
                        //                        }) {
                        //                            Image(systemName: "paperplane")
                        //                                .foregroundColor(.blue)
                        //                        }
                        //                        .padding(.trailing)
                    }
                    Spacer()
                    Button("Save") {
                        Task {
                            let keychainData = TokenObject(accessToken: apiToken)
                            print(keychainData)
                            KeychainHelper.standard.save(
                                keychainData, service: keychainConsts.accessToken,
                                account: keychainConsts.account)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.gray.opacity(0.3), radius: 5, x: 0, y: 2)
                .padding()
            }
        }
        .task {
            let result = KeychainHelper.standard.read(
                service: keychainConsts.accessToken, account: keychainConsts.account,
                type: TokenObject.self)!
            apiToken = result.accessToken

            UserDefaults.standard.set(defaultURL, forKey: "DefaultURL")

            print(result.accessToken)
        }
    }

}

struct TokenSettings_Previews: PreviewProvider {
    static var previews: some View {
        TokenSettings()
    }
}
