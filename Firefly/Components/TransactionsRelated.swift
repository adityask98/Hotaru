import SwiftUI

// MARK: - Value-based navigation to TransactionDetail

/// Pushed by `TransactionsRow`. `zoomSourceID` is unique per row instance rather than
/// the transaction id, because the same transaction can be on screen in two stacked
/// views (Home's recent list and an account's list pushed above it) and the zoom must
/// return to the row that was actually tapped.
struct TransactionRoute: Hashable {
    let transactionID: String
    let zoomSourceID: String
}

extension EnvironmentValues {
    /// Shared by every row in a stack and its detail destination; `nil` outside a stack
    /// set up with `transactionNavigationScope()`, in which case rows simply don't zoom.
    @Entry var transactionZoomNamespace: Namespace.ID?
}

extension View {
    /// Apply to the `NavigationStack` itself (not its root content) so views pushed
    /// later — e.g. `AccountDetail`'s transaction list — inherit the namespace too.
    func transactionNavigationScope() -> some View {
        modifier(TransactionZoomScope())
    }

    /// Apply to a `NavigationStack`'s root content, outside any lazy container.
    /// Registers the single `TransactionDetail` destination for the whole stack.
    func transactionNavigationDestination() -> some View {
        modifier(TransactionDestination())
    }

    /// Zooms from `id` when a namespace is available; a no-op otherwise.
    @ViewBuilder
    func zoomTransition(sourceID id: String, in namespace: Namespace.ID?) -> some View {
        if let namespace {
            navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }
}

private struct TransactionZoomScope: ViewModifier {
    @Namespace private var namespace

    func body(content: Content) -> some View {
        content.environment(\.transactionZoomNamespace, namespace)
    }
}

private struct TransactionDestination: ViewModifier {
    @Environment(\.transactionZoomNamespace) private var namespace

    func body(content: Content) -> some View {
        content.navigationDestination(for: TransactionRoute.self) { route in
            TransactionDetail(transactionID: route.transactionID)
                .zoomTransition(sourceID: route.zoomSourceID, in: namespace)
        }
    }
}

/// Enables `TransactionsRow`'s swipe actions in non-`List` stacks (iOS 27+), when the
/// "Swipe actions" setting is on.
private struct TransactionSwipeActionsContainer: ViewModifier {
    @AppStorage(UserDefaultKeys.transactionRowSwipeActions) private var swipeActionsEnabled = false

    func body(content: Content) -> some View {
        if #available(iOS 27, *), swipeActionsEnabled {
            content.swipeActionsContainer()
        } else {
            content
        }
    }
}

extension View {
    func transactionSwipeActionsContainer() -> some View {
        modifier(TransactionSwipeActionsContainer())
    }
}

struct TransactionsList: View {
    var transactions: Transactions?
    var hasMorePages: Bool
    let onLoadMore: () -> Void
    @State private var opacity = 0.1
    @EnvironmentObject private var pendingDeleteManager: PendingDeleteManager

    private var visibleTransactions: [TransactionsDatum] {
        (transactions?.data ?? []).filter { datum in
            guard let id = datum.id else { return true }
            return !pendingDeleteManager.hiddenIDs.contains(id)
        }
    }

    var body: some View {
        LazyVStack {
            // Checks the visible rows, so hiding the last one (pending delete) shows
            // the empty state rather than a blank screen
            if transactions?.data != nil, visibleTransactions.isEmpty {
                EmptyStateView(message: "No transactions in this period")
            } else {
                ForEach(visibleTransactions, id: \.id) { transactionData in
                    TransactionsRow(transaction: transactionData)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                }
                // Only page while there is loaded, non-empty data — otherwise the
                // spinner would show forever and refire load-more on empty results
                if hasMorePages, transactions?.data?.isEmpty == false {
                    LoadingSpinner()
                        .onAppear {
                            onLoadMore()
                        }
                }
            }
        }
        .transactionSwipeActionsContainer()
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.1)) {
                opacity = 1.0
            }
        }
        //    .listStyle(PlainListStyle())
        //    .background(Color.clear)
    }
}

struct TransactionsRow: View {
    var transaction: TransactionsDatum
    @State private var isActiveNav = true
    var showDate = true
    var showAccount = true
    var animate = true
    var showContextEditAction = true
    var showContextDeleteAction = true
    var showContextWebviewAction = true
    @EnvironmentObject private var pendingDeleteManager: PendingDeleteManager

