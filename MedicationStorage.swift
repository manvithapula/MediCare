//
//  MedicationStorage.swift
//  MyApp
//
//  Created by admin64 on 21/02/25.
//


import Foundation

class MedicationStorage {
    @MainActor static let shared = MedicationStorage()
    private let key = "savedMedications"
    
    func saveMedications(_ medications: [Medication]) {
        if let encoded = try? JSONEncoder().encode(medications) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    func loadMedications() -> [Medication] {
        if let data = UserDefaults.standard.data(forKey: key),
           let medications = try? JSONDecoder().decode([Medication].self, from: data) {
            return medications
        }
        return []
    }
}
