//
//  AddMedicationView.swift
//  MyApp
//
//  Created by admin64 on 21/02/25.
//


import SwiftUI

struct AddMedicationView: View {
    @Binding var medications: [Medication]
    @Environment(\.dismiss) var dismiss
    
    @State private var medicineName = ""
    @State private var medicineTime = Date()
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Medicine Name", text: $medicineName)
                    .font(.title3)
                
                DatePicker("Time to Take",
                          selection: $medicineTime,
                          displayedComponents: .hourAndMinute)
                    .font(.title3)
                
                Button(action: saveMedication) {
                    Text("Save Medicine")
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets())
            }
            .navigationTitle("Add New Medicine")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
    
    private func saveMedication() {
        let medication = Medication(name: medicineName, timeToTake: medicineTime)
        medications.append(medication)
        MedicationStorage.shared.saveMedications(medications)
        dismiss()
    }
}