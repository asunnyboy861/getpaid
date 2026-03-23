//
//  ClientListViewModel.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class ClientListViewModel {
    var clients: [Client] = []
    var filteredClients: [Client] = []
    var searchText: String = ""
    var isLoading: Bool = false
    
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func loadClients() {
        isLoading = true
        clients = ClientService.shared.fetchClients(context: modelContext)
        applyFilter()
        isLoading = false
    }
    
    func applyFilter() {
        if searchText.isEmpty {
            filteredClients = clients
        } else {
            filteredClients = ClientService.shared.searchClients(context: modelContext, query: searchText)
        }
    }
    
    func deleteClient(_ client: Client) {
        ClientService.shared.deleteClient(context: modelContext, client: client)
        loadClients()
    }
    
    func clientsByScore(_ score: PaymentScore) -> [Client] {
        return filteredClients.filter { $0.paymentScore == score }
    }
}
