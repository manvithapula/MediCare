import SwiftUI

struct MedicationDetailView: View {
    @Binding var medication: Medication
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Medication Image
            if let imageData = medication.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding(.horizontal)
            }
            
            // Medication Name
            Text(medication.name)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                
            // Medication Time
            HStack(spacing: 10) {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                Text(medication.formattedTime)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 5)
            
            // Instructions
            if !medication.instructions.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Instructions")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(medication.instructions)
                        .font(.body)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            }
            
            // Mark as Taken Button
            Button(action: {
                medication.taken.toggle()
                MedicationStorage.shared.saveMedications([medication])
                dismiss()
            }) {
                HStack {
                    Image(systemName: medication.taken ? "checkmark.circle.fill" : "plus.circle.fill")
                        .foregroundColor(.white)
                    Text(medication.taken ? "Marked as Taken" : "Mark as Taken")
                        .bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(medication.taken ? Color.green : Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            Spacer()
        }
        .padding()
        .presentationDetents([.medium, .large])
    }
}