    init(
        transaction: TransactionsDatum,
        showDate: Bool = true,
        showAccount: Bool = true,
        animate: Bool = true,
        showContextEditAction: Bool = true,
        showContextDeleteAction: Bool = true,
        showContextWebviewAction: Bool = true
    ) {
        self.transaction = transaction
        self.showDate = showDate
        self.showAccount = showAccount
        self.animate = animate
        self.showContextEditAction = showContextEditAction
        self.showContextDeleteAction = showContextDeleteAction
        self.showContextWebviewAction = showContextWebviewAction
    }

    @State private var opacity = 1.0
    @State private var showingActionSheet = false
    @State private var editSheetShown = false
    @State private var cloneSheetShown = false
    @State private var deleteAlertShown = false
    @State private var cloneLoading = false
    @AppStorage(UserDefaultKeys.transactionRowSwipeActions) private var swipeActionsEnabled = false
    @ScaledMetric(relativeTo: .title) private var typeIconFrame: CGFloat = 60

    @Environment(\.transactionZoomNamespace) private var zoomNamespace
    /// Per-row zoom source — see `TransactionRoute`.
    @State private var zoomSourceID = UUID().uuidString

    var body: some View {
        NavigationLink(
            value: TransactionRoute(transactionID: transaction.id ?? "", zoomSourceID: zoomSourceID)
        ) {
            VStack {
                HStack {
                    Image(
                        systemName: transactionTypeIcon(
                            transaction.attributes?.transactions?.first?.type ?? "unknown"
                        )
                    )
                    .foregroundStyle(
                        transactionTypeStyle(
                            transaction.attributes?.transactions?.first?.type ?? "unknown"
                        )
                    )
                    .frame(width: typeIconFrame, height: typeIconFrame)
                    .font(.title)

                    VStack(alignment: .leading) {
                        Text(
                            transactionMainTitle(transaction)
                        )
                        .font(.headline)
                        .lineLimit(1)
                        Text(
                            formatAmount(
                                calculateTransactionTotalAmount(transaction),
                                symbol: transaction.attributes?.transactions?.first?.currencySymbol
                            )
                        )
                        .font(.largeTitle)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Spacer()

                        // In case of split Transaction
                        if transaction.isSplitTransaction {
                            if showAccount {
                                SplitBadge()
                            }
                        } else {
                            if showAccount {
                                if transaction.attributes?.transactions?.first?.sourceName != nil {
                                    Text(
                                        transaction.attributes?.transactions?.first?.sourceName
                                            ?? "Source Error"
                                    )
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                                }
                            }
                        }
                        if showDate {
                            Text(formatDate(transaction.attributes?.transactions?.first?.date))
                                .foregroundStyle(.gray)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8) // Add padding inside the HStack
            }
            .background(.ultraThinMaterial) // Add a background color if needed
            .cornerRadius(12) // Round the corners
            // Anchored inside the row's padding so the zoom starts from the card's
            // visible bounds rather than the full-width tappable area.
            .zoomSource(id: zoomSourceID, in: zoomNamespace, cornerRadius: 12)
            .padding(.horizontal) // Add horizontal padding to the entire row
            .padding(.vertical, 2)
        }
        .buttonStyle(PlainButtonStyle())
        .transition(.opacity.animation(.easeInOut(duration: 0.3)))
        .opacity(opacity)
        .onAppear {
            if animate {
                withAnimation(.easeInOut(duration: 0.1)) {
                    opacity = 1.0
                }
            }
        }
        // Only take effect inside a `transactionSwipeActionsContainer()` (iOS 27+); on
        // older systems rows outside a `List` ignore them and the context menu remains.
        .swipeActions(edge: .leading) {
            if swipeActionsEnabled, showContextEditAction {
                Button("Edit", systemImage: "pencil") {
                    editSheetShown = true
                }
                .tint(.blue)
            }
        }
        .swipeActions(edge: .trailing) {
            // No confirmation alert: PendingDeleteManager always offers an undo window.
            if swipeActionsEnabled, showContextDeleteAction, let id = transaction.id {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    pendingDeleteManager.scheduleDelete(id: id, title: transaction.transactionTitle)
                }
            }
        }
        .contextMenu {
            if showContextEditAction {
                Button("Edit", systemImage: "pencil.circle.fill") {
                    editSheetShown = true
                }
            }

            if showContextDeleteAction {
                Button("Delete", systemImage: "trash.fill", role: .destructive) {
                    deleteAlertShown = true
                }
            }

            if showContextWebviewAction {
                WebviewButton(url: WebviewPaths.transaction(transaction.id!))
            }

            // Clone menu
            Menu {
                Button("Clone and Save", systemImage: "document.on.document.fill") {
                    Task {
                        await cloneAndSave()
                    }
                }
                Button("Clone and Edit", systemImage: "long.text.page.and.pencil.fill") {
                    cloneSheetShown = true
                }
            } label: {
                Label("Clone", systemImage: "document.on.document.fill")
            }
        }
        .sheet(
            isPresented: $editSheetShown,
            content: {
                TransactionEdit(transactionData: transaction)
            }
        )
        .sheet(
            isPresented: $cloneSheetShown,
            content: {
                TransactionCreate(initialTransaction: transaction)
                    .background(.ultraThinMaterial)
            }
        )
        .alert(
            "Are you sure you want to delete the transaction \(transaction.transactionTitle)?",
            isPresented: $deleteAlertShown
        ) {
            Button("Delete", role: .destructive) {
                guard let id = transaction.id else { return }
                pendingDeleteManager.scheduleDelete(
                    id: id, title: transaction.transactionTitle
                )
            }
        }
    }

    /// Clone and save transaction directly
    private func cloneAndSave() async {
        guard let trans = transaction.attributes?.transactions?.first else {
            AppLog.app.error("No transaction data to clone")
            return
        }

        cloneLoading = true
        do {
            try await postTransaction(
                description: trans.description ?? "",
                amount: formatAmountForTextField(
                    trans.amount ?? "0",
                    decimalPlace: trans.currencyDecimalPlaces ?? 2
                ),
                date: Date(), // Use current date and time
                category: trans.categoryName ?? "",
                type: convertTypeToDisplay(trans.type ?? "withdrawal"),
                sourceAccount: (
                    id: trans.sourceID ?? "",
                    name: trans.sourceName ?? ""
                ),
                destinationAccount: (
                    id: trans.destinationID ?? "",
                    name: trans.destinationName ?? ""
                ),
                // Drop the original's location — see the matching note in TransactionDetail's clone.
                notes: TransactionLocation.strip(from: trans.notes) ?? "",
                budgetID: trans.budgetID
            )
            // Trigger refresh on success
            NotificationCenter.default.post(name: AppNotifications.transactionCreated, object: nil)
        } catch {
            AppLog.networkError("Failed to clone transaction", error)
        }
        cloneLoading = false
    }

    /// date formatter specific to this View
    private func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString,
              let date = CachedFormatters.iso8601.date(from: dateString) else {
            return "Unknown Date"
        }

        let calendar = Calendar.current
        let now = Date()

        if calendar.isDate(date, equalTo: now, toGranularity: .day) {
            return "Today"
        }

        if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            return CachedFormatters.weekdayName.string(from: date)
        }
        return CachedFormatters.mediumDate.string(from: date)
    }
}

private extension View {
    @ViewBuilder
    func zoomSource(id: String, in namespace: Namespace.ID?, cornerRadius: CGFloat) -> some View {
        if let namespace {
            matchedTransitionSource(id: id, in: namespace) { source in
                source.clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
        } else {
            self
        }
    }
}

struct SplitBadge: View {
    let text: String
    let imageName: String
    let font: Font
    let foregroundStyle: Color
    let backgroundColor: Color

    init(
        text: String = "Split",
        imageName: String = "arrow.branch",
        font: Font = .subheadline,
        foregroundStyle: Color = .white,
        backgroundColor: Color = .green
    ) {
        self.text = text
        self.imageName = imageName
        self.font = font
        self.foregroundStyle = foregroundStyle
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        HStack {
            Image(systemName: imageName)
            Text(text)
        }
        .font(font)
        .foregroundStyle(foregroundStyle)
        .padding(.horizontal, 10)
        .padding(.vertical, 1)
        .background(backgroundColor)
        .clipShape(Capsule())
    }
}
