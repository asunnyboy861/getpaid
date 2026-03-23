//
//  InvoiceCreationViewModel.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class InvoiceCreationViewModel {
    var selectedClient: Client?
    var items: [InvoiceItem] = []
    var dueDate: Date = Date().addingTimeInterval(30 * 24 * 60 * 60)
    var taxRate: Decimal = 0
    var notes: String = ""
    var clients: [Client] = []
    var showClientPicker: Bool = false
    var showAddItem: Bool = false
    var newItemDescription: String = ""
    var newItemQuantity: Decimal = 1
    var newItemPrice: Decimal = 0
    var isSaving: Bool = false
    
    var createdInvoice: Invoice?
    var showSendConfirmation: Bool = false
    
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func loadClients() {
        clients = ClientService.shared.fetchClients(context: modelContext)
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
        items.remove(at: index)
    }
    
    func resetNewItemForm() {
        newItemDescription = ""
        newItemQuantity = 1
        newItemPrice = 0
    }
    
    func createInvoiceAndPrepareSend() -> Invoice? {
        guard let invoice = createInvoice() else { return nil }
        createdInvoice = invoice
        showSendConfirmation = true
        return invoice
    }
    
    func createInvoice() -> Invoice? {
        guard let client = selectedClient, !items.isEmpty else { return nil }

        isSaving = true
        defer { isSaving = false }

        guard let invoice = InvoiceService.shared.createInvoice(
            context: modelContext,
            client: client,
            items: items,
            dueDate: dueDate,
            taxRate: taxRate,
            notes: notes
        ) else {
            return nil
        }

        EscalationService.shared.scheduleReminders(context: modelContext, invoice: invoice)

        return invoice
    }
    
    func markInvoiceAsSent() {
        guard let invoice = createdInvoice else { return }
        invoice.status = .sent
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to update invoice status: \(error)")
        }
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
    
    var canCreateInvoice: Bool {
        selectedClient != nil && !items.isEmpty
    }
}
