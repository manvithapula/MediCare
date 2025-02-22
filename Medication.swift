//
//  Medication.swift
//  MyApp
//
//  Created by admin64 on 21/02/25.
//


import Foundation
struct Medication: Identifiable, Codable {
    var id = UUID()
    var name: String
    var timeToTake: Date
    var taken: Bool = false
    var instructions: String = ""    //for instructions
    var lastSevenDays: [Bool] = Array(repeating: false, count: 7)
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
    case alternateDays = "Alternate Days"
    case weekly = "Weekly"
}
