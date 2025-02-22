import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var medications: [Medication] = MedicationStorage.shared.loadMedications()
    @State private var showingAddSheet = false
    @State private var medicationToDelete: Medication?
    @State private var showingDeleteAlert = false
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    var sortedMedications: [Medication] {
        medications.sorted {
            if $0.startDate == $1.startDate {
                return $0.timeToTake < $1.timeToTake
            }
            return $0.startDate < $1.startDate
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if medications.isEmpty {
                    EmptyStateView()
                } else {
                    List {
                        ForEach(sortedMedications.indices, id: \ .self) { index in
                            MedicationRow(medication: $medications[index])
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        medicationToDelete = medications[index]
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("My Medicines")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Label("Add Medicine", systemImage: "plus.circle.fill")
                            .foregroundColor(.blue)
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
            .onAppear {
                Task {
                    let granted = await NotificationManager.shared.requestAuthorization()
                    if granted {
                        await NotificationManager.shared.rescheduleMissedNotifications(for: medications)
                    }
                }
            }
        }
    }
    
    private func speakReminder(for medication: Medication) {
        let utterance = AVSpeechUtterance(string: "It's time to take \(medication.name).")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "pills.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("No Medicines Added")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Tap the + button to add your first medicine.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medication Row
struct MedicationRow: View {
    @Binding var medication: Medication
    @State private var showDetail = false
    
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
                    .foregroundColor(.blue.opacity(0.8))
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(medication.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(medication.startDate, style: .date) - \(medication.endDate, style: .date)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
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
                        .lineLimit(1)
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

