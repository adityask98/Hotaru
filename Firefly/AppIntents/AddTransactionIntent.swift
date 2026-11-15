import AppIntents
import Foundation

struct AddTransactionIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Transaction"
    static let description = IntentDescription("Log a new expense in Firefly III.")
    /// Posts headlessly; never needs to bring the app forward.
    static let supportedModes: IntentModes = .background

    @Parameter(title: "Amount") var amount: Double

    @Parameter(title: "Description") var transactionDescription: String

    @Parameter(title: "Account") var account: AccountEntity

    /// Optional so Siri never prompts for them and shortcuts saved before they existed still run.
    @Parameter(title: "Category") var category: CategoryEntity?

    @Parameter(title: "Budget") var budget: BudgetEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$amount) expense for \(\.$transactionDescription) from \(\.$account)") {
            \.$category
            \.$budget
        }
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Validate before the irreversible POST (perform() may be re-run from the top).
        guard amount > 0 else {
            throw AddTransactionIntentError.invalidAmount
        }

        do {
            try await postTransaction(
                description: transactionDescription,
                amount: String(amount),
                date: Date(),
                category: category?.name ?? "",
                type: "Withdrawal",
                sourceAccount: (id: account.id, name: account.name),
                destinationAccount: (id: "", name: ""),
                notes: "",
                budgetID: budget?.id
            )
        } catch {
            throw AddTransactionIntentError.userFacing(error)
        }

        // Intents run in the app process, so refresh any open lists like an in-app create does.
        await MainActor.run {
            NotificationCenter.default.post(name: AppNotifications.transactionCreated, object: nil)
        }

        let formattedAmount = formatAmount(String(amount), symbol: account.currencySymbol)
        return .result(dialog: "Added \(transactionDescription) for \(formattedAmount) from \(account.name)")
    }
}

enum AddTransactionIntentError: Error, CustomLocalizedStringResourceConvertible {
    case invalidAmount
    case unreachable
    case rejected

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .invalidAmount:
            "The amount must be greater than zero."
        case .unreachable:
            "Couldn't reach your Firefly III server. Check your connection and try again."
        case .rejected:
            "Firefly III rejected the transaction. Open Hotaru to check the account and details."
        }
    }

    /// Maps an underlying failure to an error Siri/Shortcuts can present meaningfully.
    static func userFacing(_ error: Error) -> Error {
        switch error {
        case RequestBuilderError.missingBaseURL, RequestBuilderError.missingToken:
            AppIntentError.UserActionRequired.signin
        case is URLError:
            AddTransactionIntentError.unreachable
        default:
            AddTransactionIntentError.rejected
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
