//
//  NotificationManager.swift
//  MyApp
//
//  Created by admin64 on 22/02/25.
//

import Foundation
import UserNotifications
import AVFoundation

class NotificationManager {
    @MainActor static let shared = NotificationManager()
    private let synthesizer = AVSpeechSynthesizer()

    private init() {}

    /// Requests notification permission from the user
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("Error requesting notification authorization: \(error.localizedDescription)")
            return false
        }
    }

    /// Schedules a notification for a specific medication
    func scheduleNotification(for medication: Medication) async -> Bool {
        let content = UNMutableNotificationContent()
        content.title = "Medicine Reminder"
        content.body = "Time to take \(medication.name)"
        content.sound = .default
        content.badge = NSNumber(value: 1)

        // Extract hour and minute components
        let components = Calendar.current.dateComponents([.hour, .minute], from: medication.timeToTake)

        // Create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        // Unique identifier for notification
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

    /// Cancels a specific medication reminder
    func cancelNotification(for medication: Medication) {
        let identifier = "MEDICATION_\(medication.id.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        print("Canceled notification for \(medication.name)")
    }

    /// Cancels all scheduled notifications
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("All notifications canceled")
    }

    /// Retrieves all pending notifications
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }

    /// Checks the current notification authorization status
    func checkNotificationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    /// Reschedules missed notifications (if any)
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

    /// Speaks the reminder using Text-to-Speech
    private func speakReminder(for medication: Medication) {
        let utterance = AVSpeechUtterance(string: "It's time to take \(medication.name). \(medication.instructions)")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5 // Adjust speed if needed
        synthesizer.speak(utterance)
    }
}
