//
//  DashboardViewModel.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import Foundation
import SwiftData
import SwiftUI
import MessageUI

@MainActor
@Observable
final class DashboardViewModel {
    var totalOutstanding: Decimal = 0
    var overdueAmount: Decimal = 0
    var pendingInvoicesCount: Int = 0
    var overdueInvoices: [Invoice] = []
    var upcomingReminders: [ReminderSchedule] = []
    var pendingReminders: [ReminderSchedule] = []
    var isLoading: Bool = false

    var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadData() {
        isLoading = true

        totalOutstanding = InvoiceService.shared.calculateTotalOutstanding(context: modelContext)
        overdueAmount = InvoiceService.shared.calculateOverdueAmount(context: modelContext)

        let allInvoices = InvoiceService.shared.fetchInvoices(context: modelContext)
        pendingInvoicesCount = allInvoices.filter { $0.status != .paid && $0.status != .cancelled }.count

        overdueInvoices = InvoiceService.shared.fetchOverdueInvoices(context: modelContext)

        pendingReminders = EscalationService.shared.getPendingReminders(context: modelContext)

        let reminderDescriptor = FetchDescriptor<ReminderSchedule>(
            predicate: #Predicate { $0.isSent == false },
            sortBy: [SortDescriptor(\.scheduledDate)]
        )

        do {
            upcomingReminders = try modelContext.fetch(reminderDescriptor)
        } catch {
            upcomingReminders = []
        }

        isLoading = false
    }

    func sendReminder(for invoice: Invoice) async {
        invoice.lastReminderSent = Date()
    }

    func markAsPaid(_ invoice: Invoice) {
        InvoiceService.shared.markAsPaid(invoice: invoice, paymentDate: Date())
    }

    func dismissReminder(_ reminder: ReminderSchedule) {
        EscalationService.shared.markReminderAsSent(context: modelContext, reminder: reminder)
        loadData()
    }

    var formattedTotalOutstanding: String {
        totalOutstanding.formatted(.currency(code: "USD"))
    }

    var formattedOverdueAmount: String {
        overdueAmount.formatted(.currency(code: "USD"))
    }

    var tomorrowRemindersCount: Int {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return upcomingReminders.filter { reminder in
            Calendar.current.isDate(reminder.scheduledDate, inSameDayAs: tomorrow)
        }.count
    }

    var thisWeekRemindersCount: Int {
        let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return upcomingReminders.filter { reminder in
            reminder.scheduledDate <= weekFromNow
        }.count
    }
}
