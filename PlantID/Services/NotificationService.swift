import UserNotifications
import Foundation

enum NotificationService {
    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    static func scheduleWateringReminder(plant: Plant, daysSince: Int) {
        let content = UNMutableNotificationContent()
        content.title = "\(plant.name) needs watering"
        let overdueDays = daysSince - plant.wateringIntervalDays
        content.body = overdueDays >= 0
            ? "Overdue by \(overdueDays + 1) day\(overdueDays == 0 ? "" : "s")"
            : "Due today"
        content.sound = .default
        content.userInfo = ["plantId": plant.id.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "watering-\(plant.id.uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    static func scheduleDailyReminder() {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Plant care reminder"
        content.body = "Check if any of your plants need watering today"
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: "daily-watering-check",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelAllPending() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
