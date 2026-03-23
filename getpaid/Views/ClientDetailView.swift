//
//  ClientDetailView.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import SwiftData
import SwiftUI

struct ClientDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ClientDetailViewModel?
    @State private var showDeleteConfirmation = false
    
    let client: Client
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                scoreCard
                contactCard
                statsCard
                invoicesCard
            }
            .padding()
        }
        .navigationTitle(client.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: { viewModel?.isEditing = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                        Label("Delete Client", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.isEditing ?? false },
            set: { viewModel?.isEditing = $0 }
        )) {
            if let viewModel = viewModel {
                EditClientSheet(viewModel: viewModel)
            }
        }
        .alert("Delete Client", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let viewModel = viewModel {
                    ClientService.shared.deleteClient(context: modelContext, client: viewModel.client)
                }
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this client? This will also delete all associated invoices.")
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ClientDetailViewModel(client: client, modelContext: modelContext)
            }
        }
    }
    
    private var scoreCard: some View {
        HStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(client.paymentScore.rawValue)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(viewModel?.paymentScoreColor ?? .gray)
                
                Text("Payment Score")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
            
            VStack(spacing: 8) {
                Text(client.riskLevel.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(viewModel?.riskLevelColor ?? .gray)
                
                Text("Risk Level")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var contactCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contact Information")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                if !client.companyName.isEmpty {
                    Label(client.companyName, systemImage: "building.2")
                }
                
                Label(client.email, systemImage: "envelope")
                    .foregroundStyle(.blue)
                
                if !client.phone.isEmpty {
                    Label(client.phone, systemImage: "phone")
                }
                
                if !client.address.isEmpty {
                    Label(client.address, systemImage: "location")
                }
            }
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var statsCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Outstanding")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(viewModel?.formattedTotalOutstanding ?? client.totalOutstanding.formatted(.currency(code: "USD")))
                        .font(.headline)
                        .foregroundStyle(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Paid")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(viewModel?.formattedTotalPaid ?? client.totalPaid.formatted(.currency(code: "USD")))
                        .font(.headline)
                        .foregroundStyle(.green)
                }
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pending Invoices")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("\(viewModel?.pendingInvoicesCount ?? client.invoices.filter { $0.status != .paid && $0.status != .cancelled }.count)")
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Paid Invoices")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("\(viewModel?.paidInvoicesCount ?? client.invoices.filter { $0.status == .paid }.count)")
                        .font(.headline)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var invoicesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Invoices")
                .font(.headline)
            
            if client.invoices.isEmpty {
                Text("No invoices yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(client.invoices.sorted(by: { $0.createdAt > $1.createdAt }).prefix(5)) { invoice in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(invoice.invoiceNumber)
                                .font(.subheadline)
                            
                            Text(invoice.createdAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(invoice.total.formatted(.currency(code: "USD")))
                                .font(.subheadline)
                            
                            Text(invoice.status.displayName)
                                .font(.caption)
                                .foregroundStyle(statusColor(for: invoice.status))
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func statusColor(for status: InvoiceStatus) -> Color {
        switch status {
        case .draft, .cancelled: return .gray
        case .sent, .viewed: return .blue
        case .overdue1to7, .overdue8to30: return .orange
        case .overdue30plus: return .red
        case .paid: return .green
        }
    }
}

struct EditClientSheet: View {
    @Bindable var viewModel: ClientDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Contact Information") {
                    TextField("Name", text: $viewModel.editedName)
                    TextField("Email", text: $viewModel.editedEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Phone", text: $viewModel.editedPhone)
                        .keyboardType(.phonePad)
                }
                
                Section("Business Details") {
                    TextField("Company Name", text: $viewModel.editedCompanyName)
                    TextField("Address", text: $viewModel.editedAddress, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Notes") {
                    TextField("Notes", text: $viewModel.editedNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        viewModel.cancelEditing()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        viewModel.saveChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Client.self, Invoice.self, configurations: config)
    
    let client = Client(name: "Test Client", email: "test@example.com")
    
    return ClientDetailView(client: client)
        .modelContainer(container)
}
