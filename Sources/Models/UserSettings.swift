import Foundation
import SwiftData

// Slouch sensitivity = the forward angle (deg below baseline) that triggers Drift.
enum Sensitivity: String, CaseIterable, Identifiable {
    case relaxed, balanced, strict
    var id: String { rawValue }

    var degrees: Double {
        switch self {
        case .relaxed:  return 22
        case .balanced: return 15
        case .strict:   return 8
        }
    }
    var label: String {
        switch self {
        case .relaxed:  return "Relaxed"
        case .balanced: return "Balanced"
        case .strict:   return "Strict"
        }
    }
}

@Model
final class UserSettings {
    // Inline defaults below let SwiftData lightweight-migrate existing stores
    // (new non-optional attributes need a store-level default).

    // Onboarding gate + calibrated baseline (radians-derived degrees).
    var hasOnboarded: Bool = false
    var baselinePitch: Double?

    // Posture behaviour.
    var sensitivityRaw: String = Sensitivity.balanced.rawValue
    var escalateLongSlouches: Bool = true
    var sunlightEnabled: Bool = true

    // Soft alerts master switch (menu-bar popover Gentle/Off segmented).
    var softAlertsEnabled: Bool = true

    // Level-2 soft alert: quiet chime after sustained forward lean.
    var chimeOnSustainedDrift: Bool = true
    var nudgeAfterDriftSeconds: Double = 3.0
    var chimeVolume: Double = 0.5
    // Legacy persisted field. Keep for store compatibility; new behavior uses
    // nudgeAfterDriftSeconds.
    var nudgeAfterDriftMin: Double = 2.0

    // Quiet hours (minutes of day, local): notifications + chime hold off.
    var quietHoursEnabled: Bool = true
    var quietHoursStartMinutes: Int = 1320  // 22:00
    var quietHoursEndMinutes: Int = 480     // 08:00

    // Secondary habit intervals (water / walk nudges).
    var baseWaterIntervalMin: Double = 30.0
    var baseWalkIntervalMin: Double = 45.0
    var dailyWaterTargetMl: Double = 2000.0  // 2.0L default
    var dailyStepTarget: Int = 8000

    // Mascot selection.
    var selectedPlantRaw: String = PlantKind.sunflower.rawValue

    init() {
        hasOnboarded = false
        baselinePitch = nil
        sensitivityRaw = Sensitivity.balanced.rawValue
        escalateLongSlouches = true
        sunlightEnabled = true
        softAlertsEnabled = true
        chimeOnSustainedDrift = true
        nudgeAfterDriftSeconds = 3.0
        chimeVolume = 0.5
        nudgeAfterDriftMin = 2.0
        quietHoursEnabled = true
        quietHoursStartMinutes = 1320
        quietHoursEndMinutes = 480
        baseWaterIntervalMin = 30.0
        baseWalkIntervalMin = 45.0
        dailyWaterTargetMl = 2000.0
        dailyStepTarget = 8000
        selectedPlantRaw = PlantKind.sunflower.rawValue
    }

    var sensitivity: Sensitivity {
        get { Sensitivity(rawValue: sensitivityRaw) ?? .balanced }
        set { sensitivityRaw = newValue.rawValue }
    }
    var selectedPlant: PlantKind {
        get { PlantKind(rawValue: selectedPlantRaw) ?? .sunflower }
        set { selectedPlantRaw = newValue.rawValue }
    }

    func reset() {
        sensitivity = .balanced
        escalateLongSlouches = true
        sunlightEnabled = true
        softAlertsEnabled = true
        chimeOnSustainedDrift = true
        nudgeAfterDriftSeconds = 3.0
        chimeVolume = 0.5
        nudgeAfterDriftMin = 2.0
        quietHoursEnabled = true
        quietHoursStartMinutes = 1320
        quietHoursEndMinutes = 480
        baseWaterIntervalMin = 30.0
        baseWalkIntervalMin = 45.0
        dailyWaterTargetMl = 2000.0
        dailyStepTarget = 8000
        selectedPlant = .sunflower
    }
}
