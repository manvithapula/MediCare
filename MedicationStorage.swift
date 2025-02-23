import Foundation
//storing all data
actor MedicationStorage {
    static let shared = MedicationStorage()
    private let medicationKey = "savedMedications"
    private let historyKey = "medicationHistory"
    func saveMedications(_ medications: [Medication]) async { // saving for medication tab
        do {
            let encoded = try JSONEncoder().encode(medications)
            UserDefaults.standard.set(encoded, forKey: medicationKey)
        } catch {
            print("Failed to save medications: \(error)")
        }
    }
    func loadMedications() async -> [Medication] {   // loading for medication tab
        guard let data = UserDefaults.standard.data(forKey: medicationKey) else { return [] }
        do {
            return try JSONDecoder().decode([Medication].self, from: data)
        } catch {
            print("Failed to load medications: \(error)")
            return []
        }
    }

    func saveMedicationHistory(_ medication: Medication, takenDate: Date) async {  // saving for history tab
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
    func loadMedicationHistory() async -> [TakenMedication] {   // loading for history tab
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return [] }
        do {
            return try JSONDecoder().decode([TakenMedication].self, from: data)
        } catch {
            print("Failed to load medication history: \(error)")
            return []
        }
    }
}
