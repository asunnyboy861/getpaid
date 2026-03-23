//
//  Client.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import Foundation
import SwiftData

@Model
final class Client {
    var id: UUID
    var name: String
    var email: String
    var phone: String
    var companyName: String
    var address: String
    var notes: String
    var createdAt: Date
    var invoices: [Invoice]
    
    init(
        id: UUID = UUID(),
        name: String = "",
        email: String = "",
        phone: String = "",
        companyName: String = "",
        address: String = "",
        notes: String = "",
        createdAt: Date = Date(),
        invoices: [Invoice] = []
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.companyName = companyName
        self.address = address
        self.notes = notes
        self.createdAt = createdAt
        self.invoices = invoices
    }
    
    var totalOutstanding: Decimal {
        invoices
            .filter { $0.status != .paid && $0.status != .cancelled }
            .reduce(Decimal(0)) { $0 + $1.total }
    }
    
    var totalPaid: Decimal {
        invoices
            .filter { $0.status == .paid }
            .reduce(Decimal(0)) { $0 + $1.total }
    }
    
    var paymentScore: PaymentScore {
        let paidInvoices = invoices.filter { $0.status == .paid }
        let totalInvoices = Double(invoices.count)
        
        guard totalInvoices > 0 else { return .excellent }
        
        let paidRatio = Double(paidInvoices.count) / totalInvoices
        
        var totalDays = 0
        var overdueCount = 0
        
        for invoice in paidInvoices {
            if let paymentDate = invoice.paymentReceivedDate {
                let days = Calendar.current.dateComponents(
                    [.day],
                    from: invoice.dueDate,
                    to: paymentDate
                ).day ?? 0
                
                totalDays += days
                if days > 0 { overdueCount += 1 }
            }
        }
        
        let averagePaymentDays = paidInvoices.isEmpty ? 0 : totalDays / paidInvoices.count
        let overdueRatio = Double(overdueCount) / totalInvoices
        
        if paidRatio >= 0.95 && overdueRatio <= 0.1 && averagePaymentDays <= 3 {
            return .excellent
        } else if paidRatio >= 0.85 && overdueRatio <= 0.3 && averagePaymentDays <= 7 {
            return .good
        } else if paidRatio >= 0.70 && overdueRatio <= 0.5 && averagePaymentDays <= 30 {
            return .fair
        } else {
            return .poor
        }
    }
    
    var riskLevel: RiskLevel {
        let score = paymentScore
        let unpaidAmount = totalOutstanding
        
        switch score {
        case .excellent:
            return .low
        case .good:
            return unpaidAmount > 5000 ? .medium : .low
        case .fair:
            return unpaidAmount > 2000 ? .high : .medium
        case .poor:
            return .critical
        }
    }
}

enum PaymentScore: String, Codable, CaseIterable {
    case excellent = "A"
    case good = "B"
    case fair = "C"
    case poor = "D"
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent (A)"
        case .good: return "Good (B)"
        case .fair: return "Fair (C)"
        case .poor: return "Poor (D)"
        }
    }
}

enum RiskLevel: String, Codable, CaseIterable {
    case low = "Low Risk"
    case medium = "Medium Risk"
    case high = "High Risk"
    case critical = "Critical Risk"
    
    var displayName: String {
        return rawValue
    }
}
