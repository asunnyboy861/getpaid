//
//  WelcomePage.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/20.
//

import SwiftUI

struct WelcomePage: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            
            VStack(spacing: 12) {
                Text("Welcome to GetPaid")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Stop chasing, start collecting.\nAutomate your invoice recovery process.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            Button(action: onContinue) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
            
            Spacer()
                .frame(height: 40)
        }
        .padding()
    }
}
