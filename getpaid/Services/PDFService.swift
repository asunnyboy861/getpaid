//
//  PDFService.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import Foundation
import PDFKit
import UIKit

final class PDFService {
    static let shared = PDFService()
    
    private init() {}
    
    func generateInvoicePDF(invoice: Invoice, settings: AppSettings?) -> Data? {
        let effectiveSettings = settings ?? AppSettings()
        
        let pdfMetaData = [
            kCGPDFContextCreator: "GetPaid",
            kCGPDFContextAuthor: effectiveSettings.businessName
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            var yPosition: CGFloat = 50
            
            drawHeader(invoice: invoice, settings: effectiveSettings, in: context, pageRect: pageRect, yPosition: &yPosition)
            drawClientInfo(invoice: invoice, in: context, pageRect: pageRect, yPosition: &yPosition)
            drawLineItems(invoice: invoice, in: context, pageRect: pageRect, yPosition: &yPosition)
            drawTotals(invoice: invoice, in: context, pageRect: pageRect, yPosition: &yPosition)
            drawFooter(invoice: invoice, settings: effectiveSettings, in: context, pageRect: pageRect)
        }
        
        return data
    }
    
    private func drawHeader(invoice: Invoice, settings: AppSettings, in context: UIGraphicsPDFRendererContext, pageRect: CGRect, yPosition: inout CGFloat) {
        let titleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
        let subtitleFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        
        let title = "INVOICE"
        let titleAttributes: [NSAttributedString.Key: Any] = [.font: titleFont]
        title.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: titleAttributes)
        
        let businessName = settings.businessName
        let businessAttributes: [NSAttributedString.Key: Any] = [.font: subtitleFont]
        businessName.draw(at: CGPoint(x: pageRect.width - 50 - businessName.size(withAttributes: businessAttributes).width, y: yPosition + 5), withAttributes: businessAttributes)
        
        yPosition += 50
        
