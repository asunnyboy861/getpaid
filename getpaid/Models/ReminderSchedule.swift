//
//  ReminderSchedule.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import Foundation
import SwiftData

@Model
final class ReminderSchedule {
    var id: UUID
    var invoice: Invoice?
    var scheduledDate: Date
    var escalationLevel: EscalationLevel
    var isSent: Bool
    var sentDate: Date?
    var errorMessage: String?
    
    init(
        id: UUID = UUID(),
        invoice: Invoice? = nil,
        scheduledDate: Date = Date(),
        escalationLevel: EscalationLevel = .friendly,
        isSent: Bool = false
    ) {
        self.id = id
        self.invoice = invoice
        self.scheduledDate = scheduledDate
        self.escalationLevel = escalationLevel
        self.isSent = isSent
    }
    
    var isOverdue: Bool {
        return scheduledDate < Date() && !isSent
    }
}
