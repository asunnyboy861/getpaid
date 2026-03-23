//
//  EscalationService.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import Foundation
import SwiftData
import UserNotifications

@MainActor
final class EscalationService {
    static let shared = EscalationService()
    
    private init() {}
    
    func scheduleReminders(context: ModelContext, invoice: Invoice) {
        guard invoice.status != .paid && invoice.status != .cancelled else { return }
        
        let dueDate = invoice.dueDate
        
        let reminderDates: [(EscalationLevel, Date)] = [
            (.friendly, dueDate.addingTimeInterval(1 * 24 * 60 * 60)),
            (.formal, dueDate.addingTimeInterval(7 * 24 * 60 * 60)),
            (.final, dueDate.addingTimeInterval(14 * 24 * 60 * 60)),
            (.legal, dueDate.addingTimeInterval(30 * 24 * 60 * 60))
        ]
        
        for (level, date) in reminderDates {
            let schedule = ReminderSchedule(
                invoice: invoice,
                scheduledDate: date,
                escalationLevel: level
            )
            context.insert(schedule)
        }

        do {
            try context.save()
        } catch {
            print("Failed to schedule reminders: \(error)")
        }
    }
    
    func processDueReminders(context: ModelContext) async {
        let now = Date()
        
        let descriptor = FetchDescriptor<ReminderSchedule>(
            predicate: #Predicate { schedule in
                schedule.isSent == false && schedule.scheduledDate <= now
            },
            sortBy: [SortDescriptor(\.scheduledDate)]
        )
        
        do {
            let dueReminders = try context.fetch(descriptor)
            
            for reminder in dueReminders {
                guard let invoice = reminder.invoice else { continue }
                
                scheduleLocalNotification(
                    for: invoice,
                    at: Date(),
                    title: "Payment Reminder Due",
                    body: "Invoice \(invoice.invoiceNumber) needs attention - \(invoice.escalationLevel.displayName)"
                )
                
                reminder.isSent = true
                reminder.sentDate = Date()
                invoice.lastReminderSent = Date()
                invoice.escalationLevel = reminder.escalationLevel
            }
            
            try context.save()
            
        } catch {
            print("Error processing reminders: \(error)")
        }
    }
    
    func updateInvoiceStatuses(context: ModelContext) {
        let descriptor = FetchDescriptor<Invoice>()

        do {
            let invoices = try context.fetch(descriptor)

            for invoice in invoices {
                InvoiceService.shared.updateInvoiceStatus(invoice: invoice)
            }

            try context.save()

        } catch {
            print("Error updating invoice statuses: \(error)")
        }
    }

    func getPendingReminders(context: ModelContext) -> [ReminderSchedule] {
        let now = Date()
        let descriptor = FetchDescriptor<ReminderSchedule>(
            predicate: #Predicate { schedule in
                schedule.isSent == false && schedule.scheduledDate <= now
            },
            sortBy: [SortDescriptor(\.scheduledDate, order: .forward)]
        )

        do {
            return try context.fetch(descriptor)
        } catch {
            return []
        }
    }

    func markReminderAsSent(context: ModelContext, reminder: ReminderSchedule) {
        reminder.isSent = true
        reminder.sentDate = Date()

        if let invoice = reminder.invoice {
            invoice.lastReminderSent = Date()
            invoice.escalationLevel = reminder.escalationLevel
        }

        do {
            try context.save()
        } catch {
            print("Failed to save reminder: \(error)")
        }
    }
    
    func getDefaultTemplate(for level: EscalationLevel) -> EmailTemplate {
        switch level {
        case .none:
            return EmailTemplate()
        case .friendly:
            return EmailTemplate(
                name: "Friendly Reminder",
                subject: "Friendly Reminder: Invoice {invoice_number}",
                body: """
                Hi {client_name},
                
                I hope this message finds you well. I wanted to send a friendly reminder about Invoice {invoice_number} for {total_amount}, which was due on {due_date}.
                
                If you've already sent payment, thank you! If not, please let me know if you have any questions about the invoice.
                
                Best regards
                """,
                category: .friendlyReminder
            )
        case .formal:
            return EmailTemplate(
                name: "Formal Follow-up",
                subject: "Follow-up: Invoice {invoice_number} - {total_amount}",
                body: """
                Dear {client_name},
                
                This is a follow-up regarding Invoice {invoice_number} for {total_amount}, which is now {days_overdue} days overdue (due date: {due_date}).
                
                I have not yet received payment for this invoice. Please arrange for payment at your earliest convenience. If you have any questions or concerns about this invoice, please contact me immediately.
                
                Payment can be made via the methods outlined on the invoice.
                
                Thank you for your prompt attention to this matter.
                
                Best regards
                """,
                category: .formalFollowup
            )
        case .final:
            return EmailTemplate(
                name: "Final Notice",
                subject: "FINAL NOTICE: Invoice {invoice_number} - Immediate Payment Required",
                body: """
                Dear {client_name},
                
                This is a final notice regarding Invoice {invoice_number} for {total_amount}, which is now {days_overdue} days overdue.
                
                Despite multiple reminders, payment has not been received. This is your final notice before we escalate this matter further.
                
                Please remit payment immediately to avoid additional action. If payment has already been sent, please provide proof of payment.
                
                If we do not receive payment within 7 days, we will be forced to pursue additional collection measures.
                
                Sincerely
                """,
                category: .finalNotice
            )
        case .legal:
            return EmailTemplate(
                name: "Legal Action Notice",
                subject: "NOTICE: Invoice {invoice_number} - Collection Action Pending",
                body: """
                Dear {client_name},
                
                Despite multiple attempts to collect payment for Invoice {invoice_number} ({total_amount}), which is now {days_overdue} days overdue, we have not received payment.
                
                We are now preparing to pursue this matter through legal channels, including small claims court if necessary.
                
                This is your final opportunity to resolve this matter before legal proceedings begin. Please contact us immediately to discuss payment arrangements.
                
                Legal action will result in additional costs being added to the outstanding balance.
                
                Sincerely
                """,
                category: .legalAction
            )
        }
    }
    
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            return granted
        } catch {
            return false
        }
    }
    
    func scheduleLocalNotification(for invoice: Invoice, at date: Date, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["invoiceId": invoice.id.uuidString]
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "invoice-\(invoice.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}
