import SwiftUI

struct MedicationDetailView: View {
    @Binding var medication: Medication
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Medication Image
                if let imageData = medication.imageData, let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 5)
                        .padding(.horizontal)
                }
                
                // Medication Information Card
                VStack(spacing: 20) {
                    // Medication Name
                    Text(medication.name)
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .padding(.top, 5)
                    
                    // Time Section
                    VStack(spacing: 8) {
                        Text("Time to Take")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                            Text(medication.formattedTime)
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(15)
                }
                .padding(.horizontal)
                
                // Instructions Section
                if !medication.instructions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instructions")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(medication.instructions)
                            .font(.system(size: 18))
                            .lineSpacing(4)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(15)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 30)
                
                // Action Button
                Button(action: {
                    medication.taken.toggle()
                    
                    Task {
                        await MedicationStorage.shared.saveMedications([medication])
                        
                        if medication.taken {
                            await MedicationStorage.shared.saveMedicationHistory(medication, takenDate: Date())
                        }
                    }
                    
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: medication.taken ? "checkmark.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 24))
                        Text(medication.taken ? "Marked as Taken" : "Mark as Taken")
                            .font(.system(size: 20, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(medication.taken ? Color.green : Color.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 3)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.top, 20)
        }
        .background(Color(.systemBackground))
    }
}
