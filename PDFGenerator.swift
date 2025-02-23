import UIKit
import PDFKit

class PDFGenerator {
    static func generatePDF(from history: [TakenMedication], dateRange: ClosedRange<Date>) -> Data? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        
        let format = UIGraphicsPDFRendererFormat()
        let rect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        let renderer = UIGraphicsPDFRenderer(bounds: rect, format: format)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
            
            let title = "Medication History Report"
            let titleFont = UIFont.boldSystemFont(ofSize: 24)
            title.draw(at: CGPoint(x: margin, y: margin), withAttributes: [.font: titleFont])
            
            let calendar = Calendar.current
            let startDate = calendar.startOfDay(for: dateRange.lowerBound)
            let endDate = calendar.startOfDay(for: dateRange.upperBound)
            
            let dateRangeText = calendar.isDate(startDate, inSameDayAs: endDate)
                ? dateFormatter.string(from: startDate)
                : "\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))"
            
            let subtitleFont = UIFont.systemFont(ofSize: 16)
            dateRangeText.draw(at: CGPoint(x: margin, y: margin + 30), withAttributes: [.font: subtitleFont])
            
            var yPosition: CGFloat = margin + 70
            var medicationsByDate: [Date: [TakenMedication]] = [:]
            
            for medication in history {
                let date = calendar.startOfDay(for: medication.timeTaken)
                if date >= startDate && date <= endDate {
                    medicationsByDate[date, default: []].append(medication)
                }
            }
            
            let sortedDates = medicationsByDate.keys.sorted()
            
            for date in sortedDates {
                if yPosition > pageHeight - 100 {
                    context.beginPage()
                    yPosition = margin
                }
                
                let dateString = dateFormatter.string(from: date)
                let dateFont = UIFont.boldSystemFont(ofSize: 18)
                dateString.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: [.font: dateFont])
                yPosition += 30
                
                if let medications = medicationsByDate[date]?.sorted(by: { $0.timeTaken < $1.timeTaken }) {
                    for medication in medications {
                        if yPosition > pageHeight - 80 {
                            context.beginPage()
                            yPosition = margin
                        }
                        
                        let nameFont = UIFont.systemFont(ofSize: 16)
                        medication.name.draw(at: CGPoint(x: margin + 20, y: yPosition),
                                          withAttributes: [.font: nameFont])
                        
                        let timeString = dateFormatter.string(from: medication.timeTaken)
                        let timeFont = UIFont.systemFont(ofSize: 14)
                        timeString.draw(at: CGPoint(x: margin + 20, y: yPosition + 20),
                                     withAttributes: [.font: timeFont])
                        
                        if let imageData = medication.imageData,
                           let image = UIImage(data: imageData) {
                            let imageSize: CGFloat = 40
                            let imageRect = CGRect(x: pageWidth - margin - imageSize,
                                                 y: yPosition,
                                                 width: imageSize,
                                                 height: imageSize)
                            image.draw(in: imageRect)
                        }
                        
                        let path = UIBezierPath()
                        path.move(to: CGPoint(x: margin, y: yPosition + 45))
                        path.addLine(to: CGPoint(x: pageWidth - margin, y: yPosition + 45))
                        UIColor.gray.withAlphaComponent(0.3).setStroke()
                        path.stroke()
                        
                        yPosition += 60
                    }
                }
                yPosition += 20
            }
            
            if medicationsByDate.isEmpty {
                let noDataText = "No medications found for the selected date range."
                let noDataFont = UIFont.systemFont(ofSize: 16)
                noDataText.draw(at: CGPoint(x: margin, y: yPosition),
                              withAttributes: [.font: noDataFont])
            }
        }
    }
}
