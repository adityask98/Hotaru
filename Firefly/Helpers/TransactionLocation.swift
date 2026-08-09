import CoreLocation
import Foundation

/// A location attached to a transaction, encoded as a marker line inside the transaction's `notes`.
///
/// Firefly III's API returns `latitude`/`longitude`/`zoom_level` on transactions but its POST/PUT
/// schemas don't define them (see `docs/Firefly III 6.6.6.yaml` — `TransactionSplit` has them,
/// `TransactionSplitStore`/`TransactionSplitUpdate` do not), so there is no supported way to set a
/// location when creating a transaction. This type is the stopgap: it round-trips a location through
/// the notes field instead.
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
    /// The value for Firefly's native `latitude`/`longitude` string fields on a transaction POST/PUT.
    ///
    /// The 6.6.6 spec doesn't define these on the write schemas, so the server is expected to drop
    /// them — we send them anyway because it costs nothing, and any server that does honour them
    /// gets a real location without needing the notes marker at all.
    var nativeLatitude: String {
        Self.format(latitude)
    }

    var nativeLongitude: String {
        Self.format(longitude)
    }

    /// Reads Firefly's native location fields off a fetched transaction, if the server populated them.
    ///
    /// Preferred over `parse(from:)` at read time so the app upgrades for free if Firefly ever ships
    /// real write support.
    static func fromNativeFields(_ transaction: TransactionsTransaction?) -> TransactionLocation? {
        guard let latitude = transaction?.latitude, let longitude = transaction?.longitude else {
            return nil
        }

        return TransactionLocation(
            latitude: latitude, longitude: longitude, accuracy: nil, name: nil
        )
    }

    /// The location for a fetched transaction: Firefly's own fields if present, else our marker.
    static func resolve(for transaction: TransactionsTransaction?) -> TransactionLocation? {
        fromNativeFields(transaction) ?? parse(from: transaction?.notes)
    }
}
