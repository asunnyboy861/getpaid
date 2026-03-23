//
//  InvoiceService.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import Foundation
import SwiftData

@MainActor
final class InvoiceService {
    static let shared = InvoiceService()
    
    private init() {}
    
    func generateInvoiceNumber(context: ModelContext) -> String {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        let month = calendar.component(.month, from: now)
        let day = calendar.component(.day, from: now)
        
        let datePrefix = String(format: "%04d%02d%02d", year, month, day)
        
        let descriptor = FetchDescriptor<Invoice>()
        
        do {
            let allInvoices = try context.fetch(descriptor)
            let matchingInvoices = allInvoices.filter { $0.invoiceNumber.hasPrefix("INV-\(datePrefix)") }
            let count = matchingInvoices.count
            let sequence = count + 1
            return String(format: "INV-%@-%04d", datePrefix, sequence)
        } catch {
            return String(format: "INV-%@-0001", datePrefix)
        }
    }
    
    func createInvoice(
        context: ModelContext,
        client: Client,
        items: [InvoiceItem],
        dueDate: Date,
        taxRate: Decimal,
        notes: String
    ) -> Invoice? {
        let invoiceNumber = generateInvoiceNumber(context: context)

        let subtotal = items.reduce(Decimal(0)) { $0 + $1.total }
        let taxAmount = subtotal * taxRate / 100
        let total = subtotal + taxAmount

        let invoice = Invoice(
            invoiceNumber: invoiceNumber,
            client: client,
            items: items,
            subtotal: subtotal,
            taxRate: taxRate,
            total: total,
            dueDate: dueDate,
            notes: notes
        )

        context.insert(invoice)

        do {
            try context.save()
            return invoice
        } catch {
            print("Failed to save invoice: \(error)")
            return nil
        }
    }
    
    func updateInvoiceStatus(invoice: Invoice) {
        let daysOverdue = invoice.daysOverdue
        
        if invoice.status == .paid || invoice.status == .cancelled {
            return
        }
        
        if invoice.status == .draft {
            return
        }
        
        if daysOverdue == 0 {
            invoice.status = .sent
        } else if daysOverdue <= 7 {
            invoice.status = .overdue1to7
            invoice.escalationLevel = .friendly
        } else if daysOverdue <= 30 {
            invoice.status = .overdue8to30
            invoice.escalationLevel = daysOverdue <= 14 ? .formal : .final
        } else {
            invoice.status = .overdue30plus
            invoice.escalationLevel = .legal
        }
    }
    
    func markAsPaid(invoice: Invoice, paymentDate: Date = Date()) {
        invoice.status = .paid
        invoice.paymentReceivedDate = paymentDate
        invoice.escalationLevel = .none
    }
    
    func cancelInvoice(invoice: Invoice) {
        invoice.status = .cancelled
        invoice.escalationLevel = .none
    }
    
    func deleteInvoice(context: ModelContext, invoice: Invoice) {
        context.delete(invoice)
    }
    
    func fetchInvoices(context: ModelContext, status: InvoiceStatus? = nil) -> [Invoice] {
        let descriptor = FetchDescriptor<Invoice>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let allInvoices = try context.fetch(descriptor)
            if let status = status {
                return allInvoices.filter { $0.status == status }
            }
            return allInvoices
        } catch {
            return []
        }
    }
    
    func fetchOverdueInvoices(context: ModelContext) -> [Invoice] {
        let descriptor = FetchDescriptor<Invoice>(
            sortBy: [SortDescriptor(\.dueDate, order: .forward)]
        )
        
        do {
            let allInvoices = try context.fetch(descriptor)
            return allInvoices.filter { invoice in
                invoice.status == .overdue1to7 ||
                invoice.status == .overdue8to30 ||
                invoice.status == .overdue30plus
            }
        } catch {
            return []
        }
    }
    
    func calculateTotalOutstanding(context: ModelContext) -> Decimal {
        let invoices = fetchInvoices(context: context)
        return invoices
            .filter { $0.status != .paid && $0.status != .cancelled }
            .reduce(Decimal(0)) { $0 + $1.total }
    }
    
    func calculateOverdueAmount(context: ModelContext) -> Decimal {
        let overdueInvoices = fetchOverdueInvoices(context: context)
        return overdueInvoices.reduce(Decimal(0)) { $0 + $1.total }
    }
}
