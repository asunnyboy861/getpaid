//
//  InvoiceEditView.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/20.
//

import SwiftData
import SwiftUI

struct InvoiceEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let invoice: Invoice
    
    @State private var viewModel: InvoiceEditViewModel?
    
    var body: some View {
        NavigationStack {
            Form {
                clientSection
                itemsSection
                paymentTermsSection
                summarySection
            }
            .navigationTitle("Edit Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        viewModel?.saveChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(viewModel?.hasChanges == false)
                }
            }
            .sheet(isPresented: Binding(
                get: { viewModel?.showAddItem ?? false },
                set: { viewModel?.showAddItem = $0 }
            )) {
                if let viewModel = viewModel {
                    EditAddItemSheet(viewModel: viewModel)
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = InvoiceEditViewModel(invoice: invoice, modelContext: modelContext)
                }
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
                    
                    Text("Cannot change")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
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
                    get: { viewModel?.dueDate ?? Date() },
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

struct EditAddItemSheet: View {
    @Bindable var viewModel: InvoiceEditViewModel
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
