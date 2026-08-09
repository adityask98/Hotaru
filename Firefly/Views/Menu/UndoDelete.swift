import Combine
import SwiftUI

// MARK: - PendingDeleteManager

/// Handles transaction deletion with an undo window.
///
/// Deletes are not sent to the server immediately. Instead they are scheduled,
/// a snackbar with an Undo button is shown (see `UndoSnackbar`), and the actual
/// DELETE request is only performed once the timeout elapses. Undoing cancels
/// the request before it is ever sent, so nothing needs to be re-created.
///
/// The timeout is configurable in Settings (`UserDefaultKeys.undoTimeoutSeconds`).
@MainActor
final class PendingDeleteManager: ObservableObject {
    struct PendingDelete: Identifiable, Equatable {
        let id: String
        let title: String
    }

    /// The delete currently awaiting its timeout (drives the snackbar).
    @Published private(set) var pending: PendingDelete?

    /// IDs hidden from transaction lists: pending deletes plus already-committed
    /// deletes that the server-backed lists haven't refreshed away yet.
    @Published private(set) var hiddenIDs: Set<String> = []

    private var countdownTask: Task<Void, Never>?

    static let defaultTimeoutSeconds = 5

    var timeoutSeconds: Int {
        let stored = UserDefaults.standard.integer(forKey: UserDefaultKeys.undoTimeoutSeconds)
        return stored > 0 ? stored : Self.defaultTimeoutSeconds
    }

    /// Schedules a transaction for deletion after the undo timeout.
    /// If another delete is already pending, it is committed immediately.
    func scheduleDelete(id: String, title: String) {
        commitNow()

        pending = PendingDelete(id: id, title: title)
        hiddenIDs.insert(id)

        countdownTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .seconds(self.timeoutSeconds))
            guard !Task.isCancelled else { return }
            self.commitNow()
        }
    }

    /// Cancels the pending delete and restores the row.
    func undo() {
        countdownTask?.cancel()
        countdownTask = nil
        if let pending {
            hiddenIDs.remove(pending.id)
        }
        pending = nil
    }

    /// Commits the pending delete immediately, skipping the remaining timeout.
    /// Called on app backgrounding so a scheduled delete is not lost.
    func commitNow() {
        countdownTask?.cancel()
        countdownTask = nil
        guard let item = pending else { return }
        pending = nil

        Task {
            do {
                try await deleteTransaction(transactionID: item.id)
                // Keep the ID hidden; lists refresh from the server via this notification.
                NotificationCenter.default.post(
                    name: AppNotifications.transactionDeleted, object: nil
                )
            } catch {
                // Restore the row and surface the failure as a toast.
                hiddenIDs.remove(item.id)
                NotificationCenter.default.post(
                    name: AppNotifications.operationFailed, object: nil,
                    userInfo: ["message": "Failed to delete \"\(item.title)\""]
                )
                AppLog.networkError("Failed to delete transaction", error)
            }
        }
    }
}

// MARK: - UndoSnackbar

/// Bottom snackbar shown while a delete is pending, offering Undo.
struct UndoSnackbar: View {
    let title: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trash.fill")
                .foregroundStyle(.red)
            Text("Deleted \"\(title)\"")
                .font(.subheadline)
                .lineLimit(1)
            Spacer(minLength: 8)
            Button("Undo") {
                onUndo()
            }
            .font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Deleted \(title). Undo available.")
    }
}

#Preview {
    UndoSnackbar(title: "Groceries", onUndo: {})
}
