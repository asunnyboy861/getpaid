//
//  TemplateService.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/17.
//

import Foundation
import SwiftData

@MainActor
final class TemplateService {
    static let shared = TemplateService()

    private init() {}

    func populateTemplate(
        _ template: String,
        for invoice: Invoice,
        client: Client,
        businessName: String
    ) -> String {
        var result = template

        result = result.replacingOccurrences(
            of: "{{client_name}}",
            with: client.name
        )

        result = result.replacingOccurrences(
            of: "{{client_company}}",
            with: client.companyName
        )

        result = result.replacingOccurrences(
            of: "{{invoice_number}}",
            with: invoice.invoiceNumber
        )

        let totalFormatter = NumberFormatter()
        totalFormatter.numberStyle = .currency
        totalFormatter.currencyCode = "USD"
        let totalString = totalFormatter.string(from: invoice.total as NSNumber) ?? "\(invoice.total)"

        result = result.replacingOccurrences(
            of: "{{total_amount}}",
            with: totalString
        )

        result = result.replacingOccurrences(
            of: "{{total}}",
            with: totalString
        )

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        let dueDateString = dateFormatter.string(from: invoice.dueDate)

        result = result.replacingOccurrences(
            of: "{{due_date}}",
            with: dueDateString
        )

        let daysOverdue = invoice.daysOverdue
        result = result.replacingOccurrences(
            of: "{{days_overdue}}",
            with: "\(daysOverdue)"
        )

        let invoiceDateFormatter = DateFormatter()
        invoiceDateFormatter.dateStyle = .medium
        let invoiceDateString = invoiceDateFormatter.string(from: invoice.createdAt)

        result = result.replacingOccurrences(
            of: "{{invoice_date}}",
            with: invoiceDateString
        )

        result = result.replacingOccurrences(
            of: "{{business_name}}",
            with: businessName
        )

        return result
    }

    func populateSubject(
        _ subject: String,
        for invoice: Invoice,
        client: Client
    ) -> String {
        var result = subject

        result = result.replacingOccurrences(
            of: "{{client_name}}",
            with: client.name
        )

        result = result.replacingOccurrences(
            of: "{{invoice_number}}",
            with: invoice.invoiceNumber
        )

        let totalFormatter = NumberFormatter()
        totalFormatter.numberStyle = .currency
        totalFormatter.currencyCode = "USD"
        let totalString = totalFormatter.string(from: invoice.total as NSNumber) ?? "\(invoice.total)"

        result = result.replacingOccurrences(
            of: "{{total_amount}}",
            with: totalString
        )

        return result
    }
}
