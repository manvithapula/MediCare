

import Foundation
struct Medication: Identifiable, Codable {
    var id = UUID()
    var name: String
    var timeToTake: Date
    var taken: Bool = false
    var instructions: String = ""
    var imageData: Data?
    var startDate: Date
    var endDate: Date
    var frequency: Frequency
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timeToTake)
    }
}
enum Frequency: String, CaseIterable, Codable {
    case daily = "Daily"
    case alternateDays = "Alternate"
    case weekly = "Weekly"
    case justOnce = "Just Once"
}

// Medication history
struct MedicationHistory: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var medications: [Medication]
}
