import Foundation

/// A transaction group with at least one split whose notes marker still needs moving into
/// Firefly's native location fields — see `docs/LOCATION_IN_NOTES.md`.
struct LocationMigrationItem: Identifiable {
    let groupID: String
    let title: String
    let groupTitle: String?
    let splits: [TransactionsTransaction]

    var id: String {
        groupID
    }
}

/// PUT body for one group.
///
/// Deliberately separate from `PostTransaction`: it carries only what the migration changes, plus the
/// identifiers Firefly needs to leave everything else alone.
///
/// - Every split is listed with its `transaction_journal_id`. On a group with more than one split,
///   Firefly deletes any existing split the PUT doesn't name by ID, and creates a new split for any
///   entry without one (`GroupUpdateService::update`). A split with nothing to change is sent as its
///   ID alone, which the server treats as "no change".
/// - `group_title` is required whenever more than one split is sent (`validateGroupDescription`).
/// - Rules and webhooks are off: this changes bookkeeping, not the transaction, and shouldn't
///   re-trigger anything the user has automated.
private struct LocationMigrationUpdate: Encodable {
    let applyRules = false
    let fireWebhooks = false
    let groupTitle: String?
    let transactions: [Split]

    struct Split: Encodable {
        let transactionJournalID: String
        var latitude, longitude: Double?
        var zoomLevel: Int?
        var notes: String?

        enum CodingKeys: String, CodingKey {
            case transactionJournalID = "transaction_journal_id"
            case latitude, longitude
            case zoomLevel = "zoom_level"
            case notes
        }
    }

    enum CodingKeys: String, CodingKey {
        case applyRules = "apply_rules"
        case fireWebhooks = "fire_webhooks"
        case groupTitle = "group_title"
        case transactions
    }
}

enum LocationMigrationError: LocalizedError {
    case invalidResponse(statusCode: Int?)
    case missingJournalID
    case locationNotSaved

    var errorDescription: String? {
        switch self {
        case .invalidResponse(let statusCode):
            "The server rejected the update (status \(statusCode.map(String.init) ?? "unknown"))."
        case .missingJournalID:
            "A split is missing its ID, so it can't be updated safely."
        case .locationNotSaved:
            "The server accepted the update but didn't save the location."
        }
    }
}

/// Backfills Firefly's native location fields from Hotaru's notes markers.
///
/// Two steps, so nothing is written until the user has seen what will change: `scan()` finds the
/// groups that need work, `migrate()` updates them one at a time.
///
/// Whether the marker is also removed from the notes follows `AppSettings.writeLocationToNotes`:
/// with it on, the user wants markers kept, so only the native fields are filled in.
@MainActor
final class LocationMigrationViewModel: ObservableObject {
    /// PUT only stores a location from this version on (`JournalUpdateService::updateLocation`).
    /// Earlier servers would accept the request, drop the location, and — with notes cleanup on —
    /// lose it entirely.
    static let minimumServerVersion = [6, 7, 0]

    private static let searchQuery = #"notes_contains:"hotaru:loc""#
    private static let pageSize = 50

    /// Guards against a server whose pagination never reports a last page.
    private static let maxPages = 200

    @Published private(set) var serverVersion: String?
    @Published private(set) var isServerSupported = false
    @Published private(set) var hasCheckedServer = false
    @Published private(set) var isScanning = false
    @Published private(set) var isMigrating = false
    @Published private(set) var items: [LocationMigrationItem]?
    @Published private(set) var completedCount = 0
    @Published private(set) var failures: [(title: String, reason: String)] = []
    @Published private(set) var hasFinished = false
    @Published private(set) var errorMessage: String?

    /// Captured at scan time so the plan shown and the plan run can't disagree if the setting is
    /// flipped in between.
    @Published private(set) var keepsNotes = AppSettings.writeLocationToNotes

    // MARK: - Scan

    func scan() async {
        isScanning = true
        errorMessage = nil
        items = nil
        hasFinished = false
        completedCount = 0
        failures = []
        keepsNotes = AppSettings.writeLocationToNotes

        defer { isScanning = false }

        do {
            let version = try await fetchServerVersion()
            serverVersion = version
            isServerSupported = Self.isSupported(version: version)
            hasCheckedServer = true

            guard isServerSupported else { return }

            // Collect every page before changing anything: removing markers as we go would shift
            // later search pages and skip results.
            items = try await fetchCandidates().compactMap { Self.item(for: $0, keepsNotes: keepsNotes) }
        } catch {
            AppLog.networkError("Failed to scan for location markers", error)
            errorMessage = error.localizedDescription
        }
    }

    private func fetchServerVersion() async throws -> String? {
        let request = try RequestBuilder(apiURL: ApiPaths.systemAbout)
        let (data, response) = try await AppNetworking.session.data(for: request)

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw LocationMigrationError.invalidResponse(
                statusCode: (response as? HTTPURLResponse)?.statusCode
            )
        }

