//
//  InvoiceCreationView.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import SwiftData
import SwiftUI
import MessageUI

struct InvoiceCreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: InvoiceCreationViewModel?
    @State private var showAddClient = false
    @State private var showMailComposer = false
    @State private var mailComposer: MFMailComposeViewController?
    
    var body: some View {
        NavigationStack {
            Form {
                clientSection
                itemsSection
                paymentTermsSection
                summarySection
            }
            .navigationTitle("New Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        _ = viewModel?.createInvoiceAndPrepareSend()
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel?.canCreateInvoice == false || viewModel?.isSaving == true)
                }
            }
            .sheet(isPresented: Binding(
                get: { viewModel?.showAddItem ?? false },
                set: { viewModel?.showAddItem = $0 }
            )) {
                if let viewModel = viewModel {
                    AddItemSheet(viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showAddClient) {
                ClientCreationView()
            }
            .sheet(isPresented: Binding(
                get: { viewModel?.showSendConfirmation ?? false },
                set: { viewModel?.showSendConfirmation = $0 }
            )) {
                if let invoice = viewModel?.createdInvoice {
                    SendInvoiceConfirmationSheet(
                        invoice: invoice,
                        onSend: {
                            viewModel?.markInvoiceAsSent()
                            viewModel?.showSendConfirmation = false
                            dismiss()
                        },
                        onSkip: {
                            viewModel?.showSendConfirmation = false
                            dismiss()
                        },
                        showMailComposer: $showMailComposer,
                        mailComposer: $mailComposer
                    )
                }
            }
            .sheet(isPresented: $showMailComposer) {
                if let mailComposer = mailComposer {
                    MailComposerWrapper(mailComposer: mailComposer)
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = InvoiceCreationViewModel(modelContext: modelContext)
                }
                viewModel?.loadClients()
            }
        }
    }
    
    private var clientSection: some View {
        Section("Client") {
            if let client = viewModel?.selectedClient {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(client.name)
                            .font(.headline)
                        
                        Text(client.email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Change") {
                        viewModel?.showClientPicker = true
                    }
                    .font(.caption)
                }
            } else {
                Button(action: { showAddClient = true }) {
                    Label("Add Client", systemImage: "person.badge.plus")
                }
            }
        }
    }
    
    private var itemsSection: some View {
        Section("Items") {
            ForEach(viewModel?.items ?? []) { item in
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
                }
            }
            .onDelete { indexSet in
                indexSet.forEach { viewModel?.removeItem(at: $0) }
            }
            
            Button(action: { viewModel?.showAddItem = true }) {
                Label("Add Item", systemImage: "plus.circle")
            }
        }
    }
    
    private var paymentTermsSection: some View {
        Section("Payment Terms") {
            DatePicker(
                "Due Date",
                selection: Binding(
                    get: { viewModel?.dueDate ?? Date().addingTimeInterval(30 * 24 * 60 * 60) },
                    set: { viewModel?.dueDate = $0 }
                ),
                displayedComponents: .date
            )
            
            HStack {
                Text("Tax Rate (%)")
                Spacer()
                TextField("0", value: Binding(
                    get: { viewModel?.taxRate ?? 0 },
                    set: { viewModel?.taxRate = $0 }
                ), format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
            
            TextField("Notes", text: Binding(
                get: { viewModel?.notes ?? "" },
                set: { viewModel?.notes = $0 }
            ), axis: .vertical)
                .lineLimit(3...6)
        }
    }
    
    private var summarySection: some View {
        Section("Summary") {
            HStack {
                Text("Subtotal")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(viewModel?.formattedSubtotal ?? "$0.00")
            }
            
            if let taxRate = viewModel?.taxRate, taxRate > 0 {
                HStack {
                    Text("Tax")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(viewModel?.formattedTax ?? "$0.00")
                }
            }
            
            Divider()
            
            HStack {
                Text("Total")
                    .font(.headline)
                Spacer()
                Text(viewModel?.formattedTotal ?? "$0.00")
                    .font(.headline)
            }
        }
    }
}

struct AddItemSheet: View {
    @Bindable var viewModel: InvoiceCreationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Description", text: $viewModel.newItemDescription)
                    
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("1", value: $viewModel.newItemQuantity, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Unit Price")
                        Spacer()
                        TextField("0.00", value: $viewModel.newItemPrice, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
                
                Section("Preview") {
                    HStack {
                        Text("Item Total")
                            .foregroundStyle(.secondary)
                        Spacer()
                        let total = viewModel.newItemQuantity * viewModel.newItemPrice
                        Text(total.formatted(.currency(code: "USD")))
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        viewModel.resetNewItemForm()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        viewModel.addItem()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel.newItemDescription.isEmpty || viewModel.newItemPrice == 0)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    InvoiceCreationView()
        .modelContainer(AppContainer.shared.container)
}
