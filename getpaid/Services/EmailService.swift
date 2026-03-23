//
//  EmailService.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import Foundation
import MessageUI
import SwiftUI
import SwiftData

@MainActor
final class EmailService: NSObject {
    static let shared = EmailService()
    
    private var modelContext: ModelContext?
    
    private override init() {}
    
    func configure(with context: ModelContext) {
        self.modelContext = context
    }
    
    func canSendMail() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }
    
    func sendInvoiceEmail(
        invoice: Invoice,
        template: EmailTemplate? = nil,
        completion: @escaping (Result<Void, EmailError>) -> Void
    ) -> MFMailComposeViewController? {
        guard canSendMail() else {
            completion(.failure(.mailNotConfigured))
            return nil
        }
        
        guard let client = invoice.client else {
            completion(.failure(.noClient))
            return nil
        }
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setToRecipients([client.email])
        
        let subject = template?.subject ?? "Invoice \(invoice.invoiceNumber)"
        mailComposer.setSubject(subject)
        
        let body = buildEmailBody(invoice: invoice, template: template)
        mailComposer.setMessageBody(body, isHTML: true)
        
        if let pdfData = PDFService.shared.generateInvoicePDF(invoice: invoice, settings: nil) {
            mailComposer.addAttachmentData(
                pdfData,
                mimeType: "application/pdf",
                fileName: "\(invoice.invoiceNumber).pdf"
            )
        }
        
        self.completionHandler = completion
        return mailComposer
    }
    
    func sendReminderEmail(
        invoice: Invoice,
        escalationLevel: EscalationLevel,
        template: EmailTemplate? = nil,
        completion: @escaping (Result<Void, EmailError>) -> Void
    ) -> MFMailComposeViewController? {
        guard canSendMail() else {
            completion(.failure(.mailNotConfigured))
            return nil
        }
        
        guard let client = invoice.client else {
            completion(.failure(.noClient))
            return nil
        }
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        mailComposer.setToRecipients([client.email])
        
        let subject = buildReminderSubject(invoice: invoice, escalationLevel: escalationLevel)
        mailComposer.setSubject(subject)
        
        let body = buildReminderBody(invoice: invoice, escalationLevel: escalationLevel, template: template)
        mailComposer.setMessageBody(body, isHTML: true)
        
        if let pdfData = PDFService.shared.generateInvoicePDF(invoice: invoice, settings: nil) {
            mailComposer.addAttachmentData(
                pdfData,
                mimeType: "application/pdf",
                fileName: "\(invoice.invoiceNumber).pdf"
            )
        }
        
        self.completionHandler = completion
        return mailComposer
    }
    
    private func buildEmailBody(invoice: Invoice, template: EmailTemplate?) -> String {
        guard let client = invoice.client else { return "" }
        
        let templateBody = template?.body ?? """
        Dear {{client_name}},
        
        Please find attached invoice {{invoice_number}} for the amount of {{total}}.
        
        <strong>Invoice Details:</strong><br>
        Invoice Number: {{invoice_number}}<br>
        Amount Due: {{total}}<br>
        Due Date: {{due_date}}<br>
        
        Please remit payment at your earliest convenience.
        
        Best regards
        """
        
        return replaceTemplateVariables(templateBody, invoice: invoice, client: client)
    }
    
    private func buildReminderSubject(invoice: Invoice, escalationLevel: EscalationLevel) -> String {
        switch escalationLevel {
        case .none:
            return "Invoice \(invoice.invoiceNumber) - Payment Reminder"
        case .friendly:
            return "Friendly Reminder: Invoice \(invoice.invoiceNumber) - \(invoice.total.formatted(.currency(code: "USD")))"
        case .formal:
            return "Payment Reminder: Invoice \(invoice.invoiceNumber) - \(invoice.daysOverdue) Days Overdue"
        case .final:
            return "FINAL NOTICE: Invoice \(invoice.invoiceNumber) - Immediate Payment Required"
        case .legal:
            return "LEGAL NOTICE: Invoice \(invoice.invoiceNumber) - Collection Action Pending"
        }
    }
    
    private func buildReminderBody(invoice: Invoice, escalationLevel: EscalationLevel, template: EmailTemplate?) -> String {
        guard let client = invoice.client else { return "" }
        
        let defaultBody: String
        switch escalationLevel {
        case .none, .friendly:
            defaultBody = """
            <p>Dear {{client_name}},</p>
            
            <p>I hope this email finds you well. I wanted to follow up on <strong>Invoice {{invoice_number}}</strong> for <strong>{{total}}</strong>, which was due on {{due_date}}.</p>
            
            <p>The payment is now <strong>{{days_overdue}} days overdue</strong>. If you've already sent payment, please disregard this notice.</p>
            
            <p>Please find the invoice attached for your reference.</p>
            
            <p>Best regards</p>
            """
        case .formal:
            defaultBody = """
            <p>Dear {{client_name}},</p>
            
            <p>This is a formal reminder that <strong>Invoice {{invoice_number}}</strong> for <strong>{{total}}</strong> is now <strong>{{days_overdue}} days overdue</strong>.</p>
            
            <p>Original Due Date: {{due_date}}<br>
            Days Overdue: {{days_overdue}}</p>
            
            <p>We request that you remit payment immediately. Please contact us if you have any questions or concerns about this invoice.</p>
            
            <p>Regards</p>
            """
        case .final:
            defaultBody = """
            <p>Dear {{client_name}},</p>
            
            <p><strong>FINAL NOTICE</strong></p>
            
            <p>Invoice {{invoice_number}} for <strong>{{total}}</strong> is now <strong>{{days_overdue}} days overdue</strong>.</p>
            
            <p>This is your final notice before we escalate this matter. We strongly urge you to remit payment within 5 business days to avoid further action.</p>
            
            <p>If payment is not received, we may be forced to pursue additional collection measures, which could include:</p>
            <ul>
            <li>Late payment fees</li>
            <li>Collection agency referral</li>
            <li>Legal action</li>
            </ul>
            
            <p>Please contact us immediately to resolve this matter.</p>
            
            <p>Regards</p>
            """
        case .legal:
            defaultBody = """
            <p>Dear {{client_name}},</p>
            
            <p><strong>LEGAL NOTICE</strong></p>
            
            <p>Invoice {{invoice_number}} for <strong>{{total}}</strong> is now <strong>{{days_overdue}} days overdue</strong>.</p>
            
            <p>Despite multiple attempts to collect payment, we have not received payment for the above-referenced invoice.</p>
            
            <p>Please be advised that if payment is not received within 10 business days, we will have no choice but to refer this matter to our legal counsel for collection proceedings.</p>
            
            <p>All additional costs associated with collection, including legal fees and interest, may be added to the outstanding balance.</p>
            
            <p>This notice serves as your final opportunity to resolve this matter amicably.</p>
            
            <p>Sincerely</p>
            """
        }
        
        let templateBody = template?.body ?? defaultBody
        return replaceTemplateVariables(templateBody, invoice: invoice, client: client)
    }
    
    private func replaceTemplateVariables(_ template: String, invoice: Invoice, client: Client) -> String {
        var result = template
        
        result = result.replacingOccurrences(of: "{{client_name}}", with: client.name)
        result = result.replacingOccurrences(of: "{{client_company}}", with: client.companyName)
        result = result.replacingOccurrences(of: "{{invoice_number}}", with: invoice.invoiceNumber)
        result = result.replacingOccurrences(of: "{{total}}", with: invoice.total.formatted(.currency(code: "USD")))
        result = result.replacingOccurrences(of: "{{due_date}}", with: invoice.dueDate.formatted(date: .long, time: .omitted))
        result = result.replacingOccurrences(of: "{{days_overdue}}", with: "\(invoice.daysOverdue)")
        result = result.replacingOccurrences(of: "{{invoice_date}}", with: invoice.createdAt.formatted(date: .long, time: .omitted))
        result = result.replacingOccurrences(of: "{{business_name}}", with: getBusinessName())
        
        return result
    }
    
    private func getBusinessName() -> String {
        guard let context = modelContext else {
            return "Your Business"
        }
        
        let descriptor = FetchDescriptor<AppSettings>()
        
        do {
            let settings = try context.fetch(descriptor)
            if let name = settings.first?.businessName, !name.isEmpty {
                return name
            }
        } catch {}
        
        return "Your Business"
    }
    
    private var completionHandler: ((Result<Void, EmailError>) -> Void)?
}

