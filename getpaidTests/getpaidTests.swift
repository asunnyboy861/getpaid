//
//  getpaidTests.swift
//  getpaidTests
//
//  Created by MacMini4 on 2026/3/16.
//

import Foundation
import Testing
import SwiftData
@testable import getpaid

struct InvoiceTests {

    @Test func testInvoiceCreation() throws {
        let invoice = Invoice(
            invoiceNumber: "INV-2026-001",
            client: nil,
            items: [],
            subtotal: 100,
            taxRate: 10,
            total: 110,
            dueDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
            createdAt: Date(),
            status: .draft,
            notes: "Test invoice",
            escalationLevel: .none
        )

        #expect(invoice.invoiceNumber == "INV-2026-001")
        #expect(invoice.status == .draft)
        #expect(invoice.taxRate == 10)
        #expect(invoice.total == 110)
    }

    @Test func testInvoiceDaysOverdueNotOverdue() throws {
        let invoice = Invoice(
            invoiceNumber: "INV-2026-001",
            dueDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
            status: .sent
        )

        #expect(invoice.daysOverdue == 0)
        #expect(invoice.isOverdue == false)
    }

    @Test func testInvoiceDaysOverduePastDue() throws {
        let invoice = Invoice(
            invoiceNumber: "INV-2026-001",
            dueDate: Date().addingTimeInterval(-5 * 24 * 60 * 60),
            status: .sent
        )

        #expect(invoice.daysOverdue == 5)
        #expect(invoice.isOverdue == true)
    }

    @Test func testInvoiceDaysOverduePaidStatus() throws {
        let invoice = Invoice(
            invoiceNumber: "INV-2026-001",
            dueDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
            status: .paid
        )

        #expect(invoice.daysOverdue == 0)
        #expect(invoice.isOverdue == false)
    }

    @Test func testInvoiceDaysOverdueCancelledStatus() throws {
        let invoice = Invoice(
            invoiceNumber: "INV-2026-001",
            dueDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
            status: .cancelled
        )

        #expect(invoice.daysOverdue == 0)
        #expect(invoice.isOverdue == false)
    }
}

struct InvoiceItemTests {

    @Test func testInvoiceItemCalculation() throws {
        let item = InvoiceItem(
            itemDescription: "Web Development",
            quantity: 10,
            unitPrice: 150
        )

        #expect(item.itemDescription == "Web Development")
        #expect(item.quantity == 10)
        #expect(item.unitPrice == 150)
        #expect(item.total == 1500)
    }

    @Test func testInvoiceItemUpdateTotal() throws {
        let item = InvoiceItem(
            itemDescription: "Design Work",
            quantity: 5,
            unitPrice: 100
        )

        #expect(item.total == 500)

        item.quantity = 10
        item.updateTotal()

        #expect(item.total == 1000)
    }
}

struct InvoiceStatusTests {

    @Test func testInvoiceStatusIsOverdue() throws {
        #expect(InvoiceStatus.draft.isOverdue == false)
        #expect(InvoiceStatus.sent.isOverdue == false)
        #expect(InvoiceStatus.viewed.isOverdue == false)
        #expect(InvoiceStatus.overdue1to7.isOverdue == true)
        #expect(InvoiceStatus.overdue8to30.isOverdue == true)
        #expect(InvoiceStatus.overdue30plus.isOverdue == true)
        #expect(InvoiceStatus.paid.isOverdue == false)
        #expect(InvoiceStatus.cancelled.isOverdue == false)
    }
}

struct EscalationLevelTests {

    @Test func testEscalationLevelDisplayName() throws {
        #expect(EscalationLevel.none.displayName == "No Reminder")
        #expect(EscalationLevel.friendly.displayName == "Friendly Reminder")
        #expect(EscalationLevel.formal.displayName == "Formal Follow-up")
        #expect(EscalationLevel.final.displayName == "Final Notice")
        #expect(EscalationLevel.legal.displayName == "Legal Action")
    }

    @Test func testEscalationLevelDaysThreshold() throws {
        #expect(EscalationLevel.none.daysThreshold == 0)
        #expect(EscalationLevel.friendly.daysThreshold == 1)
        #expect(EscalationLevel.formal.daysThreshold == 7)
        #expect(EscalationLevel.final.daysThreshold == 14)
        #expect(EscalationLevel.legal.daysThreshold == 30)
    }
}

struct ClientTests {

    @Test func testClientCreation() throws {
        let client = Client(
            name: "John Smith",
            email: "john@example.com",
            phone: "555-1234",
            companyName: "Smith Corp"
        )

        #expect(client.name == "John Smith")
        #expect(client.email == "john@example.com")
        #expect(client.phone == "555-1234")
        #expect(client.companyName == "Smith Corp")
    }

