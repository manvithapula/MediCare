//
//  MedicationDetailView.swift
//  MyApp
//
//  Created by admin64 on 23/02/25.
//


import SwiftUI

struct MedicationDetailView: View {
    @Binding var medication: Medication
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            if let imageData = medication.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Text(medication.name)
                .font(.largeTitle)
                .bold()
            
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                Text(medication.formattedTime)
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            
            if !medication.instructions.isEmpty {
                Text(medication.instructions)
                    .font(.body)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
            }
            
            Button(action: {
                medication.taken.toggle()
                MedicationStorage.shared.saveMedications([medication]) 
                dismiss()
            }) {
                Text(medication.taken ? "Marked as Taken" : "Mark as Taken")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(medication.taken ? Color.green : Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .presentationDetents([.medium, .large])
    }
}
