//
//  InvoiceListViewModel.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class InvoiceListViewModel {
    var invoices: [Invoice] = []
    var filteredInvoices: [Invoice] = []
    var searchText: String = ""
    var selectedStatus: InvoiceStatus?
    var isLoading: Bool = false
    
    var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func loadInvoices() {
        isLoading = true
        invoices = InvoiceService.shared.fetchInvoices(context: modelContext, status: selectedStatus)
        applyFilter()
        isLoading = false
    }
    
    func applyFilter() {
        if searchText.isEmpty {
            filteredInvoices = invoices
        } else {
            filteredInvoices = invoices.filter { invoice in
                invoice.invoiceNumber.localizedCaseInsensitiveContains(searchText) ||
                (invoice.client?.name.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (invoice.client?.companyName.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    func filterByStatus(_ status: InvoiceStatus?) {
        selectedStatus = status
        loadInvoices()
    }
    
    func deleteInvoice(_ invoice: Invoice) {
        InvoiceService.shared.deleteInvoice(context: modelContext, invoice: invoice)
        loadInvoices()
    }
    
    func invoicesByStatus(_ status: InvoiceStatus) -> [Invoice] {
        return filteredInvoices.filter { $0.status == status }
    }
    
    var draftCount: Int {
        invoices.filter { $0.status == .draft }.count
    }
    
    var sentCount: Int {
        invoices.filter { $0.status == .sent || $0.status == .viewed }.count
    }
    
    var overdueCount: Int {
        invoices.filter { $0.status.isOverdue }.count
    }
    
    var paidCount: Int {
        invoices.filter { $0.status == .paid }.count
    }
}
