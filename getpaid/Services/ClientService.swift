//
//  ClientService.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import Foundation
import SwiftData

@MainActor
final class ClientService {
    static let shared = ClientService()
    
    private init() {}
    
    func createClient(
        context: ModelContext,
        name: String,
        email: String,
        phone: String = "",
        companyName: String = "",
        address: String = "",
        notes: String = ""
    ) -> Client? {
        let client = Client(
            name: name,
            email: email,
            phone: phone,
            companyName: companyName,
            address: address,
            notes: notes
        )

        context.insert(client)

        do {
            try context.save()
            return client
        } catch {
            print("Failed to save client: \(error)")
            return nil
        }
    }
    
    func updateClient(
        client: Client,
        name: String? = nil,
        email: String? = nil,
        phone: String? = nil,
        companyName: String? = nil,
        address: String? = nil,
        notes: String? = nil
    ) {
        if let name = name { client.name = name }
        if let email = email { client.email = email }
        if let phone = phone { client.phone = phone }
        if let companyName = companyName { client.companyName = companyName }
        if let address = address { client.address = address }
        if let notes = notes { client.notes = notes }
    }
    
    func deleteClient(context: ModelContext, client: Client) {
        context.delete(client)
    }
    
    func fetchClients(context: ModelContext) -> [Client] {
        let descriptor = FetchDescriptor<Client>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            return []
        }
    }
    
    func searchClients(context: ModelContext, query: String) -> [Client] {
        guard !query.isEmpty else { return fetchClients(context: context) }
        
        let descriptor = FetchDescriptor<Client>(
            predicate: #Predicate { client in
                client.name.localizedStandardContains(query) ||
                client.email.localizedStandardContains(query) ||
                client.companyName.localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            return []
        }
    }
    
    func fetchClientById(context: ModelContext, id: UUID) -> Client? {
        let descriptor = FetchDescriptor<Client>(
            predicate: #Predicate { $0.id == id }
        )
        
        do {
            return try context.fetch(descriptor).first
        } catch {
            return nil
        }
    }
    
    func fetchHighRiskClients(context: ModelContext) -> [Client] {
        let clients = fetchClients(context: context)
        return clients.filter { client in
            client.riskLevel == .high || client.riskLevel == .critical
        }
    }
}