        let invoiceNumber = "Invoice #: \(invoice.invoiceNumber)"
        invoiceNumber.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: businessAttributes)
        
        let dateText = "Date: \(invoice.createdAt.formatted(date: .abbreviated, time: .omitted))"
        dateText.draw(at: CGPoint(x: pageRect.width - 50 - dateText.size(withAttributes: businessAttributes).width, y: yPosition), withAttributes: businessAttributes)
        
        yPosition += 20
        
        let dueDateText = "Due Date: \(invoice.dueDate.formatted(date: .abbreviated, time: .omitted))"
        dueDateText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: businessAttributes)
        
        yPosition += 40
        
        drawLine(in: context, from: CGPoint(x: 50, y: yPosition), to: CGPoint(x: pageRect.width - 50, y: yPosition))
        
        yPosition += 20
    }
    
    private func drawClientInfo(invoice: Invoice, in context: UIGraphicsPDFRendererContext, pageRect: CGRect, yPosition: inout CGFloat) {
        guard let client = invoice.client else { return }
        
        let labelFont = UIFont.systemFont(ofSize: 10, weight: .semibold)
        let valueFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        
        let billTo = "BILL TO"
        let billToAttributes: [NSAttributedString.Key: Any] = [.font: labelFont]
        billTo.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: billToAttributes)
        
        yPosition += 15
        
        let clientName = client.name
        let clientAttributes: [NSAttributedString.Key: Any] = [.font: valueFont]
        clientName.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: clientAttributes)
        
        yPosition += 18
        
        if !client.companyName.isEmpty {
            client.companyName.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: clientAttributes)
            yPosition += 18
        }
        
        client.email.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: clientAttributes)
        
        yPosition += 18
        
        if !client.phone.isEmpty {
            client.phone.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: clientAttributes)
            yPosition += 18
        }
        
        yPosition += 30
    }
    
    private func drawLineItems(invoice: Invoice, in context: UIGraphicsPDFRendererContext, pageRect: CGRect, yPosition: inout CGFloat) {
        let headerFont = UIFont.systemFont(ofSize: 10, weight: .semibold)
        let valueFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        
        let columns: [(title: String, width: CGFloat, alignment: NSTextAlignment)] = [
            ("Description", 280, .left),
            ("Qty", 60, .center),
            ("Price", 100, .right),
            ("Total", 100, .right)
        ]
        
        var xPosition: CGFloat = 50
        
        for column in columns {
            let attributes: [NSAttributedString.Key: Any] = [.font: headerFont]
            let rect = CGRect(x: xPosition, y: yPosition, width: column.width, height: 20)
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = column.alignment
            let fullAttributes = attributes.merging([.paragraphStyle: paragraphStyle], uniquingKeysWith: { $1 })
            
            column.title.draw(in: rect, withAttributes: fullAttributes)
            xPosition += column.width
        }
        
        yPosition += 25
        
        drawLine(in: context, from: CGPoint(x: 50, y: yPosition), to: CGPoint(x: pageRect.width - 50, y: yPosition))
        
        yPosition += 10
        
        for item in invoice.items {
            xPosition = 50
            
            let itemColumns: [(value: String, width: CGFloat, alignment: NSTextAlignment)] = [
                (item.itemDescription, 280, .left),
                (item.quantity.description, 60, .center),
                (item.unitPrice.formatted(.currency(code: "USD")), 100, .right),
                (item.total.formatted(.currency(code: "USD")), 100, .right)
            ]
            
            for column in itemColumns {
                let attributes: [NSAttributedString.Key: Any] = [.font: valueFont]
                let rect = CGRect(x: xPosition, y: yPosition, width: column.width, height: 20)
                
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = column.alignment
                let fullAttributes = attributes.merging([.paragraphStyle: paragraphStyle], uniquingKeysWith: { $1 })
                
                column.value.draw(in: rect, withAttributes: fullAttributes)
                xPosition += column.width
            }
            
            yPosition += 25
        }
        
        yPosition += 10
        
        drawLine(in: context, from: CGPoint(x: 50, y: yPosition), to: CGPoint(x: pageRect.width - 50, y: yPosition))
        
        yPosition += 20
    }
    
    private func drawTotals(invoice: Invoice, in context: UIGraphicsPDFRendererContext, pageRect: CGRect, yPosition: inout CGFloat) {
        let labelFont = UIFont.systemFont(ofSize: 12, weight: .regular)
        let valueFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        let totalFont = UIFont.systemFont(ofSize: 14, weight: .bold)
        
        let rightX = pageRect.width - 50
        
        let subtotalLabel = "Subtotal:"
        let subtotalValue = invoice.subtotal.formatted(.currency(code: "USD"))
        
        let labelAttributes: [NSAttributedString.Key: Any] = [.font: labelFont]
        let valueAttributes: [NSAttributedString.Key: Any] = [.font: valueFont]
        
        subtotalLabel.draw(at: CGPoint(x: rightX - 200, y: yPosition), withAttributes: labelAttributes)
        subtotalValue.draw(at: CGPoint(x: rightX - subtotalValue.size(withAttributes: valueAttributes).width, y: yPosition), withAttributes: valueAttributes)
        
        yPosition += 25
        
        if invoice.taxRate > 0 {
            let taxLabel = "Tax (\(invoice.taxRate)%):"
            let taxValue = (invoice.subtotal * invoice.taxRate / 100).formatted(.currency(code: "USD"))
            
            taxLabel.draw(at: CGPoint(x: rightX - 200, y: yPosition), withAttributes: labelAttributes)
            taxValue.draw(at: CGPoint(x: rightX - taxValue.size(withAttributes: valueAttributes).width, y: yPosition), withAttributes: valueAttributes)
            
            yPosition += 25
        }
        
        let totalLabel = "TOTAL:"
        let totalValue = invoice.total.formatted(.currency(code: "USD"))
        
        let totalLabelAttributes: [NSAttributedString.Key: Any] = [.font: totalFont]
        let totalValueAttributes: [NSAttributedString.Key: Any] = [.font: totalFont]
        
        totalLabel.draw(at: CGPoint(x: rightX - 200, y: yPosition), withAttributes: totalLabelAttributes)
        totalValue.draw(at: CGPoint(x: rightX - totalValue.size(withAttributes: totalValueAttributes).width, y: yPosition), withAttributes: totalValueAttributes)
        
        yPosition += 40
    }
    
    private func drawFooter(invoice: Invoice, settings: AppSettings, in context: UIGraphicsPDFRendererContext, pageRect: CGRect) {
        let footerFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        let footerAttributes: [NSAttributedString.Key: Any] = [.font: footerFont]
        
        let yPosition = pageRect.height - 50
        
        if !settings.businessEmail.isEmpty {
            let contactText = "Contact: \(settings.businessEmail)"
            contactText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: footerAttributes)
        }
        
        let thankYou = "Thank you for your business!"
        let thankYouWidth = thankYou.size(withAttributes: footerAttributes).width
        thankYou.draw(at: CGPoint(x: (pageRect.width - thankYouWidth) / 2, y: yPosition), withAttributes: footerAttributes)
        
        let pageText = "Page 1 of 1"
        let pageWidth = pageText.size(withAttributes: footerAttributes).width
        pageText.draw(at: CGPoint(x: pageRect.width - 50 - pageWidth, y: yPosition), withAttributes: footerAttributes)
    }
    
    private func drawLine(in context: UIGraphicsPDFRendererContext, from start: CGPoint, to end: CGPoint) {
        context.cgContext.setStrokeColor(UIColor.gray.cgColor)
        context.cgContext.setLineWidth(0.5)
        context.cgContext.move(to: start)
        context.cgContext.addLine(to: end)
        context.cgContext.strokePath()
    }
}
