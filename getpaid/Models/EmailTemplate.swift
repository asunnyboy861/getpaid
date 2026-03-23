//
//  EmailTemplate.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import Foundation
import SwiftData

@Model
final class EmailTemplate {
    var id: UUID
    var name: String
    var subject: String
    var body: String
    var category: TemplateCategory
    var isDefault: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        name: String = "",
        subject: String = "",
        body: String = "",
        category: TemplateCategory = .friendlyReminder,
        isDefault: Bool = false
    ) {
        self.id = id
        self.name = name
        self.subject = subject
        self.body = body
        self.category = category
        self.isDefault = isDefault
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func fillVariables(invoice: Invoice, client: Client) -> (subject: String, body: String) {
        var filledSubject = subject
        var filledBody = body
        
        filledSubject = filledSubject
            .replacingOccurrences(of: "{client_name}", with: client.name)
            .replacingOccurrences(of: "{invoice_number}", with: invoice.invoiceNumber)
            .replacingOccurrences(of: "{total_amount}", with: invoice.total.formatted(.currency(code: "USD")))
            .replacingOccurrences(of: "{due_date}", with: invoice.dueDate.formatted(date: .long, time: .omitted))
        
        filledBody = filledBody
            .replacingOccurrences(of: "{client_name}", with: client.name)
            .replacingOccurrences(of: "{invoice_number}", with: invoice.invoiceNumber)
            .replacingOccurrences(of: "{total_amount}", with: invoice.total.formatted(.currency(code: "USD")))
            .replacingOccurrences(of: "{due_date}", with: invoice.dueDate.formatted(date: .long, time: .omitted))
            .replacingOccurrences(of: "{days_overdue}", with: "\(invoice.daysOverdue)")
            .replacingOccurrences(of: "{company_name}", with: client.companyName)
        
        return (filledSubject, filledBody)
    }
}

enum TemplateCategory: String, Codable, CaseIterable {
    case friendlyReminder = "Friendly Reminder"
    case formalFollowup = "Formal Follow-up"
    case finalNotice = "Final Notice"
    case legalAction = "Legal Action"
    case custom = "Custom"
    
    var displayName: String {
        return rawValue
    }
    
    var escalationLevel: EscalationLevel {
        switch self {
        case .friendlyReminder: return .friendly
        case .formalFollowup: return .formal
        case .finalNotice: return .final
        case .legalAction: return .legal
        case .custom: return .none
        }
    }
}
