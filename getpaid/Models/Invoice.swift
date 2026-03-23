//
//  Invoice.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import Foundation
import SwiftData

@Model
final class Invoice {
    var id: UUID
    var invoiceNumber: String
    var client: Client?
    var items: [InvoiceItem]
    var subtotal: Decimal
    var taxRate: Decimal
    var total: Decimal
    var dueDate: Date
    var createdAt: Date
    var status: InvoiceStatus
    var notes: String
    var escalationLevel: EscalationLevel
    var lastReminderSent: Date?
    var paymentReceivedDate: Date?
    
    init(
        id: UUID = UUID(),
        invoiceNumber: String = "",
        client: Client? = nil,
        items: [InvoiceItem] = [],
        subtotal: Decimal = 0,
        taxRate: Decimal = 0,
        total: Decimal = 0,
        dueDate: Date = Date().addingTimeInterval(30 * 24 * 60 * 60),
        createdAt: Date = Date(),
        status: InvoiceStatus = .draft,
        notes: String = "",
        escalationLevel: EscalationLevel = .none
    ) {
        self.id = id
        self.invoiceNumber = invoiceNumber
        self.client = client
        self.items = items
        self.subtotal = subtotal
        self.taxRate = taxRate
        self.total = total
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.status = status
        self.notes = notes
        self.escalationLevel = escalationLevel
    }
    
    var daysOverdue: Int {
        guard status != .paid, status != .cancelled else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: dueDate, to: Date())
        return max(0, components.day ?? 0)
    }
    
    var isOverdue: Bool {
        return daysOverdue > 0
    }
}

enum InvoiceStatus: String, Codable, CaseIterable {
    case draft = "Draft"
    case sent = "Sent"
    case viewed = "Viewed"
    case overdue1to7 = "Overdue (1-7 days)"
    case overdue8to30 = "Overdue (8-30 days)"
    case overdue30plus = "Overdue (30+ days)"
    case paid = "Paid"
    case cancelled = "Cancelled"
    
    var displayName: String {
        return rawValue
    }
    
    var isOverdue: Bool {
        switch self {
        case .overdue1to7, .overdue8to30, .overdue30plus:
            return true
        default:
            return false
        }
    }
}

enum EscalationLevel: Int, Codable, CaseIterable {
    case none = 0
    case friendly = 1
    case formal = 2
    case final = 3
    case legal = 4
    
    var displayName: String {
        switch self {
        case .none: return "No Reminder"
        case .friendly: return "Friendly Reminder"
        case .formal: return "Formal Follow-up"
        case .final: return "Final Notice"
        case .legal: return "Legal Action"
        }
    }

    var daysThreshold: Int {
        switch self {
        case .none: return 0
        case .friendly: return 1
        case .formal: return 7
        case .final: return 14
        case .legal: return 30
        }
    }
}

import SwiftUI

extension EscalationLevel {
    var color: Color {
        switch self {
        case .none: return .gray
        case .friendly: return .blue
        case .formal: return .orange
        case .final: return .red
        case .legal: return .purple
        }
    }
}
