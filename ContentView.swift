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
                    ForEach(medications) { medication in
                        MedicationRow(medication: medication)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    medicationToDelete = medication
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
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
                    // Move the notification cancellation to the main thread
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

// Medication row for the list
struct MedicationRow: View {
    let medication: Medication
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(medication.name)
                    .font(.title3)
                    .foregroundColor(.primary)
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text(medication.formattedTime)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
