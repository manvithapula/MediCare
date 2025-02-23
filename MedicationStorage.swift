//
//  MedicationStorage.swift
//  MyApp
//
//  Created by admin64 on 21/02/25.
//

import Foundation

actor MedicationStorage {
    static let shared = MedicationStorage() 

    private let medicationKey = "savedMedications"
    private let historyKey = "medicationHistory"

    // MARK: - Save Medications
    func saveMedications(_ medications: [Medication]) async {
        do {
            let encoded = try JSONEncoder().encode(medications)
            UserDefaults.standard.set(encoded, forKey: medicationKey)
        } catch {
            print("Failed to save medications: \(error)")
        }
    }

    // MARK: - Load Medications
    func loadMedications() async -> [Medication] {
        guard let data = UserDefaults.standard.data(forKey: medicationKey) else { return [] }
        do {
            return try JSONDecoder().decode([Medication].self, from: data)
        } catch {
            print("Failed to load medications: \(error)")
            return []
        }
    }

    // MARK: - Save Medication History
    func saveMedicationHistory(_ medication: Medication, takenDate: Date) async {
        var history = await loadMedicationHistory()
        let takenMedication = TakenMedication(
            id: medication.id,
            name: medication.name,
            timeTaken: takenDate,
            imageData: medication.imageData
        )
        history.append(takenMedication)

        do {
            let encoded = try JSONEncoder().encode(history)
            UserDefaults.standard.set(encoded, forKey: historyKey)
        } catch {
            print("Failed to save medication history: \(error)")
        }
    }

    // MARK: - Load Medication History
    func loadMedicationHistory() async -> [TakenMedication] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return [] }
        do {
            return try JSONDecoder().decode([TakenMedication].self, from: data)
        } catch {
            print("Failed to load medication history: \(error)")
            return []
        }
    }
}
