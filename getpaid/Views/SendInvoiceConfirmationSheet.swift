//
//  SendInvoiceConfirmationSheet.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/20.
//

import SwiftUI
import MessageUI

struct SendInvoiceConfirmationSheet: View {
    let invoice: Invoice
    let onSend: () -> Void
    let onSkip: () -> Void
    @Binding var showMailComposer: Bool
    @Binding var mailComposer: MFMailComposeViewController?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                invoiceSummary
                sendOptions
            }
            .padding()
            .navigationTitle("Invoice Created")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Skip") {
                        onSkip()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private var invoiceSummary: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            
            Text("Invoice \(invoice.invoiceNumber) Created")
                .font(.headline)
            
            if let client = invoice.client {
                Text("To: \(client.name)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text(invoice.total.formatted(.currency(code: "USD")))
                .font(.title)
                .fontWeight(.bold)
        }
    }
    
    private var sendOptions: some View {
        VStack(spacing: 12) {
            Button(action: sendInvoiceEmail) {
                Label("Send Invoice Now", systemImage: "paperplane.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            
            Button("Send Later") {
                onSkip()
            }
            .buttonStyle(.bordered)
        }
    }
    
    private func sendInvoiceEmail() {
        guard EmailService.shared.canSendMail() else {
            onSkip()
            return
        }
        
        let composer = EmailService.shared.sendInvoiceEmail(invoice: invoice) { result in
            switch result {
            case .success:
                onSend()
            case .failure:
                onSkip()
            }
        }
        
        if let composer = composer {
            mailComposer = composer
            showMailComposer = true
        } else {
            onSkip()
        }
    }
}
