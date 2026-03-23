//
//  ClientListView.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import SwiftData
import SwiftUI

struct ClientListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ClientListViewModel?
    @State private var showAddClient = false
    @State private var selectedClient: Client?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                clientList
            }
            .navigationTitle("Clients")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddClient = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddClient) {
                ClientCreationView()
            }
            .navigationDestination(item: $selectedClient) { client in
                ClientDetailView(client: client)
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = ClientListViewModel(modelContext: modelContext)
                }
                viewModel?.loadClients()
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search clients...", text: Binding(
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
    
    private var clientList: some View {
        Group {
            if viewModel?.isLoading == true {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let clients = viewModel?.filteredClients, clients.isEmpty {
                ContentUnavailableView(
                    "No Clients",
                    systemImage: "person.2",
                    description: Text("Add your first client to get started")
                )
            } else {
                List {
                    ForEach(viewModel?.filteredClients ?? []) { client in
                        ClientListRow(client: client)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedClient = client
                            }
                    }
                    .onDelete { indexSet in
                        guard let clients = viewModel?.filteredClients else { return }
                        for index in indexSet {
                            viewModel?.deleteClient(clients[index])
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}

struct ClientListRow: View {
    let client: Client
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(scoreColor.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay {
                    Text(client.paymentScore.rawValue)
                        .font(.headline)
                        .foregroundStyle(scoreColor)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(client.name)
                    .font(.headline)
                
                if !client.companyName.isEmpty {
                    Text(client.companyName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(client.totalOutstanding.formatted(.currency(code: "USD")))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(client.riskLevel.displayName)
                    .font(.caption)
                    .foregroundStyle(riskColor)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var scoreColor: Color {
        switch client.paymentScore {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
    
    private var riskColor: Color {
        switch client.riskLevel {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

#Preview {
    ClientListView()
        .modelContainer(AppContainer.shared.container)
}
