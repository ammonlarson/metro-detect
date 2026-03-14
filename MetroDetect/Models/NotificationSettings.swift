import Foundation

struct NotificationSettings: Codable, Equatable {
    // MARK: - Proximity Notifications

    /// Whether to send a notification when near a metro station
    var notifyNearStation: Bool = true

    /// Which metro lines to notify about (empty means all)
    var notifyLines: Set<String> = []

    /// Radius in meters around a station to trigger the notification
    var proximityRadius: Double = 150

    // MARK: - Movement Notifications

    /// Whether to send a notification when moving at metro speed
    var notifyOnMovement: Bool = true

    /// Minimum speed (m/s) to consider as metro movement
    var movementMinSpeedMPS: Double = 8.0

    /// Maximum speed (m/s) to consider as metro movement
    var movementMaxSpeedMPS: Double = 25.0

    /// Duration in seconds that speed must be sustained before notifying
    var movementSustainedSeconds: Double = 10.0

    /// Only notify if movement started from a metro station
    var movementRequireStationOrigin: Bool = false

    // MARK: - Computed

    /// Returns true if all lines should be notified (empty set = all)
    var shouldNotifyAllLines: Bool {
        notifyLines.isEmpty
    }

    /// Check if a specific line should trigger a notification
    func shouldNotify(line: String) -> Bool {
        notifyLines.isEmpty || notifyLines.contains(line)
    }

    // MARK: - Convenience

    var movementMinSpeedKMH: Double {
        get { movementMinSpeedMPS * 3.6 }
        set { movementMinSpeedMPS = newValue / 3.6 }
    }

    var movementMaxSpeedKMH: Double {
        get { movementMaxSpeedMPS * 3.6 }
        set { movementMaxSpeedMPS = newValue / 3.6 }
    }
}

// MARK: - UserDefaults Persistence

extension NotificationSettings {
    private static let storageKey = "notificationSettings"

    static func load() -> NotificationSettings {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let settings = try? JSONDecoder().decode(NotificationSettings.self, from: data) else {
            return NotificationSettings()
        }
        return settings
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: NotificationSettings.storageKey)
        }
    }
}
