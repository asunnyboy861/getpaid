//
//  InvoiceEditViewModel.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/20.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class InvoiceEditViewModel {
    var invoice: Invoice
    
    var selectedClient: Client?
    var items: [InvoiceItem] = []
    var dueDate: Date
    var taxRate: Decimal
    var notes: String
    var showAddItem: Bool = false
    var newItemDescription: String = ""
    var newItemQuantity: Decimal = 1
    var newItemPrice: Decimal = 0
    
    private var modelContext: ModelContext
    private var originalDueDate: Date
    private var originalTaxRate: Decimal
    private var originalNotes: String
    
    init(invoice: Invoice, modelContext: ModelContext) {
        self.invoice = invoice
        self.modelContext = modelContext
        
        self.selectedClient = invoice.client
        self.items = invoice.items
        self.dueDate = invoice.dueDate
        self.taxRate = invoice.taxRate
        self.notes = invoice.notes
        
        self.originalDueDate = invoice.dueDate
        self.originalTaxRate = invoice.taxRate
        self.originalNotes = invoice.notes
    }
    
    var hasChanges: Bool {
        dueDate != originalDueDate ||
        taxRate != originalTaxRate ||
        notes != originalNotes ||
        items.count != invoice.items.count
    }
    
    func saveChanges() {
        invoice.items = items
        invoice.dueDate = dueDate
        invoice.taxRate = taxRate
        invoice.notes = notes
        
        invoice.subtotal = items.reduce(Decimal(0)) { $0 + $1.total }
        invoice.total = invoice.subtotal + (invoice.subtotal * taxRate / 100)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save invoice changes: \(error)")
        }
    }
    
    func addItem() {
        let item = InvoiceItem(
            itemDescription: newItemDescription,
            quantity: newItemQuantity,
            unitPrice: newItemPrice
        )
        items.append(item)
        resetNewItemForm()
    }
    
    func removeItem(at index: Int) {
        guard index < items.count else { return }
        items.remove(at: index)
    }
    
    func resetNewItemForm() {
        newItemDescription = ""
        newItemQuantity = 1
        newItemPrice = 0
        showAddItem = false
    }
    
    var subtotal: Decimal {
        items.reduce(Decimal(0)) { $0 + $1.total }
    }
    
    var taxAmount: Decimal {
        subtotal * taxRate / 100
    }
    
    var total: Decimal {
        subtotal + taxAmount
    }
    
    var formattedSubtotal: String {
        subtotal.formatted(.currency(code: "USD"))
    }
    
    var formattedTax: String {
        taxAmount.formatted(.currency(code: "USD"))
    }
    
    var formattedTotal: String {
        total.formatted(.currency(code: "USD"))
    }
}
