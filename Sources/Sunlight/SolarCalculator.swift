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
        // ponytail: Simulator/CoreLocation often fails — default to SF lat/lon.
        let fallback = computeFor(lat: 37.77, lon: -122.42)
        guard manager.authorizationStatus == .authorizedWhenInUse
                || manager.authorizationStatus == .notDetermined else {
            return fallback
        }
        return await withCheckedContinuation { cont in
            self.continuation = cont
            manager.requestWhenInUseAuthorization()
            manager.requestLocation()
            // ponytail: 3s timeout — if location fails, use fallback
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
        let coord = locations.last?.coordinate
        let windows = coord != nil
            ? computeFor(lat: coord!.latitude, lon: coord!.longitude)
            : computeFor(lat: 37.77, lon: -122.42)
        finish(windows)
    }

    func locationManager(_ mgr: CLLocationManager, didFailWithError error: Error) {
        finish(computeFor(lat: 37.77, lon: -122.42))
    }

    // MARK: - NOAA solar calculation (simplified)

    func computeFor(lat: Double, lon: Double) -> DaylightWindows {
        let now = Date()
        let cal = Calendar.current
        let dayOfYear = Double(cal.ordinality(of: .day, in: .year, for: now) ?? 1)

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

        let startOfDay = cal.startOfDay(for: now)
        let morning = startOfDay.addingTimeInterval(morningMin * 60)
        let afternoon = startOfDay.addingTimeInterval(afternoonMin * 60)

        // If both times have already passed today, they'll just be in the past —
        // the scheduler won't fire them. Next day's compute() will be fresh.
        return DaylightWindows(morningNudge: morning, afternoonNudge: afternoon)
    }

    private func deg2rad(_ d: Double) -> Double { d * .pi / 180 }
    private func rad2deg(_ r: Double) -> Double { r * 180 / .pi }
}
