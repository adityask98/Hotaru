# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Hotaru is an unofficial iOS SwiftUI client for [Firefly III](https://github.com/firefly-iii/firefly-iii),
a self-hosted personal finance manager. The app talks to a user's Firefly III instance over its REST
API (often plain HTTP over a self-hosted/Tailscale connection — see `NSAllowsArbitraryLoads` note below).

**`docs/Firefly III 6.6.6.yaml`** is the full OpenAPI spec for the Firefly III API this app talks to.
Always check it when adding or changing anything that touches the API — request/response shapes,
field names, endpoints, enums (transaction types, etc.) should be verified against this spec rather
than guessed.

## Build, lint, format

There is no test target/scheme — `xcodebuild -list` shows only `Firefly` and the `AlertToast` SPM
package. Verification is build + lint/format, not `xcodebuild test`. Do not boot/launch the iOS
Simulator to visually verify UI changes — the user checks those themselves.

```bash
# Build (Debug, generic iOS Simulator destination)
xcodebuild -scheme Firefly -configuration Debug -destination 'generic/platform=iOS Simulator' build

# Format
swiftformat .
swiftformat --lint .        # check only, no changes

# Lint
swiftlint
swiftlint --fix              # auto-fix what's fixable
```

SwiftFormat and SwiftLint also run automatically as Xcode build phases (format, then lint) using the
root `.swiftformat` / `.swiftlint.yml` configs — see `FORMATTING.md` for the full setup and troubleshooting
(Homebrew PATH issues, etc.). Editing in VS Code uses the SweetPad extension (`.vscode/settings.json`)
for build/format-on-save against the same Xcode workspace.

## Architecture

**Pattern:** SwiftUI views + `@MainActor` `ObservableObject` view models + a thin API client layer, no
persistence framework (no CoreData/SwiftData) — state is fetched fresh or cached in-memory per view model.

- `Firefly/FireflyAPIClient/<Domain>/` — one folder per API domain (Transactions, Accounts, Categories,
  Charts, Insights, Autocomplete, Errors, About). Each typically has a `Codable` model file, an API
  provider/fetch file, and sometimes a view model when the domain's state is shared across views
  (e.g. `TransactionsViewModel`, `TransactionsPaginationManager`, `CategoriesInsightStore`).
- `Firefly/FireflyAPIClient/Constants.swift` — all API paths (`ApiPaths`, `PostApiPaths`, `PutApiPaths`,
  `AutocompleteApiPaths`, `InsightsApiPaths`, `ChartsApiPaths`, `WebviewPaths`) and `UserDefaults`/Keychain
  key names live here as enums of static constants. Add new endpoints here rather than inlining path
  strings.
- `Firefly/Helpers/RequestBuilder.swift` — builds every outgoing `URLRequest`: reads the bearer token
  from Keychain and the base URL from `UserDefaults`, throws `RequestBuilderError.missingToken` /
  `.missingBaseURL` rather than falling back to placeholders. All API calls should route through this.
- `Firefly/Helpers/KeychainHelper.swift` — token storage (`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`).
- `Firefly/Views/<Feature>/` — SwiftUI views, generally paired 1:1 with a `<Feature>ViewModel`.
- `Firefly/Views/Shared/` + shared components in `Firefly/Components/` — cross-feature UI:
  `EmptyStateView`/`ErrorStateView` (used app-wide for empty/error states), `FloatingButton`,
  `PrimaryButton`, toast components. Prefer these over per-view empty/error/loading UI.
- Cross-view communication uses `NotificationCenter`, not callbacks/bindings, when multiple unrelated
  views need to react to the same event (see `NOTIFICATIONS.md` for the full pattern: constants live in
  `Helpers/NotificationConstants.swift` as `AppNotifications`, e.g. `.transactionCreated/.transactionUpdated/.transactionDeleted`).
  Post after the async operation succeeds; listeners run on `.main` queue.
- `AppSettings.swift` / `@AppStorage` — user-facing settings (theme, pagination toggle, webview inline
  toggle, undo timeout) persisted via `UserDefaults`, keyed by `UserDefaultKeys` in `Constants.swift`.
- `Firefly/AppIntents/` + `FireflyApp.swift`'s `AppDelegate`/`SceneDelegate` — the "Add Transaction" home
  screen quick action / App Intents shortcut opens `MenuViewModel.openTransactionSheet()`.

### Transaction forms — three implementations, one in flux

There are currently three separate "add/edit transaction" implementations at different stages; see
`docs/TRANSACTION_FORM_REWRITE.md` before touching transaction create/edit code:

- `TransactionCreate` (`Views/Transactions/TransactionCreate/`) — in production (FAB, shortcuts, clone).
  State is `@State`, transaction types are raw strings converted via `convertTransactionType`/`convertTypeToDisplay`.
- `TransactionEdit` (`Views/Transactions/TransactionEdit.swift`) — in production, separate hand-rolled
  implementation with `Binding(get:set:)` into `PostTransaction`, supports splits.
- `TransactionAdd` + `TransactionAddViewModel` + `TransactionStore` (`Views/Transactions/TransactionAdd/`,
  `FireflyAPIClient/Transactions/TransactionStore.swift`) — half-finished rewrite meant to replace both
  of the above, using a typed `TransactionTypeProperty` enum and the full Firefly split schema. This is
  the intended long-term direction (see the doc for the merge plan) — don't invest further in the string-typed
  paths in `TransactionCreate`/`TransactionEdit` without checking whether the rewrite supersedes it.

### Known open items

`docs/TODO.md` tracks the remaining items from a past code audit (dead code to delete, one deliberate
security exception for plaintext HTTP since the app is sideloaded against a self-hosted server, and a
note about enabling `SWIFT_STRICT_CONCURRENCY = complete`). Check it before assuming something flagged
there is still unresolved — items are marked `[x]` as they're fixed.
