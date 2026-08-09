import CoreLocation
import Foundation

/// The outcome of trying to capture a location for a transaction.
///
/// Distinguishes "the user said no" from "we tried and couldn't", because the two need different UI:
/// one offers a link to Settings, the other just quietly says nothing was recorded.
enum LocationCaptureResult {
    case success(TransactionLocation)
    case denied
    case unavailable
}

/// UI-facing capture state for the transaction create screen.
enum LocationCaptureStatus {
    case idle
    case locating
    case captured
    case denied
    case unavailable
}

/// One-shot location capture for the transaction create screen.
///
/// Deliberately minimal: it asks for a single fix, gives up quickly, and never keeps location
/// services running. Nothing here should ever block the user from saving a transaction — every
/// failure path returns rather than throws, and the caller is expected to post without a location.
///
/// Not marked `@MainActor` at the type level so the `CLLocationManagerDelegate` callbacks can satisfy
/// the protocol without isolation mismatches. The manager is created on the main thread, so its
/// delegate callbacks arrive there too, which is what keeps the `@Published` updates and the
/// continuation bookkeeping below free of races.
final class LocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    /// Fixes vaguer than this are discarded. A cold GPS or indoor wifi-only fix can be accurate to
    /// well over a kilometre, and pinning the wrong city block is worse than recording nothing.
    private static let maximumAcceptableAccuracy: CLLocationDistance = 200

    private static let fixTimeout: TimeInterval = 8

    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        authorizationStatus = manager.authorizationStatus
    }

    // MARK: - Public API

    /// Captures the current location and reverse-geocodes it, prompting for permission if needed.
    func capture() async -> LocationCaptureResult {
        let status = await requestAuthorization()

        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            return .denied
        }

        guard let location = await currentLocation() else {
            return .unavailable
        }

        let accuracy = location.horizontalAccuracy
        let name = await placeName(for: location)

        return .success(
            TransactionLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                accuracy: accuracy >= 0 ? accuracy : nil,
                name: name
            )
        )
    }

    /// Whether the user has actively refused location access, as opposed to simply not being asked yet.
    var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    // MARK: - Authorization

    private func requestAuthorization() async -> CLAuthorizationStatus {
        guard authorizationStatus == .notDetermined else { return authorizationStatus }

        return await withCheckedContinuation { continuation in
            // A second caller arriving mid-prompt would otherwise strand the first continuation.
            finishAuthorization(with: authorizationStatus)
            authorizationContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }

    private func finishAuthorization(with status: CLAuthorizationStatus) {
        guard let continuation = authorizationContinuation else { return }
        authorizationContinuation = nil
        continuation.resume(returning: status)
    }

    // MARK: - Fix

    /// Requests a single fix, returning `nil` on error, timeout, or a fix too vague to be useful.
    private func currentLocation() async -> CLLocation? {
        await withCheckedContinuation { continuation in
            // Abandon any in-flight request rather than letting two share one continuation slot.
            finishLocation(with: nil)
            locationContinuation = continuation
            manager.requestLocation()

            Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(Self.fixTimeout * 1_000_000_000))
                self?.finishLocation(with: nil)
            }
        }
    }

    /// The single resume path for `locationContinuation`.
    ///
    /// `didUpdateLocations`, `didFailWithError` and the timeout all race each other, and resuming a
    /// `CheckedContinuation` twice is a hard crash — so the continuation is cleared before it is
    /// resumed, and every later caller becomes a no-op.
    private func finishLocation(with location: CLLocation?) {
        guard let continuation = locationContinuation else { return }
        locationContinuation = nil

        guard let location else {
            continuation.resume(returning: nil)
            return
        }

        let accuracy = location.horizontalAccuracy
        let isUsable = accuracy >= 0 && accuracy <= Self.maximumAcceptableAccuracy
        continuation.resume(returning: isUsable ? location : nil)
    }

    // MARK: - Reverse geocoding

    /// Best-effort place name. Failure is expected and fine — the marker simply omits the name.
    private func placeName(for location: CLLocation) async -> String? {
        guard let placemark = try? await CLGeocoder().reverseGeocodeLocation(location).first else {
            return nil
        }

        // `name` is usually the POI or street address; pairing it with the locality gives something
        // recognisable without turning into a full postal address.
        let parts = [placemark.name ?? placemark.thoroughfare, placemark.locality]
            .compactMap(\.self)
            .reduce(into: [String]()) { result, part in
                if !result.contains(part) { result.append(part) }
            }

        return parts.isEmpty ? nil : parts.joined(separator: ", ")
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if authorizationStatus != .notDetermined {
            finishAuthorization(with: authorizationStatus)
        }
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        finishLocation(with: locations.last)
    }

    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        AppLog.appError("Failed to get location for transaction", error)
        finishLocation(with: nil)
    }
}
