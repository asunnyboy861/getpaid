//
//  InvoiceDetailView.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import SwiftData
import SwiftUI
import PDFKit
import MessageUI

struct InvoiceDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: InvoiceDetailViewModel?
    @State private var showPDFPreview = false
    @State private var showMarkPaidSheet = false
    @State private var showDeleteConfirmation = false
    @State private var showMailComposer = false
    @State private var mailComposer: MFMailComposeViewController?
    @State private var showMailError = false
    @State private var mailErrorMessage = ""
    
    let invoice: Invoice
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                statusCard
                clientInfoCard
                lineItemsCard
                totalsCard
                actionsCard
            }
            .padding()
        }
        .navigationTitle(invoice.invoiceNumber)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if invoice.status == .draft {
                        NavigationLink(destination: InvoiceEditView(invoice: invoice)) {
                            Label("Edit Invoice", systemImage: "pencil")
                        }
                    }
                    
                    Button(action: { showPDFPreview = true }) {
                        Label("View PDF", systemImage: "doc.fill")
                    }
                    
                    Button(action: { showMarkPaidSheet = true }) {
                        Label("Mark as Paid", systemImage: "checkmark.circle")
                    }
                    
                    Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                        Label("Delete Invoice", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showPDFPreview) {
            if let pdfData = viewModel?.pdfData {
                PDFPreviewView(pdfData: pdfData)
            }
        }
        .sheet(isPresented: $showMarkPaidSheet) {
            if let viewModel = viewModel {
                MarkPaidSheet(viewModel: viewModel, isPresented: $showMarkPaidSheet)
            }
        }
        .sheet(isPresented: $showMailComposer) {
            if let mailComposer = mailComposer {
                MailComposerWrapper(mailComposer: mailComposer)
            }
        }
        .alert("Mail Error", isPresented: $showMailError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(mailErrorMessage)
        }
        .alert("Delete Invoice", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel?.cancelInvoice()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this invoice?")
        }
        .onAppear {
            if viewModel == nil {
                viewModel = InvoiceDetailViewModel(invoice: invoice, modelContext: modelContext)
            }
            viewModel?.generatePDF(settings: nil)
        }
    }
    
    private var statusCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Status")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(invoice.status.displayName)
                        .font(.headline)
                        .foregroundStyle(viewModel?.statusColor ?? .gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Escalation Level")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(viewModel?.escalationLevelText ?? invoice.escalationLevel.displayName)
                        .font(.subheadline)
                }
            }
            
            if invoice.isOverdue {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    
                    Text("\(invoice.daysOverdue) days overdue")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var clientInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Client")
                .font(.headline)
            
            if let client = invoice.client {
                VStack(alignment: .leading, spacing: 4) {
                    Text(client.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if !client.companyName.isEmpty {
                        Text(client.companyName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(client.email)
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var lineItemsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Items")
                .font(.headline)
            
            ForEach(invoice.items) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.itemDescription)
                            .font(.subheadline)
                        
                        Text("\(item.quantity) × \(item.unitPrice.formatted(.currency(code: "USD")))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(item.total.formatted(.currency(code: "USD")))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var totalsCard: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Subtotal")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(viewModel?.formattedSubtotal ?? invoice.subtotal.formatted(.currency(code: "USD")))
            }
            
            if invoice.taxRate > 0 {
                HStack {
                    Text("Tax (\(invoice.taxRate)%)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(viewModel?.formattedTax ?? (invoice.subtotal * invoice.taxRate / 100).formatted(.currency(code: "USD")))
                }
            }
            
            Divider()
            
            HStack {
                Text("Total")
                    .font(.headline)
                Spacer()
                Text(viewModel?.formattedTotal ?? invoice.total.formatted(.currency(code: "USD")))
                    .font(.headline)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var actionsCard: some View {
        VStack(spacing: 12) {
            Button(action: { showPDFPreview = true }) {
                Label("View PDF", systemImage: "doc.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button(action: sendReminderEmail) {
                if viewModel?.isSendingReminder == true {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Label("Send Reminder", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.bordered)
            .disabled(viewModel?.isSendingReminder == true)
            
            Button(action: { showMarkPaidSheet = true }) {
                Label("Mark as Paid", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func sendReminderEmail() {
        viewModel?.isSendingReminder = true
        
        let composer = EmailService.shared.sendReminderEmail(
            invoice: invoice,
            escalationLevel: invoice.escalationLevel
        ) { result in
            viewModel?.isSendingReminder = false
            
            switch result {
            case .success:
                viewModel?.updateLastReminderSent()
            case .failure(let error):
                mailErrorMessage = error.errorDescription ?? "Unknown error"
                showMailError = true
            }
        }
        
        if let composer = composer {
            mailComposer = composer
            showMailComposer = true
        } else {
            viewModel?.isSendingReminder = false
            mailErrorMessage = "Please configure an email account in Settings to send emails."
            showMailError = true
        }
    }
}

struct MarkPaidSheet: View {
    @Bindable var viewModel: InvoiceDetailViewModel
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Payment Details") {
                    DatePicker(
                        "Payment Date",
                        selection: $viewModel.paymentDate,
                        displayedComponents: .date
                    )
                    
                    HStack {
                        Text("Amount")
                        Spacer()
                        Text(viewModel.formattedTotal)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Mark as Paid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        viewModel.markAsPaid()
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct PDFPreviewView: View {
    let pdfData: Data
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if let pdfDocument = PDFDocument(data: pdfData) {
                    PDFKitView(document: pdfDocument)
                } else {
                    ContentUnavailableView(
                        "PDF Unavailable",
                        systemImage: "doc.fill",
                        description: Text("Could not generate PDF preview")
                    )
                }
            }
            .navigationTitle("Invoice PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = document
    }
}

struct MailComposerWrapper: UIViewControllerRepresentable {
    let mailComposer: MFMailComposeViewController
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        return mailComposer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Invoice.self, Client.self, configurations: config)
    
    let client = Client(name: "Test Client", email: "test@example.com")
    let invoice = Invoice(invoiceNumber: "INV-001", client: client)
    
    return InvoiceDetailView(invoice: invoice)
        .modelContainer(container)
}
