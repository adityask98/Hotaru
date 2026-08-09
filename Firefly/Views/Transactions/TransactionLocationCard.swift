import MapKit
import SwiftUI

/// Inline map for a transaction's recorded location.
///
/// The location comes either from Firefly's native `latitude`/`longitude` fields or, far more likely,
/// from the marker Hotaru writes into the notes — see `TransactionLocation` and
/// `docs/LOCATION_IN_NOTES.md`.
struct TransactionLocationCard: View {
    let location: TransactionLocation

    /// Tight enough to show the street, loose enough that a mediocre fix doesn't look precise.
    private static let span = MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)

    private var region: MKCoordinateRegion {
        MKCoordinateRegion(center: location.coordinate, span: Self.span)
    }

    private var caption: String? {
        var parts: [String] = []

        if let name = location.name {
            parts.append(name)
        }

        if let accuracy = location.accuracy, accuracy > 0 {
            parts.append("±\(Int(accuracy.rounded())) m")
        }

        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Map(initialPosition: .region(region), interactionModes: []) {
                Marker(location.name ?? "Transaction", coordinate: location.coordinate)

                if let accuracy = location.accuracy, accuracy > 0 {
                    MapCircle(center: location.coordinate, radius: accuracy)
                        .foregroundStyle(Color.accentColor.opacity(0.15))
                        .stroke(Color.accentColor.opacity(0.4), lineWidth: 1)
                }
            }
            .frame(height: 180)
            // The map is inert so it never steals the parent ScrollView's gestures; tapping the card
            // hands off to Maps instead.
            .allowsHitTesting(false)

            if let caption {
                HStack(spacing: 6) {
                    Text(caption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "arrow.up.forward.app")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18.0))
        .contentShape(RoundedRectangle(cornerRadius: 18.0))
        .onTapGesture(perform: openInMaps)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(caption.map { "Location: \($0)" } ?? "Transaction location")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Opens in Maps")
    }

    private func openInMaps() {
        let placemark = MKPlacemark(coordinate: location.coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = location.name ?? "Transaction"
        item.openInMaps()
    }
}
