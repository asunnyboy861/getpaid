//
//  OnboardingViewModel.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/20.
//

import Foundation
import SwiftData

@MainActor
@Observable
final class OnboardingViewModel {
    var businessName: String = ""
    var businessEmail: String = ""
    var businessPhone: String = ""
    
    var clientName: String = ""
    var clientEmail: String = ""
    var clientCompany: String = ""
    
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func completeOnboarding() {
        let settings = getOrCreateSettings()
        settings.businessName = businessName
        settings.businessEmail = businessEmail
        settings.businessPhone = businessPhone
        settings.hasCompletedOnboarding = true
        
        if !clientName.isEmpty && !clientEmail.isEmpty {
            _ = ClientService.shared.createClient(
                context: modelContext,
                name: clientName,
                email: clientEmail,
                companyName: clientCompany
            )
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to complete onboarding: \(error)")
        }
    }
    
    func skipClientCreation() {
        let settings = getOrCreateSettings()
        settings.businessName = businessName
        settings.businessEmail = businessEmail
        settings.businessPhone = businessPhone
        settings.hasCompletedOnboarding = true
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
    
    private func getOrCreateSettings() -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        
        do {
            let settings = try modelContext.fetch(descriptor)
            if let existing = settings.first {
                return existing
            }
        } catch {}
        
        let newSettings = AppSettings()
        modelContext.insert(newSettings)
        return newSettings
    }
}
