import Foundation
import CoreLocation

// One-shot location → sunrise/sunset via NOAA solar formula (~60 lines, zero deps).
// Returns two optimal nudge times: mid-morning + mid-afternoon.
// Simulator: uses a default latitude when location unavailable.
final class SolarCalculator: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<DaylightWindows, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    struct DaylightWindows {
        let morningNudge: Date   // ~2h after sunrise
        let afternoonNudge: Date // ~2h before sunset
    }

    func compute() async -> DaylightWindows {
        // Simulator/CoreLocation can fail to resolve — default to SF lat/lon
        // as a fallback only, not a macOS-wide substitute (CoreLocation works
        // fine on native macOS 10.15+).
        let fallback = computeFor(lat: 37.77, lon: -122.42)
        let status = manager.authorizationStatus
        #if os(macOS)
        let isAuthorized = status == .authorizedAlways
        #else
        let isAuthorized = status == .authorizedWhenInUse
        #endif
        guard isAuthorized || status == .notDetermined else {
            return fallback
        }
        return await withCheckedContinuation { cont in
            self.continuation = cont
            manager.requestWhenInUseAuthorization()
            manager.requestLocation()
            // 3s timeout — if location fails to resolve, use fallback.
            // Routed through main so it can never race the delegate's finish
            // call (both now touch `continuation` only from main).
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self, self.continuation != nil else { return }
                self.finish(fallback)
            }
        }
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    private func finish(_ windows: DaylightWindows) {
        let cont = continuation
        continuation = nil
        cont?.resume(returning: windows)
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ mgr: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let windows: DaylightWindows
        if let coord = locations.last?.coordinate {
            windows = computeFor(lat: coord.latitude, lon: coord.longitude)
        } else {
            windows = computeFor(lat: 37.77, lon: -122.42)
        }
        DispatchQueue.main.async { self.finish(windows) }
    }

    func locationManager(_ mgr: CLLocationManager, didFailWithError error: Error) {
        let windows = computeFor(lat: 37.77, lon: -122.42)
        DispatchQueue.main.async { self.finish(windows) }
    }

    // MARK: - NOAA solar calculation (simplified)

    func computeFor(lat: Double, lon: Double, now: Date = Date()) -> DaylightWindows {
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(identifier: "UTC")!
        let dayOfYear = Double(utcCal.ordinality(of: .day, in: .year, for: now) ?? 1)

        // Solar declination (degrees)
        let decl = 23.45 * sin(deg2rad(360 * (284 + dayOfYear) / 365))

        // Hour angle at sunrise/sunset (degrees)
        let latRad = deg2rad(lat)
        let declRad = deg2rad(decl)
        let cosH = -tan(latRad) * tan(declRad)
        let clampedCosH = max(-1, min(1, cosH))
        let hourAngle = rad2deg(acos(clampedCosH))  // degrees

        // Sunrise/sunset in UTC minutes (lon positive = east)
        let solarNoonMin = 720 - lon / 15.0 * 60
        let sunriseMin = solarNoonMin - hourAngle / 15.0 * 60
        let sunsetMin = solarNoonMin + hourAngle / 15.0 * 60

        // Mid-morning = 2h after sunrise, mid-afternoon = 2h before sunset
        let morningMin = sunriseMin + 120
        let afternoonMin = sunsetMin - 120

        // sunriseMin/sunsetMin are UTC minutes-of-day — anchor to the UTC
        // start of day, not the caller's local start of day, or the nudge
        // times drift by the local UTC offset (previously wrong outside UTC).
        let startOfDayUTC = utcCal.startOfDay(for: now)
        let morning = startOfDayUTC.addingTimeInterval(morningMin * 60)
        let afternoon = startOfDayUTC.addingTimeInterval(afternoonMin * 60)

        // If both times have already passed today, they'll just be in the past —
        // the scheduler won't fire them. Next day's compute() will be fresh.
        return DaylightWindows(morningNudge: morning, afternoonNudge: afternoon)
    }

    private func deg2rad(_ d: Double) -> Double { d * .pi / 180 }
    private func rad2deg(_ r: Double) -> Double { r * 180 / .pi }
}
