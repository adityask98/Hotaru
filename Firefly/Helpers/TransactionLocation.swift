import CoreLocation
import Foundation

/// A location attached to a transaction.
///
/// Saved in Firefly's native `latitude`/`longitude`/`zoom_level` fields — the spec only lists them
/// on the read schema (`TransactionSplit` in `docs/Firefly III 6.7.2.yaml`), but the server accepts
/// them on POST and PUT too; see "Firefly's native fields" below.
///
/// It can also be encoded as a marker line inside the transaction's `notes` — the workaround from
/// before the native fields were known to work. Writing the marker is opt-in
/// (`AppSettings.writeLocationToNotes`); reading it is not, so older transactions keep their location.
///
/// The marker is appended as the final line of the notes, separated by a blank line:
///
///     Groceries for the week
///
///     [hotaru:loc v1 lat=12.971600 lon=77.594600 acc=12 name="Whole Foods, Indiranagar"]
///
/// The marker must never be shown to the user — every display and re-entry point strips it. See
/// `docs/LOCATION_IN_NOTES.md` for the full list and the migration plan.
struct TransactionLocation: Equatable {
    let latitude: Double
    let longitude: Double

    /// Horizontal accuracy in metres, if it was known at capture time.
    let accuracy: Double?

    /// Reverse-geocoded place name. Optional — geocoding is best-effort and fails soft.
    let name: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Encoding

extension TransactionLocation {
    private static let markerPrefix = "[hotaru:loc v1 "

    /// Coordinates are written to 6 decimal places (~11cm), far beyond what a phone fix justifies but
    /// enough that the string form never loses anything meaningful.
    private static let coordinatePrecision = 6

    /// Place names are sanitised rather than escaped: `]`, `"` and `\` are removed outright, which
    /// keeps the parser a simple "everything up to the closing bracket" match with no escaping scheme
    /// to get wrong on either side. Real place names don't contain those characters.
    private static let forbiddenNameCharacters = CharacterSet(charactersIn: "]\"\\")

    private static let maxNameLength = 60

    /// The encoded marker line on its own, without surrounding whitespace.
    var markerLine: String {
        var fields = [
            "lat=\(Self.format(latitude))",
            "lon=\(Self.format(longitude))",
        ]

        if let accuracy, accuracy.isFinite, accuracy >= 0 {
            fields.append("acc=\(Int(accuracy.rounded()))")
        }

        if let sanitised = Self.sanitiseName(name) {
            fields.append("name=\"\(sanitised)\"")
        }

        return Self.markerPrefix + fields.joined(separator: " ") + "]"
    }

    /// Returns `notes` with this location's marker as its final line.
    ///
    /// Any existing marker is removed first, so applying this repeatedly never stacks two markers —
    /// which matters because the edit screen re-appends on every save.
    func appended(to notes: String) -> String {
        let body = TransactionLocation.strip(from: notes) ?? ""
        return body.isEmpty ? markerLine : body + "\n\n" + markerLine
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.\(coordinatePrecision)f", value)
    }

