import SwiftUI

/// Settings screen that moves locations out of notes markers and into Firefly's own location fields.
///
/// Scans first and shows what it found; nothing is written until the user confirms.
struct LocationMigrationView: View {
    @StateObject private var viewModel = LocationMigrationViewModel()
    @State private var showConfirmation = false

    var body: some View {
        List {
            Section {
                Text("""
                Older versions of Hotaru saved locations as a hidden line in the transaction's notes. \
                This copies those locations into Firefly III's own location fields, so the web \
                interface and other apps can show them on a map too.
                """)
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            if viewModel.isScanning {
                Section {
                    HStack {
                        ProgressView()
                        Text("Looking for transactions…")
                            .foregroundStyle(.secondary)
                    }
                }
            } else if let errorMessage = viewModel.errorMessage {
                Section {
                    ErrorStateView(
                        message: "Couldn't scan transactions: \(errorMessage)",
                        onRetry: { Task { await viewModel.scan() } }
                    )
                }
            } else if viewModel.hasCheckedServer, !viewModel.isServerSupported {
                Section {
                    Label {
                        Text("""
                        This needs Firefly III 6.7.0 or newer. Your server reports version \
                        \(viewModel.serverVersion ?? "unknown"), which would ignore the update — \
                        your locations are safer left in the notes.
                        """)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            } else if let items = viewModel.items {
                resultSections(items)
            }
        }
        .navigationTitle("Move Locations")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.scan() }
        .confirmationDialog(
            "Update \(viewModel.items?.count ?? 0) transactions?",
            isPresented: $showConfirmation, titleVisibility: .visible
        ) {
            Button("Update") { Task { await viewModel.migrate() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(planDescription)
        }
    }

    @ViewBuilder
    private func resultSections(_ items: [LocationMigrationItem]) -> some View {
        if viewModel.hasFinished {
            Section {
                let succeeded = items.count - viewModel.failures.count
                Label(
                    "Updated \(succeeded) of \(items.count) transactions",
                    systemImage: viewModel.failures.isEmpty
                        ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
                )
                .foregroundStyle(viewModel.failures.isEmpty ? .green : .orange)
            }

            if !viewModel.failures.isEmpty {
                Section {
                    ForEach(Array(viewModel.failures.enumerated()), id: \.offset) { _, failure in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(failure.title)
                            Text(failure.reason)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Not updated")
                } footer: {
                    Text("These still have their location in the notes, so nothing was lost. Scan again to retry.")
                }
            }

            Section {
                Button("Scan Again") { Task { await viewModel.scan() } }
            }
        } else if items.isEmpty {
            Section {
                EmptyStateView(
                    icon: "checkmark.circle",
                    message: viewModel.keepsNotes
                        ? "Every location in your notes is already saved in Firefly III."
                        : "No transactions have a location saved in their notes."
                )
            }
        } else if viewModel.isMigrating {
            Section {
                ProgressView(
                    value: Double(viewModel.completedCount), total: Double(items.count)
                ) {
                    Text("Updating \(viewModel.completedCount) of \(items.count)…")
                }
            } footer: {
                Text("Keep this screen open until it finishes.")
            }
        } else {
            Section {
                Text(planDescription)
                    .font(.callout)
                Button("Update \(items.count) Transactions") { showConfirmation = true }
            } header: {
                Text("Found \(items.count) \(items.count == 1 ? "transaction" : "transactions")")
            }
        }
    }

    private var planDescription: String {
        if viewModel.keepsNotes {
            return """
            Each location is copied into Firefly III. The line in the notes is kept, because \
            "Also save location in notes" is on.
            """
        }

        return """
        Each location is copied into Firefly III, checked, and only then removed from the notes. \
        Firefly III doesn't store the place name or accuracy; Hotaru looks the name up when showing \
        the map instead.
        """
    }
}

#Preview {
    NavigationStack {
        LocationMigrationView()
    }
}
