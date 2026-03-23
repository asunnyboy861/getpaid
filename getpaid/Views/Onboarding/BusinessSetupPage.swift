//
//  BusinessSetupPage.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/20.
//

import SwiftUI

struct BusinessSetupPage: View {
    @Binding var businessName: String
    @Binding var businessEmail: String
    @Binding var businessPhone: String
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Step 1 of 2")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("Your Business Info")
                    .font(.title)
                    .fontWeight(.bold)
            }
            .padding(.top, 60)
            
            Form {
                Section("Business Details") {
                    TextField("Business Name", text: $businessName)
                    
                    TextField("Email", text: $businessEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    
                    TextField("Phone (Optional)", text: $businessPhone)
                        .keyboardType(.phonePad)
                }
            }
            .frame(height: 280)
            
            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
}