    private static func sanitiseName(_ name: String?) -> String? {
        guard let name else { return nil }

        // Removing the forbidden characters can leave gaps behind ("Bob's ] Grill"), so collapse
        // runs of whitespace afterwards rather than shipping a name with holes in it.
        let stripped = name
            .components(separatedBy: forbiddenNameCharacters).joined()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        guard !stripped.isEmpty else { return nil }

        return String(stripped.prefix(maxNameLength)).trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Parsing

extension TransactionLocation {
    /// Matches the whole marker plus any blank lines leading up to it, so stripping leaves no
    /// trailing gap behind.
    private static let markerRegex = try? NSRegularExpression(
        pattern: #"\n*\[hotaru:loc v1 ([^\]]*)\]"#
    )

    /// Extracts the location encoded in `notes`, if there is one.
    static func parse(from notes: String?) -> TransactionLocation? {
        guard let notes, let regex = markerRegex else { return nil }

        let range = NSRange(notes.startIndex..<notes.endIndex, in: notes)

        // Last match wins: if a transaction somehow ended up with two markers, the most recently
        // appended one is the current location.
        guard let match = regex.matches(in: notes, range: range).last,
              let bodyRange = Range(match.range(at: 1), in: notes) else {
            return nil
        }

        let fields = parseFields(String(notes[bodyRange]))

        guard let latitude = fields["lat"].flatMap(Double.init),
              let longitude = fields["lon"].flatMap(Double.init),
              CLLocationCoordinate2DIsValid(
                  CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
              ) else {
            return nil
        }

        return TransactionLocation(
            latitude: latitude,
            longitude: longitude,
            accuracy: fields["acc"].flatMap(Double.init),
            name: fields["name"]
        )
    }

    /// Returns `notes` with any marker removed, or `nil` if nothing but whitespace remains — letting
    /// callers hide an empty notes section rather than render a blank card.
    static func strip(from notes: String?) -> String? {
        guard let notes else { return nil }
        guard let regex = markerRegex else { return notes }

        let range = NSRange(notes.startIndex..<notes.endIndex, in: notes)
        let stripped = regex
            .stringByReplacingMatches(in: notes, range: range, withTemplate: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return stripped.isEmpty ? nil : stripped
    }

    /// Splits `lat=1.5 lon=2.5 name="Some Place"` into its key/value pairs.
    ///
    /// Hand-rolled rather than regex'd because the quoted name may contain the spaces that otherwise
    /// separate fields.
    private static func parseFields(_ body: String) -> [String: String] {
        var fields: [String: String] = [:]
        var remainder = Substring(body)

        while !remainder.isEmpty {
            remainder = remainder.drop(while: { $0 == " " })

            guard let equals = remainder.firstIndex(of: "=") else { break }

            let key = String(remainder[remainder.startIndex..<equals])
            var value = remainder[remainder.index(after: equals)...]

            if value.first == "\"" {
                value = value.dropFirst()
                let end = value.firstIndex(of: "\"") ?? value.endIndex
                fields[key] = String(value[value.startIndex..<end])
                remainder = end == value.endIndex ? "" : value[value.index(after: end)...]
            } else {
                let end = value.firstIndex(of: " ") ?? value.endIndex
                fields[key] = String(value[value.startIndex..<end])
                remainder = value[end...]
            }
        }

        return fields
    }
}

// MARK: - Firefly's native fields

extension TransactionLocation {
    /// The zoom level sent with a location we captured ourselves.
    ///
    /// The spec leaves `latitude`/`longitude`/`zoom_level` off the write schemas, but the server
    /// accepts them anyway: POST has stored them since before 6.6.6, and PUT since 6.7.0. On create,
    /// though, `TransactionJournalFactory::storeLocation` saves nothing unless **all three** are
    /// non-null, and it doesn't return an error. Zoom is only used to frame a map in Firefly's web
    /// UI (valid range 0–80); 15 is roughly street level there.
    static let nativeZoomLevel = 15

    /// Copies this location into Firefly's native fields on an outgoing split.
    ///
    /// `zoomLevel` defaults to `nativeZoomLevel`; pass the server's own value when echoing back a
    /// location it already has, so an edit doesn't reframe the web UI's map.
    func apply(to element: inout PostTransactionElement, zoomLevel: Int? = nil) {
        element.latitude = latitude
        element.longitude = longitude
        element.zoomLevel = zoomLevel ?? Self.nativeZoomLevel
    }

    /// Marks an outgoing split's location for deletion: all three fields as explicit JSON `null`,
    /// which `JournalUpdateService::updateLocation` treats as "delete" (6.7.0+).
    static func clear(on element: inout PostTransactionElement) {
        element.latitude = .some(nil)
        element.longitude = .some(nil)
        element.zoomLevel = .some(nil)
    }

    /// Reads Firefly's native location fields off a fetched transaction, if the server populated them.
    ///
    /// Carries only coordinates — Firefly doesn't store accuracy or a place name. See `resolve(for:)`.
    static func fromNativeFields(_ transaction: TransactionsTransaction?) -> TransactionLocation? {
        guard let latitude = transaction?.latitude, let longitude = transaction?.longitude else {
            return nil
        }

        return TransactionLocation(
            latitude: latitude, longitude: longitude, accuracy: nil, name: nil
        )
    }

    /// How far apart the native location and the notes marker can be and still count as the same
    /// place. They normally differ only by the marker's 6-decimal rounding; anything further means
    /// the location was moved elsewhere (e.g. in the web UI) and the marker's name is stale.
    private static let sameLocationTolerance: CLLocationDistance = 100

    /// The location for a fetched transaction.
    ///
    /// Firefly's own coordinates win when present, falling back to the notes marker. When both exist
    /// and agree, the marker's accuracy and place name are kept alongside the native coordinates.
    static func resolve(for transaction: TransactionsTransaction?) -> TransactionLocation? {
        let marker = parse(from: transaction?.notes)

        guard let native = fromNativeFields(transaction) else { return marker }
        guard let marker, native.distance(to: marker) <= sameLocationTolerance else { return native }

        return TransactionLocation(
            latitude: native.latitude, longitude: native.longitude,
            accuracy: marker.accuracy, name: marker.name
        )
    }

    private func distance(to other: TransactionLocation) -> CLLocationDistance {
        CLLocation(latitude: latitude, longitude: longitude)
            .distance(from: CLLocation(latitude: other.latitude, longitude: other.longitude))
    }
}
