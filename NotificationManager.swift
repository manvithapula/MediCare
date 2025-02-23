import Foundation
import UserNotifications
import AVFoundation

//audio based notification
class NotificationManager {
    @MainActor static let shared = NotificationManager()
    private let synthesizer = AVSpeechSynthesizer()

    private init() {}

//permission
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("Error requesting notification authorization: \(error.localizedDescription)")
            return false
        }
    }

    
    func scheduleNotification(for medication: Medication) async -> Bool {
        let content = UNMutableNotificationContent()
        content.title = "Medicine Reminder"
        content.body = "Time to take \(medication.name)"
        content.sound = .default
        content.badge = NSNumber(value: 1)
        let components = Calendar.current.dateComponents([.hour, .minute], from: medication.timeToTake)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let identifier = "MEDICATION_\(medication.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            print("Scheduled notification for \(medication.name)")

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                NotificationManager.shared.speakReminder(for: medication)
            }


            return true
        } catch {
            print(" Error scheduling notification: \(error.localizedDescription)")
            return false
        }
    }

    func cancelNotification(for medication: Medication) {
        let identifier = "MEDICATION_\(medication.id.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Canceled notification for \(medication.name)")
    }
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("All notifications canceled")
    }
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
    func checkNotificationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    func rescheduleMissedNotifications(for medications: [Medication]) async {
        let pendingRequests = await getPendingNotifications()
        let pendingIDs = pendingRequests.map { $0.identifier }

        for medication in medications {
            let identifier = "MEDICATION_\(medication.id.uuidString)"
            if !pendingIDs.contains(identifier) {
                print("Rescheduling missed notification for \(medication.name)")
                _ = await scheduleNotification(for: medication)
            }
        }
    }
    private func speakReminder(for medication: Medication) {
        let utterance = AVSpeechUtterance(string: "It's time to take \(medication.name). \(medication.instructions)")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }
}
