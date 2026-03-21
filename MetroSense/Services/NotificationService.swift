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
}
