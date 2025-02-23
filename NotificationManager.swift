import Foundation
import UIKit
import UserNotifications
import AVFoundation

class NotificationManager {
    @MainActor static let shared = NotificationManager()

    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }

    func scheduleNotification(for medication: Medication) async -> Bool {
        let content = UNMutableNotificationContent()
        content.title = "Medicine Reminder"
        content.body = "Time to take \(medication.name)"
        content.sound = .default
        content.badge = NSNumber(value: 1)
        content.userInfo = ["medicationName": medication.name, "instructions": medication.instructions]

        let components = Calendar.current.dateComponents([.hour, .minute], from: medication.timeToTake)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let identifier = "MEDICATION_\(medication.id.uuidString)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
            return true
        } catch {
            return false
        }
    }

    func cancelNotification(for medication: Medication) {
        let identifier = "MEDICATION_\(medication.id.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
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
                _ = await scheduleNotification(for: medication)
            }
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate, @preconcurrency UNUserNotificationCenterDelegate {
    let synthesizer = AVSpeechSynthesizer() // Keep synthesizer alive

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        if let medicationName = notification.request.content.userInfo["medicationName"] as? String,
           let instructions = notification.request.content.userInfo["instructions"] as? String {
            
            DispatchQueue.main.async {
                self.speakReminder(medicationName: medicationName, instructions: instructions)
            }
        }
        
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if let medicationName = response.notification.request.content.userInfo["medicationName"] as? String,
           let instructions = response.notification.request.content.userInfo["instructions"] as? String {
            
            DispatchQueue.main.async {
                self.speakReminder(medicationName: medicationName, instructions: instructions)
            }
        }
        
        completionHandler()
    }

    func speakReminder(medicationName: String, instructions: String) {
        let utterance = AVSpeechUtterance(string: "It's time to take \(medicationName). \(instructions)")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        
        if !synthesizer.isSpeaking {
            synthesizer.speak(utterance)
        }
    }
}