    @Test func testClientTotalOutstandingNoInvoices() throws {
        let client = Client(
            name: "John Smith",
            email: "john@example.com"
        )

        #expect(client.totalOutstanding == 0)
        #expect(client.totalPaid == 0)
    }

    @Test func testClientTotalOutstandingWithPaidInvoice() throws {
        let client = Client(
            name: "John Smith",
            email: "john@example.com"
        )

        let paidInvoice = Invoice(
            invoiceNumber: "INV-001",
            client: client,
            total: 1000,
            status: .paid
        )
        paidInvoice.paymentReceivedDate = Date()

        let unpaidInvoice = Invoice(
            invoiceNumber: "INV-002",
            client: client,
            total: 500,
            status: .sent
        )

        client.invoices = [paidInvoice, unpaidInvoice]

        #expect(client.totalOutstanding == 500)
        #expect(client.totalPaid == 1000)
    }

    @Test func testClientPaymentScoreNoInvoices() throws {
        let client = Client(
            name: "New Client",
            email: "new@example.com"
        )

        #expect(client.paymentScore == .excellent)
    }
}

struct PaymentScoreTests {

    @Test func testPaymentScoreDisplayName() throws {
        #expect(PaymentScore.excellent.displayName == "Excellent (A)")
        #expect(PaymentScore.good.displayName == "Good (B)")
        #expect(PaymentScore.fair.displayName == "Fair (C)")
        #expect(PaymentScore.poor.displayName == "Poor (D)")
    }
}

struct RiskLevelTests {

    @Test func testRiskLevelDisplayName() throws {
        #expect(RiskLevel.low.displayName == "Low Risk")
        #expect(RiskLevel.medium.displayName == "Medium Risk")
        #expect(RiskLevel.high.displayName == "High Risk")
        #expect(RiskLevel.critical.displayName == "Critical Risk")
    }
}

@MainActor
struct TemplateServiceTests {

    @Test func testPopulateSubject() throws {
        let client = Client(
            name: "John Smith",
            email: "john@example.com"
        )

        let invoice = Invoice(
            invoiceNumber: "INV-2026-001",
            client: client,
            total: 500,
            dueDate: Date(),
            status: .sent
        )

        let subject = "Invoice {{invoice_number}} for {{total_amount}}"
        let result = TemplateService.shared.populateSubject(subject, for: invoice, client: client)

        #expect(result.contains("INV-2026-001"))
        #expect(result.contains("$500.00") || result.contains("500"))
    }
}

struct SubscriptionTierTests {

    @Test func testSubscriptionTierDisplayName() throws {
        #expect(SubscriptionTier.free.displayName == "Free")
        #expect(SubscriptionTier.pro.displayName == "Pro")
        #expect(SubscriptionTier.business.displayName == "Business")
    }

    @Test func testSubscriptionTierMaxInvoices() throws {
        #expect(SubscriptionTier.free.maxInvoices == 5)
        #expect(SubscriptionTier.pro.maxInvoices == 100)
        #expect(SubscriptionTier.business.maxInvoices == .max)
    }

    @Test func testSubscriptionTierMaxClients() throws {
        #expect(SubscriptionTier.free.maxClients == 10)
        #expect(SubscriptionTier.pro.maxClients == 100)
        #expect(SubscriptionTier.business.maxClients == .max)
    }

    @Test func testSubscriptionTierHasAutomation() throws {
        #expect(SubscriptionTier.free.hasAutomation == false)
        #expect(SubscriptionTier.pro.hasAutomation == true)
        #expect(SubscriptionTier.business.hasAutomation == true)
    }

    @Test func testSubscriptionTierComparisons() throws {
        #expect(SubscriptionTier.free < SubscriptionTier.pro)
        #expect(SubscriptionTier.pro < SubscriptionTier.business)
        #expect(SubscriptionTier.free < SubscriptionTier.business)
    }
}

struct AppSettingsTests {

    @Test func testAppSettingsDefaultValues() throws {
        let settings = AppSettings()

        #expect(settings.businessName == "")
        #expect(settings.businessEmail == "")
        #expect(settings.defaultTaxRate == 0)
        #expect(settings.defaultPaymentTerms == 30)
        #expect(settings.currency == "USD")
        #expect(settings.hasCompletedOnboarding == false)
    }

    @Test func testAppSettingsCustomValues() throws {
        let settings = AppSettings(
            businessName: "My Business",
            businessEmail: "test@business.com",
            defaultTaxRate: 8.25,
            defaultPaymentTerms: 45,
            hasCompletedOnboarding: true
        )

        #expect(settings.businessName == "My Business")
        #expect(settings.businessEmail == "test@business.com")
        #expect(settings.defaultTaxRate == 8.25)
        #expect(settings.defaultPaymentTerms == 45)
        #expect(settings.hasCompletedOnboarding == true)
    }
}