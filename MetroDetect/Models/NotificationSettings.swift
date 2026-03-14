import Foundation

struct NotificationSettings: Equatable {
    // MARK: - Proximity Notifications

    var proximityEnabled: Bool
    var proximityRadius: Double // meters
    var proximityStationFilter: StationFilter

    enum StationFilter: Equatable {
        case all
        case selected(Set<String>) // station names
    }

    // MARK: - Movement Notifications

    var movementEnabled: Bool
    var minimumSpeedMPS: Double
    var maximumSpeedMPS: Double
    var sustainedDurationSeconds: TimeInterval
    var requireStartAtStation: Bool

    // MARK: - Defaults

    static let `default` = NotificationSettings(
        proximityEnabled: true,
        proximityRadius: 150,
        proximityStationFilter: .all,
        movementEnabled: true,
        minimumSpeedMPS: 8.0,
        maximumSpeedMPS: 25.0,
        sustainedDurationSeconds: 0,
        requireStartAtStation: false
    )

    // MARK: - Validation

    var isValid: Bool {
        proximityRadius > 0
            && minimumSpeedMPS > 0
            && maximumSpeedMPS > 0
            && minimumSpeedMPS <= maximumSpeedMPS
            && sustainedDurationSeconds >= 0
            && {
                if case .selected(let stations) = proximityStationFilter {
                    return !stations.isEmpty
                }
                return true
            }()
    }
}

// MARK: - UserDefaults Persistence

extension NotificationSettings {
    private enum Keys {
        static let proximityEnabled = "ns_proximityEnabled"
        static let proximityRadius = "ns_proximityRadius"
        static let stationFilterAll = "ns_stationFilterAll"
        static let selectedStations = "ns_selectedStations"
        static let movementEnabled = "ns_movementEnabled"
        static let minimumSpeedMPS = "ns_minimumSpeedMPS"
        static let maximumSpeedMPS = "ns_maximumSpeedMPS"
        static let sustainedDuration = "ns_sustainedDuration"
        static let requireStartAtStation = "ns_requireStartAtStation"
        static let hasStoredSettings = "ns_hasStoredSettings"
    }

    func save(to defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: Keys.hasStoredSettings)
        defaults.set(proximityEnabled, forKey: Keys.proximityEnabled)
        defaults.set(proximityRadius, forKey: Keys.proximityRadius)

        switch proximityStationFilter {
        case .all:
            defaults.set(true, forKey: Keys.stationFilterAll)
            defaults.removeObject(forKey: Keys.selectedStations)
        case .selected(let stations):
            defaults.set(false, forKey: Keys.stationFilterAll)
            defaults.set(Array(stations), forKey: Keys.selectedStations)
        }

        defaults.set(movementEnabled, forKey: Keys.movementEnabled)
        defaults.set(minimumSpeedMPS, forKey: Keys.minimumSpeedMPS)
        defaults.set(maximumSpeedMPS, forKey: Keys.maximumSpeedMPS)
        defaults.set(sustainedDurationSeconds, forKey: Keys.sustainedDuration)
        defaults.set(requireStartAtStation, forKey: Keys.requireStartAtStation)
    }

    static func load(from defaults: UserDefaults = .standard) -> NotificationSettings {
        guard defaults.bool(forKey: Keys.hasStoredSettings) else {
            return .default
        }

        let stationFilter: StationFilter
        if defaults.bool(forKey: Keys.stationFilterAll) {
            stationFilter = .all
        } else {
            let names = defaults.stringArray(forKey: Keys.selectedStations) ?? []
            stationFilter = names.isEmpty ? .all : .selected(Set(names))
        }

        return NotificationSettings(
            proximityEnabled: defaults.bool(forKey: Keys.proximityEnabled),
            proximityRadius: defaults.double(forKey: Keys.proximityRadius),
            proximityStationFilter: stationFilter,
            movementEnabled: defaults.bool(forKey: Keys.movementEnabled),
            minimumSpeedMPS: defaults.double(forKey: Keys.minimumSpeedMPS),
            maximumSpeedMPS: defaults.double(forKey: Keys.maximumSpeedMPS),
            sustainedDurationSeconds: defaults.double(forKey: Keys.sustainedDuration),
            requireStartAtStation: defaults.bool(forKey: Keys.requireStartAtStation)
        )
    }
}
