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
    
    // For time formatting
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timeToTake)
    }
}