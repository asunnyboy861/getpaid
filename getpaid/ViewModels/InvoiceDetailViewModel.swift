//
//  InvoiceDetailViewModel.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class InvoiceDetailViewModel {
    var invoice: Invoice
    var pdfData: Data?
    var isSendingReminder: Bool = false
    var showPaymentSheet: Bool = false
    var showShareSheet: Bool = false
    var paymentDate: Date = Date()
    var paymentAmount: Decimal = 0
    var paymentMethod: String = ""
    
    var modelContext: ModelContext
    
    init(invoice: Invoice, modelContext: ModelContext) {
        self.invoice = invoice
        self.modelContext = modelContext
        self.paymentAmount = invoice.total
    }
    
    func generatePDF(settings: AppSettings?) {
        pdfData = PDFService.shared.generateInvoicePDF(invoice: invoice, settings: settings)
    }
    
    func sendReminder() async {
        isSendingReminder = true
        defer { isSendingReminder = false }
        
        invoice.lastReminderSent = Date()
    }
    
    func updateLastReminderSent() {
        invoice.lastReminderSent = Date()
    }
    
    func markAsPaid() {
        InvoiceService.shared.markAsPaid(invoice: invoice, paymentDate: paymentDate)
        invoice.paymentReceivedDate = paymentDate
    }
    
    func cancelInvoice() {
        InvoiceService.shared.cancelInvoice(invoice: invoice)
    }
    
    var formattedTotal: String {
        invoice.total.formatted(.currency(code: "USD"))
    }
    
    var formattedSubtotal: String {
        invoice.subtotal.formatted(.currency(code: "USD"))
    }
    
    var formattedTax: String {
        (invoice.subtotal * invoice.taxRate / 100).formatted(.currency(code: "USD"))
    }
    
    var statusColor: Color {
        switch invoice.status {
        case .draft, .cancelled:
            return .gray
        case .sent, .viewed:
            return .blue
        case .overdue1to7:
            return .orange
        case .overdue8to30:
            return .orange
        case .overdue30plus:
            return .red
        case .paid:
            return .green
        }
    }
    
    var escalationLevelText: String {
        invoice.escalationLevel.displayName
    }
}
