//
//  NotificationManager.swift
//  MyApp
//
//  Created by admin64 on 22/02/25.
//


import Foundation
import UserNotifications

class NotificationManager {
    @MainActor static let shared = NotificationManager()
    
    private init() {}
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("Error requesting authorization for notifications: \(error.localizedDescription)")
            return false
        }
    }
    
    func scheduleNotification(for medication: Medication) async -> Bool {
        let content = UNMutableNotificationContent()
        content.title = "Medicine Reminder"
        content.body = "Time to take \(medication.name)"
        content.sound = .default
        content.badge = 1
        
        // Extract hour and minute components
        let components = Calendar.current.dateComponents([.hour, .minute], from: medication.timeToTake)
        
        // Create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // Create request with unique identifier
        let identifier = "MEDICATION_\(medication.id.uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            return true
        } catch {
            print("Error scheduling notification: \(error.localizedDescription)")
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
}