        return try JSONDecoder().decode(SystemInfo.self, from: data).data?.version
    }

    /// Accepts `6.7.3` and `v6.7.3`. Anything unparseable (e.g. a `develop/…` build) counts as
    /// unsupported: running this against a server that drops locations on PUT loses data.
    static func isSupported(version: String?) -> Bool {
        guard let version else { return false }

        let trimmed = version.hasPrefix("v") ? String(version.dropFirst()) : version
        let parts = trimmed.split(separator: ".").map { Int($0.prefix(while: \.isNumber)) }

        guard parts.count >= 2, parts.allSatisfy({ $0 != nil }) else { return false }

        let numbers = parts.compactMap(\.self) + Array(repeating: 0, count: max(0, 3 - parts.count))
        return numbers.lexicographicallyPrecedes(minimumServerVersion) == false
    }

    private func fetchCandidates() async throws -> [TransactionsDatum] {
        var results: [TransactionsDatum] = []
        var page = 1

        while page <= Self.maxPages {
            var request = try RequestBuilder(apiURL: ApiPaths.searchTransactions)
            request.url?.append(queryItems: [
                URLQueryItem(name: "query", value: Self.searchQuery),
                URLQueryItem(name: "limit", value: String(Self.pageSize)),
                URLQueryItem(name: "page", value: String(page)),
            ])

            let (data, response) = try await AppNetworking.session.data(for: request)

            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                throw LocationMigrationError.invalidResponse(
                    statusCode: (response as? HTTPURLResponse)?.statusCode
                )
            }

            let decoded = try JSONDecoder().decode(Transactions.self, from: data)
            let pageData = decoded.data ?? []
            results.append(contentsOf: pageData)

            let totalPages = decoded.meta?.pagination?.totalPages ?? page
            guard !pageData.isEmpty, page < totalPages else { break }
            page += 1
        }

        return results
    }

    /// The search is only a coarse filter, so each result is re-checked with the real parser.
    private static func item(for datum: TransactionsDatum, keepsNotes: Bool) -> LocationMigrationItem? {
        guard let groupID = datum.id,
              let splits = datum.attributes?.transactions,
              splits.contains(where: { splitUpdate(for: $0, keepsNotes: keepsNotes) != nil }) else {
            return nil
        }

        return LocationMigrationItem(
            groupID: groupID,
            title: datum.attributes?.groupTitle ?? splits.first?.description ?? "Transaction #\(groupID)",
            groupTitle: datum.attributes?.groupTitle,
            splits: splits
        )
    }

    /// What needs changing on one split, or `nil` if nothing does.
    ///
    /// - Marker, no native location: copy the marker's coordinates into the native fields.
    /// - Marker and native location: the native one wins (it may have been moved in the web UI), so
    ///   only the notes need cleaning — and only if the user isn't keeping markers.
    private static func splitUpdate(
        for split: TransactionsTransaction, keepsNotes: Bool
    ) -> LocationMigrationUpdate.Split? {
        guard let journalID = split.transactionJournalID,
              let marker = TransactionLocation.parse(from: split.notes) else {
            return nil
        }

        var update = LocationMigrationUpdate.Split(transactionJournalID: journalID)
        var changed = false

        if TransactionLocation.fromNativeFields(split) == nil {
            update.latitude = marker.latitude
            update.longitude = marker.longitude
            update.zoomLevel = TransactionLocation.nativeZoomLevel
            changed = true
        }

        if !keepsNotes {
            // Empty rather than nil: nil is omitted from the JSON and would leave the marker there.
            update.notes = TransactionLocation.strip(from: split.notes) ?? ""
            changed = true
        }

        return changed ? update : nil
    }

    // MARK: - Migrate

    func migrate() async {
        guard let items, isServerSupported else { return }

        isMigrating = true
        completedCount = 0
        failures = []

        for item in items {
            do {
                try await migrate(item)
            } catch {
                AppLog.networkError("Failed to migrate location for group \(item.groupID)", error)
                failures.append((item.title, error.localizedDescription))
            }
            completedCount += 1
        }

        isMigrating = false
        hasFinished = true

        NotificationCenter.default.post(
            name: AppNotifications.transactionUpdated, object: nil,
            userInfo: ["message": "Locations migrated"]
        )
    }

    /// Two requests per group, in this order, so a marker is never removed before its location is
    /// confirmed saved: first the native fields (then check the response actually has them), then
    /// the notes cleanup.
    private func migrate(_ item: LocationMigrationItem) async throws {
        var updates: [LocationMigrationUpdate.Split] = []

        for split in item.splits {
            guard let journalID = split.transactionJournalID else {
                throw LocationMigrationError.missingJournalID
            }

            updates.append(
                Self.splitUpdate(for: split, keepsNotes: keepsNotes)
                    ?? LocationMigrationUpdate.Split(transactionJournalID: journalID)
            )
        }

        let expectsLocation = Set(updates.filter { $0.latitude != nil }.map(\.transactionJournalID))

        if !expectsLocation.isEmpty {
            let locationOnly = updates.map { update in
                var copy = update
                copy.notes = nil
                return copy
            }
            let saved = try await put(locationOnly, for: item)

            let savedIDs = Set(
                saved.filter { TransactionLocation.fromNativeFields($0) != nil }
                    .compactMap(\.transactionJournalID)
            )
            guard expectsLocation.isSubset(of: savedIDs) else {
                throw LocationMigrationError.locationNotSaved
            }
        }

        if updates.contains(where: { $0.notes != nil }) {
            let notesOnly = updates.map { update in
                var copy = LocationMigrationUpdate.Split(transactionJournalID: update.transactionJournalID)
                copy.notes = update.notes
                return copy
            }
            _ = try await put(notesOnly, for: item)
        }
    }

    /// Sends one update for `item` and returns the splits as the server now has them.
    private func put(
        _ splits: [LocationMigrationUpdate.Split], for item: LocationMigrationItem
    ) async throws -> [TransactionsTransaction] {
        let body = LocationMigrationUpdate(
            groupTitle: item.splits.count > 1 ? item.groupTitle : nil, transactions: splits
        )

        var request = try RequestBuilder(
            apiURL: PutApiPaths.editTransaction(item.groupID), httpMethod: "PUT"
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await AppNetworking.session.data(for: request)

        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw LocationMigrationError.invalidResponse(
                statusCode: (response as? HTTPURLResponse)?.statusCode
            )
        }

        return try JSONDecoder().decode(TransactionDetailDatum.self, from: data)
            .data?.attributes?.transactions ?? []
    }
}
