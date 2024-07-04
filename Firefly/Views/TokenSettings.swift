//
//  TokenSettings.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/06/05.
//

import SwiftUI

struct TokenSettings: View {

    @StateObject private var tokenSettingsValues = TokenSettingsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Credentials")
                    .font(.title)
                    .padding()

                instructionsLink

                credentialsForm

                TokenSettingsAsyncButton(action: tokenSettingsValues.saveCredentials) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!tokenSettingsValues.isFormValid)
                .padding()
            }
        }
        .onAppear(perform: tokenSettingsValues.loadCredentials)
    }
    private var instructionsLink: some View {
        Link(
            destination: URL(
                string: "https://docs.firefly-iii.org/how-to/firefly-iii/features/api/")!
        ) {
            HStack {
                Image(systemName: "book.closed.fill")
                Text("Instructions")
                Spacer()
                Image(systemName: "chevron.right")
                    .imageScale(.small)
                    .opacity(0.35)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.gray))
        }
    }
    private var credentialsForm: some View {
        VStack {
            TokenSettingsCustomTextField(placeholder: "API Token", text: $tokenSettingsValues.apiToken)
            TokenSettingsCustomTextField(placeholder: "Default URL", text: $tokenSettingsValues.defaultURL)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .shadow(color: Color.gray.opacity(0.3), radius: 5, x: 0, y: 2)
    }
}

struct TokenSettingsCustomTextField: View {
    let placeholder: String
    @Binding var text: String
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
            .autocapitalization(.none)
            .disableAutocorrection(true)
    }
}

struct TokenSettingsAsyncButton<Label: View>: View {
    var action: () async -> Void
    @ViewBuilder var label: () -> Label

    @State private var isPerformingTask = false

    var body: some View {
        Button(action: {
            isPerformingTask = true
            Task {
                await action()
                isPerformingTask = false
            }
        }) {
            ZStack {
                label().opacity(isPerformingTask ? 0 : 1)

                if isPerformingTask {
                    ProgressView()
                }
            }
        }
        .disabled(isPerformingTask)
    }
}

class TokenSettingsViewModel: ObservableObject {
    @Published var apiToken: String = ""
    @Published var defaultURL: String = ""

    func saveCredentials() {
        let keychainData = TokenObject(accessToken: apiToken)
        KeychainHelper.standard.save(
            keychainData, service: keychainConsts.accessToken,
            account: keychainConsts.account)
        UserDefaults.standard.set(defaultURL, forKey: UserDefaultKeys.baseURLKey)
    }

    func loadCredentials() {
        if let result = KeychainHelper.standard.read(
            service: keychainConsts.accessToken,
            account: keychainConsts.account,
            type: TokenObject.self
        ) {
            apiToken = result.accessToken
        }
        defaultURL = UserDefaults.standard.string(forKey: UserDefaultKeys.baseURLKey) ?? ""
    }
}

extension TokenSettingsViewModel {
    var isFormValid: Bool {
        !apiToken.isEmpty && !defaultURL.isEmpty
    }
}

//struct TokenSettings_Previews: PreviewProvider {
//    static var previews: some View {
//        TokenSettings()
//    }
//}
