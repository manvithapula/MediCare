import UIKit
import PDFKit

class PDFGenerator {
    static func generatePDF(from history: [TakenMedication], dateRange: ClosedRange<Date>) -> Data? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        
        let pdfMetaData = [
            kCGPDFContextCreator: "Medication Tracker",
            kCGPDFContextAuthor: "User",
            kCGPDFContextTitle: "Medication History"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight), format: format)
        let data = renderer.pdfData { context in
            context.beginPage()
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            
          
            let startDate = Calendar.current.startOfDay(for: dateRange.lowerBound)
            let endDate = Calendar.current.startOfDay(for: dateRange.upperBound)
            let title = "Medication History"
            let dateRangeText: String
            
            if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
           
                dateRangeText = dateFormatter.string(from: startDate)
            } else {
               
                dateRangeText = "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
            }
            
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 24)
            ]
            let dateAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.gray
            ]
            
            title.draw(at: CGPoint(x: margin, y: margin), withAttributes: titleAttributes)
            dateRangeText.draw(at: CGPoint(x: margin, y: margin + 30), withAttributes: dateAttributes)
            let calendar = Calendar.current
            var medicationsByDate: [Date: [TakenMedication]] = [:]
            
            for medication in history {
                let date = calendar.startOfDay(for: medication.timeTaken)
                if date >= startDate && date <= endDate {
                    medicationsByDate[date, default: []].append(medication)
                }
            }
            let sortedDates = medicationsByDate.keys.sorted()
            
            var yPosition: CGFloat = margin + 80
            
            if medicationsByDate.isEmpty {
                let noDataText = "No medications taken during this period."
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14),
                    .foregroundColor: UIColor.gray
                ]
                noDataText.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: attributes)
            } else {
                for date in sortedDates {
                  
                    if yPosition > pageHeight - 100 {
                        context.beginPage()
                        yPosition = margin
                    }
                    
                    let dateString = dateFormatter.string(from: date)
                    let dateHeaderAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.boldSystemFont(ofSize: 18)
                    ]
                    dateString.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: dateHeaderAttributes)
                    yPosition += 30
                    
                    if let medications = medicationsByDate[date]?.sorted(by: { $0.timeTaken < $1.timeTaken }) {
                        for medication in medications {
                          
                            let nameAttributes: [NSAttributedString.Key: Any] = [
                                .font: UIFont.boldSystemFont(ofSize: 16)
                            ]
                            medication.name.draw(at: CGPoint(x: margin + 20, y: yPosition), withAttributes: nameAttributes)
                            
                            let timeFormatter = DateFormatter()
                            timeFormatter.timeStyle = .short
                            let timeAttributes: [NSAttributedString.Key: Any] = [
                                .font: UIFont.systemFont(ofSize: 14),
                                .foregroundColor: UIColor.gray
                            ]
                            let timeString = timeFormatter.string(from: medication.timeTaken)
                            timeString.draw(at: CGPoint(x: margin + 20, y: yPosition + 20), withAttributes: timeAttributes)
                            if let imageData = medication.imageData,
                               let image = UIImage(data: imageData) {
                                let imageSize: CGFloat = 40
                                let imageRect = CGRect(x: pageWidth - margin - imageSize, y: yPosition,
                                                     width: imageSize, height: imageSize)
                                image.draw(in: imageRect)
                            }
                            
                            yPosition += 50
                            
                            let path = UIBezierPath()
                            path.move(to: CGPoint(x: margin, y: yPosition - 10))
                            path.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition - 10))
                            UIColor.gray.withAlphaComponent(0.3).setStroke()
                            path.stroke()
                        }
                    }
                    
                    yPosition += 20
                }
            }
        }
        
        return data
    }
}
