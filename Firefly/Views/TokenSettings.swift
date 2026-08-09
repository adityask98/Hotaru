import AlertToast
import SwiftUI

@MainActor
struct TokenSettings: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var tokenSettingsValues = TokenSettingsViewModel()
    @FocusState private var tokenFocused: Bool
    @State private var showToast = false
    @State private var toastParams = AlertToast(displayMode: .alert, type: .regular)

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 16) {
                    instructionsLink
                    credentialsCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .background(Color(.systemGroupedBackground))
        .onAppear(perform: tokenSettingsValues.loadCredentials)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(24)
        .toast(isPresenting: $showToast, tapToDismiss: false) {
            toastParams
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack {
            Text("Credentials")
                .font(.system(size: 17, weight: .semibold))

            HStack {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(Color.accentColor)

                Spacer()

                saveButton
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 14)
    }

    private var saveButton: some View {
        Button(action: handleSave) {
            HStack(spacing: 5) {
                if tokenSettingsValues.saved {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                }
                Text(tokenSettingsValues.saved ? "Saved" : "Save")
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(tokenSettingsValues.canSave ? .white : .secondary)
            .padding(.horizontal, 18)
            .padding(.vertical, 7)
            .background(
                Capsule().fill(tokenSettingsValues.canSave ? Color.accentColor : Color(.tertiarySystemFill))
            )
        }
        .buttonStyle(.plain)
        .disabled(!tokenSettingsValues.canSave)
        .animation(.easeOut(duration: 0.15), value: tokenSettingsValues.saved)
    }

    // MARK: - Instructions

    private var instructionsLink: some View {
        Link(
            destination: URL(
                string: "https://docs.firefly-iii.org/how-to/firefly-iii/features/api/"
            )!
        ) {
            HStack(spacing: 10) {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(Color.accentColor)
                Text("Instructions")
                    .foregroundStyle(Color.accentColor)
                Spacer()
                Image(systemName: "chevron.right")
                    .imageScale(.small)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06))
            )
        }
    }

    // MARK: - Credentials card

    private var credentialsCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            apiTokenSection
            Divider()
            instanceURLSection
            VStack(alignment: .leading, spacing: 8) {
                testConnectionButton
                testErrorDetail
            }
            .animation(.easeOut(duration: 0.2), value: tokenSettingsValues.testErrorMessage)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var apiTokenSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("API TOKEN")
                    .font(.system(size: 12.5, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)
                Spacer()
                if !tokenSettingsValues.pasteMessage.isEmpty {
                    Text(tokenSettingsValues.pasteMessage)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }
            }

            HStack(spacing: 8) {
                maskedTokenField
                    .padding(.leading, 14)
                    .padding(.trailing, 6)
                    .padding(.vertical, 13)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(.tertiarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.06))
                    )

                Button(action: tokenSettingsValues.pasteToken) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(Color.accentColor.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Paste from clipboard")
            }

            Text(
                "Firefly III → Profile → OAuth → Personal Access Tokens. The field masks automatically once you tap away."
            )
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
        .animation(.easeOut(duration: 0.15), value: tokenSettingsValues.pasteMessage)
    }

    /// Shows the real token while focused and a dot mask once the field loses focus,
    /// avoiding a SecureField/TextField identity swap (which drops focus/cursor state).
    private var maskedTokenField: some View {
        ZStack(alignment: .leading) {
            TextField("Paste your personal access token", text: $tokenSettingsValues.token)
                .focused($tokenFocused)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .keyboardType(.asciiCapable)
                .fontDesign(.monospaced)
                .font(.system(size: 14))
                .privacySensitive(true)
                .opacity(tokenFocused || tokenSettingsValues.token.isEmpty ? 1 : 0)

            if !tokenFocused && !tokenSettingsValues.token.isEmpty {
                Text(String(repeating: "•", count: min(tokenSettingsValues.token.count, 40)))
                    .font(.system(size: 14))
                    .foregroundStyle(.primary)
                    .allowsHitTesting(false)
                    .accessibilityLabel("Token hidden, tap to reveal")
            }
        }
    }

    private var instanceURLSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("INSTANCE URL")
                .font(.system(size: 12.5, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                protocolPicker
                domainField
            }

            if case .error(let message) = tokenSettingsValues.domainValidation {
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
                    .transition(.opacity)
            } else if tokenSettingsValues.isDomainValid {
                Text("Looks good")
                    .font(.system(size: 12))
                    .foregroundStyle(.green)
                    .transition(.opacity)
            }

            if tokenSettingsValues.showResolvedURL {
                HStack(spacing: 7) {
                    Text("Will connect to")
                        .font(.system(size: 11.5))
                        .foregroundStyle(.secondary)
                    Text(tokenSettingsValues.resolvedURL)
                        .font(.system(size: 12.5, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.15), value: tokenSettingsValues.domain)
        .animation(.easeOut(duration: 0.15), value: tokenSettingsValues.protocolOption)
    }

    private var protocolPicker: some View {
        HStack(spacing: 2) {
            protocolButton(.https, label: "https")
            protocolButton(.http, label: "http")
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        )
    }

    private func protocolButton(_ option: TokenSettingsViewModel.HTTPProtocolOption, label: String) -> some View {
        let selected = tokenSettingsValues.protocolOption == option
        return Button {
            tokenSettingsValues.protocolOption = option
        } label: {
            Text(label)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(selected ? .white : .secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(selected ? Color.accentColor : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }

    private var domainField: some View {
        HStack(spacing: 8) {
            TextField("firefly.example.com", text: $tokenSettingsValues.domain)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
                .keyboardType(.URL)
                .fontDesign(.monospaced)
                .font(.system(size: 14))

            if !tokenSettingsValues.domain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Group {
                    if tokenSettingsValues.isDomainValid {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    } else {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                    }
                }
                .font(.system(size: 16))
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.tertiarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(domainBorderColor, lineWidth: 1)
        )
    }

    private var domainBorderColor: Color {
        switch tokenSettingsValues.domainValidation {
        case .error:
            .red.opacity(0.5)
        case .valid:
            .green.opacity(0.4)
        case .empty:
            Color.primary.opacity(0.06)
        }
    }

    private var testConnectionButton: some View {
        Button {
            Task { await tokenSettingsValues.runConnectionTest() }
        } label: {
            HStack(spacing: 8) {
                switch tokenSettingsValues.testState {
                case .loading:
                    ProgressView().tint(.primary)
                case .success:
                    Image(systemName: "checkmark").foregroundStyle(.green)
                case .failure:
                    Image(systemName: "xmark").foregroundStyle(.red)
                case .idle:
                    EmptyView()
                }
                Text(testLabel)
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(testTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(testBackground)
            )
        }
        .buttonStyle(.plain)
        .disabled(!tokenSettingsValues.canSave || tokenSettingsValues.testState == .loading)
        .opacity(tokenSettingsValues.canSave ? 1 : 0.4)
        .animation(.easeOut(duration: 0.2), value: tokenSettingsValues.testState)
    }

    @ViewBuilder
    private var testErrorDetail: some View {
        if tokenSettingsValues.testState == .failure, !tokenSettingsValues.testErrorMessage.isEmpty {
            Text(tokenSettingsValues.testErrorMessage)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
        }
    }

    private var testLabel: String {
        switch tokenSettingsValues.testState {
        case .loading: "Testing connection…"
        case .success: "Connected"
        case .failure: "Couldn’t connect — tap to retry"
        case .idle: "Test Connection"
        }
    }

    private var testTextColor: Color {
        switch tokenSettingsValues.testState {
        case .success: .green
        case .failure: .red
        default: .primary
        }
    }

    private var testBackground: Color {
        switch tokenSettingsValues.testState {
        case .success: .green.opacity(0.12)
        case .failure: .red.opacity(0.12)
        default: Color(.tertiarySystemBackground)
        }
    }

    // MARK: - Actions

    private func handleSave() {
        do {
            try tokenSettingsValues.saveCredentials()
            withAnimation { tokenSettingsValues.saved = true }
            Task {
                try? await Task.sleep(for: .seconds(1.6))
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
        } catch {
            toastParams = AlertToast(
                displayMode: .alert, type: .error(Color.red), title: "Something went wrong!"
            )
            showToast.toggle()
            AppLog.appError("Unexpected error saving credentials", error)
        }
    }
}

enum CredentialSaveError: Error {
    case keychainSaveFailure
    case userDefaultsSaveFailure
    case accessError
}

@MainActor
class TokenSettingsViewModel: ObservableObject {
    enum HTTPProtocolOption: String, Equatable {
        case https
        case http
    }

    enum DomainValidationStatus: Equatable {
        case empty
        case error(String)
        case valid
    }

    enum ConnectionTestState: Equatable {
        case idle
        case loading
        case success
        case failure
    }

    @Published var token = "" {
        didSet { testState = .idle; testErrorMessage = ""; saved = false }
    }

    @Published var protocolOption: HTTPProtocolOption = .https {
        didSet { testState = .idle; testErrorMessage = ""; saved = false }
    }

    @Published var domain = "" {
        didSet { testState = .idle; testErrorMessage = ""; saved = false }
    }

    @Published var testState: ConnectionTestState = .idle
    @Published var testErrorMessage = ""
    @Published var saved = false
    @Published var pasteMessage = ""
    @Published var isLoading = false

    private var pasteMessageTask: Task<Void, Never>?

    private static let domainPattern =
        #"^(localhost|(\d{1,3}\.){3}\d{1,3}|[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+)(:\d{1,5})?(\/[a-zA-Z0-9\-._~%!$&'()*+,;=:@/]*)?$"#

    // MARK: - Derived state

    var domainValidation: DomainValidationStatus {
        let value = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return .empty }
        guard value.rangeOfCharacter(from: .whitespacesAndNewlines) == nil else {
            return .error("No spaces allowed")
        }
        guard value.range(of: "^https?://", options: [.regularExpression, .caseInsensitive]) == nil else {
            return .error("Don’t include http(s):// — use the toggle above")
        }
        guard !value.contains("@") else {
            return .error("Enter a domain, not an email")
        }
        guard value.range(of: Self.domainPattern, options: [.regularExpression, .caseInsensitive]) != nil else {
            return .error("Enter a valid domain, e.g. firefly.example.com")
        }
        return .valid
    }

    var isDomainValid: Bool {
        domainValidation == .valid
    }

    /// The domain with surrounding whitespace and any trailing slash(es) removed, so a
    /// user-entered extra slash (or a missing one) never produces a malformed base URL.
    var domainTrimmed: String {
        var value = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        while value.hasSuffix("/") {
            value.removeLast()
        }
        return value
    }

    var resolvedURL: String {
        domainTrimmed.isEmpty ? "" : "\(protocolOption.rawValue)://\(domainTrimmed)/"
    }

    var showResolvedURL: Bool {
        isDomainValid
    }

    var canSave: Bool {
        isDomainValid && !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Actions

    func pasteToken() {
        pasteMessageTask?.cancel()

        if let text = UIPasteboard.general.string,
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            token = text.trimmingCharacters(in: .whitespacesAndNewlines)
            pasteMessage = "Pasted"
        } else {
            pasteMessage = "Clipboard empty"
        }

        pasteMessageTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.8))
            guard !Task.isCancelled else { return }
            self?.pasteMessage = ""
        }
    }

    func runConnectionTest() async {
        guard canSave, testState != .loading else { return }
        testState = .loading
        testErrorMessage = ""

        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: resolvedURL + ApiPaths.userAbout) else {
            testState = .failure
            testErrorMessage = "Couldn’t build a URL from that domain."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer \(trimmedToken)",
        ]

        do {
            let (data, response) = try await AppNetworking.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode
                testState = .failure
                testErrorMessage = Self.describeFailure(statusCode: statusCode, body: data)
                return
            }
            testState = .success
        } catch {
            AppLog.networkError("Test connection failed", error)
            testState = .failure
            testErrorMessage = error.localizedDescription
        }
    }

    /// Prefers the Firefly III API's own `{"message": ...}` error body; falls back to
    /// the raw response text, then just the HTTP status, so something always shows.
    private static func describeFailure(statusCode: Int?, body: Data) -> String {
        let prefix = statusCode.map { "HTTP \($0)" } ?? "Request failed"

        if let decoded = try? errorDecoder(body), let message = decoded.message ?? decoded.exception {
            return "\(prefix): \(message)"
        }

        if let raw = String(data: body, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !raw.isEmpty {
            return "\(prefix): \(raw)"
        }

        return prefix
    }

    func saveCredentials() throws {
        guard canSave else { return }
        let trimmedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let keychainData = TokenObject(accessToken: trimmedToken)
            try KeychainHelper.standard.save(
                keychainData, service: KeychainConsts.accessToken,
                account: KeychainConsts.account
            )
        } catch {
            AppLog.appError("Failed to save token to keychain", error)
            throw CredentialSaveError.keychainSaveFailure
        }

        let urlToSave = resolvedURL
        UserDefaults.standard.set(urlToSave, forKey: UserDefaultKeys.baseURLKey)
        guard UserDefaults.standard.string(forKey: UserDefaultKeys.baseURLKey) == urlToSave else {
            throw CredentialSaveError.userDefaultsSaveFailure
        }

        token = trimmedToken
    }

    func loadCredentials() {
        if let result = KeychainHelper.standard.read(
            service: KeychainConsts.accessToken,
            account: KeychainConsts.account,
            type: TokenObject.self
        ) {
            token = result.accessToken
        }

        let stored = UserDefaults.standard.string(forKey: UserDefaultKeys.baseURLKey) ?? ""
        if let components = URLComponents(string: stored), let host = components.host, !host.isEmpty {
            protocolOption = components.scheme?.lowercased() == "http" ? .http : .https
            var rebuilt = host
            if let port = components.port {
                rebuilt += ":\(port)"
            }
            let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if !path.isEmpty {
                rebuilt += "/\(path)"
            }
            domain = rebuilt
        } else {
            domain = stored
        }

        testState = .idle
        saved = false
    }

    /// Tests the *saved* credentials (Keychain + UserDefaults) — used by RootView on
    /// launch to decide whether to force-present this sheet, independent of any
    /// in-progress edits to the form above.
    func testUserAccessInfo() async throws {
        let request = try RequestBuilder(apiURL: ApiPaths.userAbout)

        let (_, response) = try await AppNetworking.session.data(for: request)

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw CredentialSaveError.accessError
        }
    }
}

// struct TokenSettings_Previews: PreviewProvider {
//    static var previews: some View {
//        TokenSettings()
//    }
// }
