import AppIntents
import Foundation

struct AddTransactionIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Transaction"
    static var description = IntentDescription("Log a new expense in Firefly III.")

    @Parameter(title: "Amount") var amount: Double

    @Parameter(title: "Description") var transactionDescription: String

    @Parameter(title: "Account") var account: AccountEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$amount) expense for \(\.$transactionDescription) from \(\.$account)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        do {
            try await postTransaction(
                description: transactionDescription,
                amount: String(amount),
                date: Date(),
                category: "",
                type: "Withdrawal",
                sourceAccount: (id: account.id, name: account.name),
                destinationAccount: (id: "", name: ""),
                notes: ""
            )
        } catch {
            throw AddTransactionIntentError.failed
        }

        return .result(dialog: "Added \(transactionDescription) for \(amount.formatted())")
    }
}

enum AddTransactionIntentError: Error, CustomLocalizedStringResourceConvertible {
    case failed

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .failed:
            "Couldn't add the transaction. Make sure Firefly is signed in and reachable."
        }
    }
}

struct FireflyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTransactionIntent(),
            phrases: [
                "Add a transaction in \(.applicationName)",
                "Log an expense in \(.applicationName)",
            ],
            shortTitle: "Add Transaction",
            systemImageName: "plus.circle.fill"
        )
    }
}
