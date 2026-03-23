//
//  InvoiceListView.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import SwiftData
import SwiftUI

struct InvoiceListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: InvoiceListViewModel?
    @State private var showCreateInvoice = false
    @State private var selectedInvoice: Invoice?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                filterTabs
                invoiceList
            }
            .navigationTitle("Invoices")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showCreateInvoice = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateInvoice) {
                InvoiceCreationView()
            }
            .navigationDestination(item: $selectedInvoice) { invoice in
                InvoiceDetailView(invoice: invoice)
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = InvoiceListViewModel(modelContext: modelContext)
                }
                viewModel?.loadInvoices()
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search invoices...", text: Binding(
                get: { viewModel?.searchText ?? "" },
                set: { viewModel?.searchText = $0 }
            ))
            .textFieldStyle(.plain)
            .onChange(of: viewModel?.searchText ?? "") {
                viewModel?.applyFilter()
            }
            
            if let text = viewModel?.searchText, !text.isEmpty {
                Button(action: { viewModel?.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterTab(title: "All", count: viewModel?.invoices.count ?? 0, isSelected: viewModel?.selectedStatus == nil) {
                    viewModel?.filterByStatus(nil)
                }
                
                FilterTab(title: "Draft", count: viewModel?.draftCount ?? 0, isSelected: viewModel?.selectedStatus == .draft) {
                    viewModel?.filterByStatus(.draft)
                }
                
                FilterTab(title: "Sent", count: viewModel?.sentCount ?? 0, isSelected: viewModel?.selectedStatus == .sent) {
                    viewModel?.filterByStatus(.sent)
                }
                
                FilterTab(title: "Overdue", count: viewModel?.overdueCount ?? 0, isSelected: viewModel?.selectedStatus?.isOverdue == true) {
                    viewModel?.filterByStatus(.overdue1to7)
                }
                
                FilterTab(title: "Paid", count: viewModel?.paidCount ?? 0, isSelected: viewModel?.selectedStatus == .paid) {
                    viewModel?.filterByStatus(.paid)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
    }
    
    private var invoiceList: some View {
        Group {
            if viewModel?.isLoading == true {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let invoices = viewModel?.filteredInvoices, invoices.isEmpty {
                ContentUnavailableView(
                    "No Invoices",
                    systemImage: "doc.text",
                    description: Text("Create your first invoice to get started")
                )
            } else {
                List {
                    ForEach(viewModel?.filteredInvoices ?? []) { invoice in
                        InvoiceListRow(invoice: invoice)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedInvoice = invoice
                            }
                    }
                    .onDelete { indexSet in
                        guard let invoices = viewModel?.filteredInvoices else { return }
                        for index in indexSet {
                            viewModel?.deleteInvoice(invoices[index])
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

struct FilterTab: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                
                if count > 0 {
                    Text("(\(count))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

struct InvoiceListRow: View {
    let invoice: Invoice
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(invoice.invoiceNumber)
                    .font(.headline)
                
                Text(invoice.client?.name ?? "Unknown Client")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(invoice.total.formatted(.currency(code: "USD")))
                    .font(.headline)
                
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(statusColor)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch invoice.status {
        case .draft: return .gray
        case .sent, .viewed: return .blue
        case .overdue1to7: return .orange
        case .overdue8to30: return .orange
        case .overdue30plus: return .red
        case .paid: return .green
        case .cancelled: return .gray
        }
    }
    
    private var statusText: String {
        switch invoice.status {
        case .draft: return "Draft"
        case .sent: return "Sent"
        case .viewed: return "Viewed"
        case .overdue1to7: return "\(invoice.daysOverdue) days overdue"
        case .overdue8to30: return "\(invoice.daysOverdue) days overdue"
        case .overdue30plus: return "\(invoice.daysOverdue) days overdue"
        case .paid: return "Paid"
        case .cancelled: return "Cancelled"
        }
    }
}

#Preview {
    InvoiceListView()
        .modelContainer(AppContainer.shared.container)
}
