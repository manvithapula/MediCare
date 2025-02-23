

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

// Data Model for History
struct TakenMedication: Identifiable, Codable {
    let id: UUID
    let name: String
    let timeTaken: Date
    let imageData: Data?
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: timeTaken)
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timeTaken)
    }
}
