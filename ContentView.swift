import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var medications: [Medication] = []
    @State private var showingAddSheet = false
    @State private var medicationToDelete: Medication?
    @State private var showingDeleteAlert = false
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    @MainActor
       func loadMedications() {
           Task {
               self.medications = await MedicationStorage.shared.loadMedications()
           }
       }

    
    private let timePeriods = [
        ("Morning", 5..<12, "sun.rise.fill"),
        ("Afternoon", 12..<17, "sun.max.fill"),
        ("Evening", 17..<22, "sun.set.fill"),
        ("Night", 22..<24, "moon.stars.fill")
    ]
    
    var upcomingMedications: [Medication] {
            let now = Date()
            let calendar = Calendar.current
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))!

            return medications.filter { medication in
                let medicationDate = calendar.startOfDay(for: medication.timeToTake)
                
                // Only include medications from tomorrow onwards
                return medicationDate >= tomorrow
            }.sorted { $0.timeToTake < $1.timeToTake }
        }

    var todayMedications: [Medication] {
           let now = Date()
           let calendar = Calendar.current
           let today = calendar.startOfDay(for: now)
           
           return medications.filter { medication in
               // Check if the medication is scheduled for today
               let medicationDate = calendar.startOfDay(for: medication.timeToTake)
               return medicationDate == today
           }.sorted { $0.timeToTake < $1.timeToTake }
       }

    var body: some View {
        NavigationStack {
            List {
                if todayMedications.isEmpty && upcomingMedications.isEmpty {
                    EmptyStateView()
                        .listRowBackground(Color.clear)
                } else {
                    if !todayMedications.isEmpty {
                        Section(header: Text("Today")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)) {
                            
                            ForEach(timePeriods, id: \ .0) { period, range, icon in
                                let periodMeds = medicationsForPeriod(range, in: todayMedications)
                                if !periodMeds.isEmpty {
                                    Section(header: Label(period, systemImage: icon)
                                        .foregroundColor(.blue)) {
                                        ForEach(periodMeds) { medication in
                                            MedicationRow(medication: binding(for: medication))
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    if !upcomingMedications.isEmpty {
                        Section(header: Text("Upcoming")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)) {
                            
                            ForEach(upcomingMedications) { medication in
                                MedicationRow(medication: binding(for: medication))
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("My Medicines")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Label("Add Medicine", systemImage: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .tint(.blue)
        .sheet(isPresented: $showingAddSheet) {
            AddMedicationView(medications: $medications)
        }
        .alert("Delete Medicine?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteMedication()
            }
        } message: {
            if let medication = medicationToDelete {
                Text("Are you sure you want to delete \(medication.name)?")
            }
        }
    }

    private func medicationsForPeriod(_ range: Range<Int>, in medications: [Medication]) -> [Medication] {
        medications.filter { medication in
            let hour = Calendar.current.component(.hour, from: medication.timeToTake)
            return range.contains(hour) || (range.lowerBound == 22 && hour < 5)
        }.sorted { $0.timeToTake < $1.timeToTake }
    }

    private func binding(for medication: Medication) -> Binding<Medication> {
        guard let index = medications.firstIndex(where: { $0.id == medication.id }) else {
            fatalError("Medication not found")
        }
        return $medications[index]
    }
    
    private func speakReminder(for medication: Medication) {
        let utterance = AVSpeechUtterance(string: "Reminder! It's time to take \(medication.name).")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }
    @MainActor
    private func deleteMedication() {
        guard let medicationToDelete = medicationToDelete,
              let index = medications.firstIndex(where: { $0.id == medicationToDelete.id }) else {
            return
        }
        
        Task {
            await NotificationManager.shared.cancelNotification(for: medicationToDelete)
            withAnimation {
                medications.remove(at: index)
            }
            await MedicationStorage.shared.saveMedications(medications)
        }
    }

}

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
        .padding()
    }
}

struct MedicationRow: View {
    @Binding var medication: Medication
    @State private var showDetail = false
    
    var body: some View {
        HStack(spacing: 15) {
            if let imageData = medication.imageData,
               let uiImage = UIImage(data: imageData) {
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
                    .foregroundColor(medication.taken ? .secondary : .primary)
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text(medication.formattedTime)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                
                if !medication.instructions.isEmpty {
                    Text(medication.instructions)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Completion indicator
            if medication.taken {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 24))
                    .transition(.scale.combined(with: .opacity))
            }
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
