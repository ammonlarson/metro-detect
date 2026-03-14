import UserNotifications
import Combine

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
            Task { @MainActor in
                if let error {
                    print("Notification authorization error: \(error.localizedDescription)")
                }
                self?.authorizationStatus = granted ? .authorized : .denied
            }
        }
    }

    func sendMetroDetected(line: String, fromStation: String) {
        let content = UNMutableNotificationContent()
        content.title = "Metro Detected"
        content.body = "You're on the \(line) from \(fromStation)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "metro-detected-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func sendNearStation(stationName: String, lines: [String]) {
        let lineList = lines.joined(separator: ", ")
        let content = UNMutableNotificationContent()
        content.title = "Near Metro Station"
        content.body = "You're near \(stationName) (\(lineList))"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "near-station-\(stationName)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func sendMovementDetected(speedKMH: Double, fromStation: String?) {
        let content = UNMutableNotificationContent()
        content.title = "Metro Speed Detected"
        if let station = fromStation {
            content.body = String(format: "Moving at %.0f km/h from %@", speedKMH, station)
        } else {
            content.body = String(format: "Moving at %.0f km/h in metro speed range", speedKMH)
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "movement-detected-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
