import HealthKit
import Foundation
import Observation

// Reads today's step count from HealthKit. On Simulator, HKHealthStore.isHealthDataAvailable
// returns true but queries return no data — walk chip falls back to interval mode.
@Observable
final class StepReader {
    private(set) var todaySteps: Int = 0

    private let store: HKHealthStore?

    init() {
        store = HKHealthStore.isHealthDataAvailable() ? HKHealthStore() : nil
    }

    var isAvailable: Bool { store != nil }

    func requestPermission() async {
        guard let store else { return }
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: [stepType])
        } catch {
            // ponytail: permission denied — walk chip stays in interval fallback
        }
    }

    func refresh() {
        guard let store, let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            todaySteps = 0
            return
        }
        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: .now, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, stats, _ in
            let total = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            DispatchQueue.main.async { self?.todaySteps = Int(total) }
        }
        store.execute(query)
    }
}
