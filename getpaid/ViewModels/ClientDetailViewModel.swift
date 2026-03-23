//
//  ClientDetailViewModel.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class ClientDetailViewModel {
    var client: Client
    var isEditing: Bool = false
    var editedName: String = ""
    var editedEmail: String = ""
    var editedPhone: String = ""
    var editedCompanyName: String = ""
    var editedAddress: String = ""
    var editedNotes: String = ""
    
    private var modelContext: ModelContext
    
    init(client: Client, modelContext: ModelContext) {
        self.client = client
        self.modelContext = modelContext
        populateEditFields()
    }
    
    func populateEditFields() {
        editedName = client.name
        editedEmail = client.email
        editedPhone = client.phone
        editedCompanyName = client.companyName
        editedAddress = client.address
        editedNotes = client.notes
    }
    
    func saveChanges() {
        ClientService.shared.updateClient(
            client: client,
            name: editedName,
            email: editedEmail,
            phone: editedPhone,
            companyName: editedCompanyName,
            address: editedAddress,
            notes: editedNotes
        )
        isEditing = false
    }
    
    func cancelEditing() {
        populateEditFields()
        isEditing = false
    }
    
    var formattedTotalOutstanding: String {
        client.totalOutstanding.formatted(.currency(code: "USD"))
    }
    
    var formattedTotalPaid: String {
        client.totalPaid.formatted(.currency(code: "USD"))
    }
    
    var paymentScoreColor: Color {
        switch client.paymentScore {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
    
    var riskLevelColor: Color {
        switch client.riskLevel {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    var paidInvoicesCount: Int {
        client.invoices.filter { $0.status == .paid }.count
    }
    
    var pendingInvoicesCount: Int {
        client.invoices.filter { $0.status != .paid && $0.status != .cancelled }.count
    }
}
