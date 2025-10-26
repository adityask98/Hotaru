import AlertToast
import SwiftUI

@MainActor
struct TokenSettings: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var tokenSettingsValues = TokenSettingsViewModel()
    @State private var showToast = false
    @State private var toastParams = AlertToast(displayMode: .alert, type: .regular)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    instructionsLink

                    credentialsForm
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            Task {
                                await saveCredentials()
                            }
                        }
                        .disabled(!tokenSettingsValues.isFormValid)
                    }
                }
            }
            .padding(.horizontal)
            .onAppear(perform: tokenSettingsValues.loadCredentials)
            .interactiveDismissDisabled()
            .toast(isPresenting: $showToast, tapToDismiss: false) {
                toastParams
            }
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
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Credentials").fontWeight(.semibold).font(.title2)
                    Spacer()
                }
                .padding(.horizontal, 4)
                TokenSettingsCustomTextField(
                    placeholder: "API Token", keyboardType: .default,
                    text: $tokenSettingsValues.apiToken
                )
                TokenSettingsCustomTextField(
                    placeholder: "Default URL", keyboardType: .URL,
                    text: $tokenSettingsValues.defaultURL
                )
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .cornerRadius(10)
        .shadow(color: Color.gray.opacity(0.3), radius: 5, x: 0, y: 2)
    }

    private func saveCredentials() async {
        do {
            try await tokenSettingsValues.saveCredentials()
            toastParams = AlertToast(
                displayMode: .alert, type: .complete(Color.green), title: "Saved Successfully"
            )
            showToast.toggle()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                dismiss()
            }
        } catch CredentialSaveError.keychainSaveFailure {
            toastParams = AlertToast(
                displayMode: .alert, type: .error(Color.red), title: "Failed to save token!"
            )
            showToast.toggle()
        } catch CredentialSaveError.userDefaultsSaveFailure {
            toastParams = AlertToast(
                displayMode: .alert, type: .error(Color.red), title: "Failed to save URL!"
            )
            showToast.toggle()
            print("Failed to save to UserDefaults")
        } catch CredentialSaveError.accessError {
            toastParams = AlertToast(
                displayMode: .alert, type: .error(Color.red),
                title: "Could not access with the entered info!"
            )
            showToast.toggle()
        } catch {
            toastParams = AlertToast(
                displayMode: .alert, type: .error(Color.red), title: "Something went wrong!"
            )
            showToast.toggle()
            print("An unexpected error occurred: \(error)")
        }
    }
}

struct TokenSettingsCustomTextField: View {
    let placeholder: String
    let keyboardType: UIKeyboardType?
    @Binding var text: String
    @FocusState var focused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(placeholder.uppercased()).fontWeight(.semibold).font(.callout).padding(
                .horizontal, 12
            ).opacity(0.5)
            TextField(placeholder, text: $text)
                .focused($focused)
                .autocorrectionDisabled(true)
                .keyboardType(keyboardType ?? .default)
                .textInputAutocapitalization(.never)
                .fontDesign(.monospaced)
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.darkGray))
                        .brightness(focused ? 0.1 : 0)
                        .shadow(
                            color: .black.opacity(focused ? 0.15 : 0), radius: focused ? 12 : 0,
                            y: focused ? 6 : 0
                        )
                        .animation(.easeOut.speed(2.5), value: focused)
                        .onTapGesture {
                            focused = true
                        }
                )
        }
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

@MainActor
class TokenSettingsViewModel: ObservableObject {
    @Published var apiToken = ""
    @Published var defaultURL = ""
    @Published var isLoading = false

    func saveCredentials() async throws {
        isLoading = true

        // Save Creds
        do {
            let keychainData = TokenObject(accessToken: apiToken)

            KeychainHelper.standard.save(
                keychainData, service: KeychainConsts.accessToken,
                account: KeychainConsts.account
            )
            UserDefaults.standard.set(defaultURL, forKey: UserDefaultKeys.baseURLKey)

            // Ensure the UserDefaults value was set successfully
            guard UserDefaults.standard.string(forKey: UserDefaultKeys.baseURLKey) == defaultURL else {
                throw CredentialSaveError.userDefaultsSaveFailure
            }
        } catch {
            print("Failed to save credentials: \(error)")
            throw CredentialSaveError.keychainSaveFailure
        }
        // Test if the API actually works
        do {
            try await testUserAccessInfo()
        } catch {
            print(error)
            throw CredentialSaveError.accessError
        }
        isLoading = false
    }

    func loadCredentials() {
        if let result = KeychainHelper.standard.read(
            service: KeychainConsts.accessToken,
            account: KeychainConsts.account,
            type: TokenObject.self
        ) {
            apiToken = result.accessToken
        }
        defaultURL = UserDefaults.standard.string(forKey: UserDefaultKeys.baseURLKey) ?? ""
    }

    func testUserAccessInfo() async throws {
        let request = try RequestBuilder(apiURL: ApiPaths.userAbout)

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

// struct TokenSettings_Previews: PreviewProvider {
//    static var previews: some View {
//        TokenSettings()
//    }
// }
