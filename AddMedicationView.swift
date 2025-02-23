import SwiftUI
import PhotosUI

struct AddMedicationView: View {
    @Binding var medications: [Medication]
    @Environment(\.dismiss) var dismiss
    @State private var medicineName = ""
    @State private var medicineTime = Date()
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var instructions = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var frequency: Frequency = .justOnce
    @State private var showAlert = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Medicine Details").font(.headline)) {
                    TextField("Medicine Name", text: $medicineName)
                        .font(.title2)
                        .padding()
                        .cornerRadius(8)
                }
                
                Section(header: Text("Medication Schedule").font(.headline)) {
                    DatePicker("Start Date", selection: $startDate, in: Date()..., displayedComponents: .date)
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                    DatePicker("Time to Take", selection: $medicineTime, displayedComponents: .hourAndMinute)
                }

                Section(header: Text("Frequency").font(.headline)) {
                    Picker("How Often?", selection: $frequency) {
                        ForEach(Frequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(header: Text("Instructions").font(.headline)) {
                    TextEditor(text: $instructions)
                        .frame(height: 100)
                        .font(.body)
                }

                Section(header: Text("Medicine Image").font(.headline)) {
                    if let image = selectedImage {
                        VStack {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                                .cornerRadius(8)
                            
                            Button("Remove Photo") {
                                selectedImage = nil
                            }
                            .foregroundColor(.red)
                        }
                    }

                    HStack {
                        Button("Choose Photo") {
                            sourceType = .photoLibrary
                            showImagePicker = true
                        }
                        Spacer()
                        Button("Take Photo") {
                            sourceType = .camera
                            showImagePicker = true
                        }
                    }
                }

                Button(action: saveMedication) {
                    Text("Save Medicine")
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets())
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Error"), message: Text("Medicine name cannot be empty"), dismissButton: .default(Text("OK")))
                }
            }
            .navigationTitle("Add New Medicine")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: sourceType)
            }
        }
    }

    private func saveMedication() {
        guard !medicineName.isEmpty else {
            showAlert = true
            return
        }
        let imageData = selectedImage?.jpegData(compressionQuality: 0.8)
        let medication = Medication(
            name: medicineName,
            timeToTake: medicineTime,
            instructions: instructions,
            imageData: imageData,
            startDate: startDate,
            endDate: endDate,
            frequency: frequency
        )
        medications.append(medication)
        Task {
            await MedicationStorage.shared.saveMedications(medications)

            let granted = await NotificationManager.shared.requestAuthorization()
            if granted {
                let scheduled = await NotificationManager.shared.scheduleNotification(for: medication)
                if !scheduled {
                    print("Failed to schedule notification")
                }
            }
        }

        dismiss()
    }
}

// adding medicine photo
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }
    }
}

