import SwiftUI

struct MedicationDetailView: View {
    @Binding var medication: Medication
    @Environment(\.dismiss) var dismiss
    @State private var isEditing = false
    
    // Edit mode state
    @State private var editedName = ""
    @State private var editedTime = Date()
    @State private var editedStartDate = Date()
    @State private var editedEndDate = Date()
    @State private var editedInstructions = ""
    @State private var editedFrequency: Frequency = .justOnce
    @State private var editedImage: UIImage?
    
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                if !isEditing {
                    statusSection
                }
                
                imageSection
                
                if isEditing {
                    editDetailsSection
                } else {
                    displayDetailsSection
                }
            }
            .navigationTitle(isEditing ? "Edit Medicine" : "Medicine Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isEditing ? "Cancel" : "Done") {
                        isEditing ? cancelEdit() : dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Edit") {
                        isEditing ? saveChanges() : startEditing()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $editedImage, sourceType: sourceType)
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Medicine name cannot be empty")
            }
            .onAppear {
                initializeEditValues()
            }
        }
    }
    

    private var statusSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Status: ")
                    Text(medication.taken ? "Taken" : "Not Taken")
                        .foregroundColor(medication.taken ? .green : .red)
                        .fontWeight(.bold)
                    if medication.taken {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                Button {
                    Task {
                        medication.taken.toggle()
                        if medication.taken {
                            await MedicationStorage.shared.saveMedicationHistory(medication, takenDate: Date())
                        }
                        await MedicationStorage.shared.saveMedications([medication])
                    }
                } label: {
                    HStack {
                        Image(systemName: medication.taken ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill")
                        Text(medication.taken ? "Mark as Not Taken" : "Mark as Taken")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(medication.taken ? Color.red.opacity(0.8) : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private var imageSection: some View {
        Section {
            if isEditing {
                if let image = editedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                }
                
                HStack {
                    Button {
                        sourceType = .photoLibrary
                        showImagePicker = true
                    } label: {
                        Label("Choose Photo", systemImage: "photo")
                    }
                    
                    Spacer()
                    
                    Button {
                        sourceType = .camera
                        showImagePicker = true
                    } label: {
                        Label("Take Photo", systemImage: "camera")
                    }
                }
                
                if editedImage != nil {
                    Button(role: .destructive) {
                        editedImage = nil
                    } label: {
                        Label("Remove Photo", systemImage: "trash")
                    }
                }
            } else {
                if let imageData = medication.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                } else {
                    Image(systemName: "pills.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                }
            }
        }
    }
    
    private var displayDetailsSection: some View {
        Section {
            LabeledContent("Medicine Name", value: medication.name)
            LabeledContent("Time to Take", value: medication.formattedTime)
            LabeledContent("Start Date", value: formatDate(medication.startDate))
            LabeledContent("End Date", value: formatDate(medication.endDate))
            LabeledContent("Frequency", value: medication.frequency.rawValue)
            
            if !medication.instructions.isEmpty {
                LabeledContent("Instructions", value: medication.instructions)
            }
        }
    }
    
    private var editDetailsSection: some View {
        Section {
            TextField("Medicine Name", text: $editedName)
            DatePicker("Time to Take", selection: $editedTime, displayedComponents: .hourAndMinute)
            DatePicker("Start Date", selection: $editedStartDate, displayedComponents: .date)
            DatePicker("End Date", selection: $editedEndDate, in: editedStartDate..., displayedComponents: .date)
            
            Picker("Frequency", selection: $editedFrequency) {
                ForEach(Frequency.allCases, id: \.self) { freq in
                    Text(freq.rawValue).tag(freq)
                }
            }
            
            TextField("Instructions", text: $editedInstructions, axis: .vertical)
                .lineLimit(4, reservesSpace: true)
        }
    }
   
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func initializeEditValues() {
        editedName = medication.name
        editedTime = medication.timeToTake
        editedStartDate = medication.startDate
        editedEndDate = medication.endDate
        editedInstructions = medication.instructions
        editedFrequency = medication.frequency
        if let imageData = medication.imageData,
           let uiImage = UIImage(data: imageData) {
            editedImage = uiImage
        }
    }
    
    private func startEditing() {
        initializeEditValues()
        withAnimation {
            isEditing = true
        }
    }
    
    private func cancelEdit() {
        withAnimation {
            isEditing = false
        }
    }
    
    private func saveChanges() {
        guard !editedName.isEmpty else {
            showAlert = true
            return
        }
        
        Task {
            await NotificationManager.shared.cancelNotification(for: medication)
            
            medication.name = editedName
            medication.timeToTake = editedTime
            medication.startDate = editedStartDate
            medication.endDate = editedEndDate
            medication.instructions = editedInstructions
            medication.frequency = editedFrequency
            medication.imageData = editedImage?.jpegData(compressionQuality: 0.8)
            
            await MedicationStorage.shared.saveMedications([medication])
            
            if await NotificationManager.shared.requestAuthorization() {
                await NotificationManager.shared.scheduleNotification(for: medication)
            }
        }
        
        withAnimation {
            isEditing = false
        }
    }
}
