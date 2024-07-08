//
//  TokenSettings.swift
//  Firefly
//
//  Created by Aditya Srinivasa on 2024/06/05.
//

import AlertToast
import SwiftUI

@MainActor
struct TokenSettings: View {

    @Environment(\.dismiss) var dismiss
    @StateObject private var tokenSettingsValues = TokenSettingsViewModel()
    @State private var showToast = false
    @State private var toastParams: AlertToast = AlertToast(displayMode: .alert, type: .regular)

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Credentials")
                    .font(.title)
                    .padding()

                instructionsLink

                credentialsForm

                TokenSettingsAsyncButton(action: saveCredentials) {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!tokenSettingsValues.isFormValid)
                .padding()
            }
        }
        .onAppear(perform: tokenSettingsValues.loadCredentials)
        .interactiveDismissDisabled()
        .toast(isPresenting: $showToast, tapToDismiss: false) {
            toastParams
        }
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
            TokenSettingsCustomTextField(
                placeholder: "API Token", text: $tokenSettingsValues.apiToken)
            TokenSettingsCustomTextField(
                placeholder: "Default URL", text: $tokenSettingsValues.defaultURL)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
        .shadow(color: Color.gray.opacity(0.3), radius: 5, x: 0, y: 2)
    }
    private func saveCredentials() async {
        do {
            try await tokenSettingsValues.saveCredentials()
            toastParams = AlertToast(
                displayMode: .alert, type: .complete(Color.green), title: "Saved Successfully")
            showToast.toggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismiss()
            }
        } catch CredentialSaveError.keychainSaveFailure {
            toastParams = AlertToast(
                displayMode: .alert, type: .error(Color.red), title: "Failed to save token!")
            showToast.toggle()
        } catch CredentialSaveError.userDefaultsSaveFailure {
            toastParams = AlertToast(
                displayMode: .alert, type: .error(Color.red), title: "Failed to save URL!")
            showToast.toggle()
            print("Failed to save to UserDefaults")
        } catch CredentialSaveError.accessError {
            toastParams = AlertToast(
                displayMode: .alert, type: .error(Color.red),
                title: "Could not access with the entered info!")
            showToast.toggle()
        } catch {
            toastParams = AlertToast(
                displayMode: .alert, type: .error(Color.red), title: "Something went wrong!")
            showToast.toggle()
            print("An unexpected error occurred: \(error)")
        }
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

enum CredentialSaveError: Error {
    case keychainSaveFailure
    case userDefaultsSaveFailure
    case accessError
}

class TokenSettingsViewModel: ObservableObject {
    @Published var apiToken: String = ""
    @Published var defaultURL: String = ""
    @Published var isLoading: Bool = false

    func saveCredentials() async throws {
        self.isLoading = true
        do {
            let keychainData = TokenObject(accessToken: apiToken)

            KeychainHelper.standard.save(
                keychainData, service: keychainConsts.accessToken,
                account: keychainConsts.account)
            UserDefaults.standard.set(defaultURL, forKey: UserDefaultKeys.baseURLKey)

            //Ensure the UserDefaults value was set sucessfully
            guard UserDefaults.standard.string(forKey: UserDefaultKeys.baseURLKey) == defaultURL
            else {
                throw CredentialSaveError.userDefaultsSaveFailure
            }
        } catch {
            print("Failed to save credentials: \(error)")
            throw CredentialSaveError.keychainSaveFailure
        }

        //Test if the API actually works
        do {
            try await testUserAccessInfo()
        } catch {
            print(error)
            throw CredentialSaveError.accessError
        }
        self.isLoading = false
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

    func testUserAccessInfo() async throws {
        let request = try RequestBuilder(apiURL: apiPaths.userAbout)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw CredentialSaveError.accessError
        }
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
