//
//  ClientCreationView.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import SwiftData
import SwiftUI

struct ClientCreationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var companyName = ""
    @State private var address = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Contact Information") {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section("Business Details") {
                    TextField("Company Name", text: $companyName)
                    TextField("Address", text: $address, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveClient()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || email.isEmpty)
                }
            }
        }
    }
    
    private func saveClient() {
        _ = ClientService.shared.createClient(
            context: modelContext,
            name: name,
            email: email,
            phone: phone,
            companyName: companyName,
            address: address,
            notes: notes
        )
        
        dismiss()
    }
}

#Preview {
    ClientCreationView()
        .modelContainer(AppContainer.shared.container)
}