extension EmailService: MFMailComposeViewControllerDelegate {
    nonisolated func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        Task { @MainActor in
            controller.dismiss(animated: true)
            
            if let error = error {
                completionHandler?(.failure(.sendFailed(error.localizedDescription)))
            } else {
                switch result {
                case .sent:
                    completionHandler?(.success(()))
                case .saved:
                    completionHandler?(.success(()))
                case .cancelled:
                    completionHandler?(.failure(.cancelled))
                case .failed:
                    completionHandler?(.failure(.unknown))
                @unknown default:
                    completionHandler?(.failure(.unknown))
                }
            }
            completionHandler = nil
        }
    }
}

enum EmailError: LocalizedError {
    case mailNotConfigured
    case noClient
    case cancelled
    case sendFailed(String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .mailNotConfigured:
            return "Please configure an email account in Settings to send emails."
        case .noClient:
            return "No client associated with this invoice."
        case .cancelled:
            return "Email was cancelled."
        case .sendFailed(let message):
            return "Failed to send email: \(message)"
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

struct MailComposerView: UIViewControllerRepresentable {
    let mailComposer: MFMailComposeViewController?
    @Binding var isPresented: Bool
    let completion: (Result<Void, EmailError>) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        if let mailComposer = mailComposer {
            return mailComposer
        }
        
        let alert = UIAlertController(
            title: "Mail Not Configured",
            message: "Please configure an email account in Settings to send emails.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            isPresented = false
            completion(.failure(.mailNotConfigured))
        })
        return alert
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
