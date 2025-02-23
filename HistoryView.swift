import SwiftUI

struct HistoryView: View {
    @State private var medicationHistory: [TakenMedication] = []
    @State private var selectedDate = Date()
    
    var filteredHistory: [TakenMedication] {
        let calendar = Calendar.current
        return medicationHistory.filter { calendar.isDate($0.timeTaken, inSameDayAs: selectedDate) }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .padding()
                
                List {
                    if filteredHistory.isEmpty {
                        Text("No medications taken on this date.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(filteredHistory) { medication in
                            HistoryRow(medication: medication)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Medication History")
            .task { await loadMedicationHistory() } // Load history on appearance
        }
    }
    
    @MainActor
    private func loadMedicationHistory() async {
        medicationHistory = await MedicationStorage.shared.loadMedicationHistory()
    }
}

struct HistoryRow: View {
    let medication: TakenMedication
    
    var body: some View {
        HStack(spacing: 15) {
            if let imageData = medication.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Image(systemName: "pills.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(medication.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text(medication.formattedTime)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

