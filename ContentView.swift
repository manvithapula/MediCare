import SwiftUI

struct ContentView: View {
    @State private var medications: [Medication] = MedicationStorage.shared.loadMedications()
    @State private var showingAddSheet = false
    @State private var medicationToDelete: Medication?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            if medications.isEmpty {
                EmptyStateView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: { showingAddSheet = true }) {
                                Label("Add Medicine", systemImage: "plus.circle.fill")
                            }
                        }
                    }
            } else {
                List {
                    ForEach($medications.indices, id: \.self) { index in
                        MedicationRow(medication: $medications[index])
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    medicationToDelete = medications[index]
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .onTapGesture {
                                medications[index].taken.toggle()
                                if medications[index].taken {
                                    medications[index].lastSevenDays[0] = true
                                }
                                MedicationStorage.shared.saveMedications(medications)
                            }
                    }
                }
                .navigationTitle("My Medicines")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingAddSheet = true }) {
                            Label("Add Medicine", systemImage: "plus.circle.fill")
                        }
                    }
                }
            }
        }
        .alert("Delete Medicine?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let medicationToDelete = medicationToDelete,
                   let index = medications.firstIndex(where: { $0.id == medicationToDelete.id }) {
                    DispatchQueue.main.async {
                        NotificationManager.shared.cancelNotification(for: medicationToDelete)
                    }
                    
                    withAnimation {
                        medications.remove(at: index)
                        MedicationStorage.shared.saveMedications(medications)
                    }
                }
            }
        } message: {
            if let medication = medicationToDelete {
                Text("Are you sure you want to delete \(medication.name)?")
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddMedicationView(medications: $medications)
        }
    }
}

// no medications are added
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "pills.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("No Medicines Added")
                .font(.title2)
                .foregroundColor(.primary)
            
            Text("Tap the + button to add your first medicine")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .navigationTitle("My Medicines")
    }
}

// Medication row with image
struct MedicationRow: View {
    @State private var showDetail = false
    @Binding var medication: Medication
    
    var body: some View {
        HStack {
            if let imageData = medication.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(medication.name)
                    .font(.title3)
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text(medication.formattedTime)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if !medication.instructions.isEmpty {
                    Text(medication.instructions)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Circle()
                .fill(medication.taken ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 20, height: 20)
                .overlay(
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .opacity(medication.taken ? 1 : 0)
                )
        }
        .padding(.vertical, 8)
        .onTapGesture {
            showDetail = true
        }
        .sheet(isPresented: $showDetail) {
            MedicationDetailView(medication: $medication)
        }
    }
}
