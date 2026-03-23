//
//  FirstClientPage.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/20.
//

import SwiftUI

struct FirstClientPage: View {
    @Binding var clientName: String
    @Binding var clientEmail: String
    @Binding var clientCompany: String
    let onComplete: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Step 2 of 2")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("Add Your First Client")
                    .font(.title)
                    .fontWeight(.bold)
            }
            .padding(.top, 60)
            
            Form {
                Section("Client Details") {
                    TextField("Client Name", text: $clientName)
                    
                    TextField("Email", text: $clientEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    
                    TextField("Company (Optional)", text: $clientCompany)
                }
            }
            .frame(height: 280)
            
            Button(action: onComplete) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            
            Button("Skip for Now") {
                onSkip()
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding()
    }
}
