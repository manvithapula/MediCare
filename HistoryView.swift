import SwiftUI

struct HistoryView: View {
    @State private var medicationHistory: [TakenMedication] = []
    @State private var selectedDate = Date()
    
    //pdf export
    @State private var showingShareSheet = false
    @State private var pdfData: Data?
    @State private var isShowingDatePicker = false
    @State private var dateRange: ClosedRange<Date> = Date()...Date()
    
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
               .toolbar {
                   Button(action: { isShowingDatePicker = true }) {
                       Image(systemName: "square.and.arrow.up")
                   }
               }
               .sheet(isPresented: $isShowingDatePicker) {
                   NavigationStack {
                       DateRangePickerView(
                           dateRange: $dateRange,
                           isPresented: $isShowingDatePicker,
                           onExport: exportToPDF
                       )
                   }
               }
               .sheet(isPresented: $showingShareSheet) {
                   if let data = pdfData {
                       ShareSheet(items: [data])
                   }
               }
               .task { await loadMedicationHistory() }
           }
       }
       
       private func exportToPDF() {
           let filteredHistory = medicationHistory.filter { medication in
               dateRange.contains(medication.timeTaken)
           }
           
           if let pdfData = PDFGenerator.generatePDF(from: filteredHistory, dateRange: dateRange) {
               self.pdfData = pdfData
               self.showingShareSheet = true
           }
       }
       
       @MainActor
       private func loadMedicationHistory() async {
           medicationHistory = await MedicationStorage.shared.loadMedicationHistory()
       }
   }

   // New DateRangePickerView
   struct DateRangePickerView: View {
       @Binding var dateRange: ClosedRange<Date>
       @Binding var isPresented: Bool
       let onExport: () -> Void
       
       @State private var startDate = Date()
       @State private var endDate = Date()
       
       var body: some View {
           List {
               Section("Select Date Range") {
                   DatePicker("Start Date",
                             selection: $startDate,
                             displayedComponents: .date)
                   
                   DatePicker("End Date",
                             selection: $endDate,
                             displayedComponents: .date)
               }
           }
           .navigationTitle("Export History")
           .navigationBarTitleDisplayMode(.inline)
           .toolbar {
               ToolbarItem(placement: .cancellationAction) {
                   Button("Cancel") {
                       isPresented = false
                   }
               }
               ToolbarItem(placement: .confirmationAction) {
                   Button("Export") {
                       dateRange = startDate...endDate
                       isPresented = false
                       onExport()
                   }
               }
           }
       }
   }

   struct ShareSheet: UIViewControllerRepresentable {
       let items: [Any]
       
       func makeUIViewController(context: Context) -> UIActivityViewController {
           let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
           return controller
       }
       
       func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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
