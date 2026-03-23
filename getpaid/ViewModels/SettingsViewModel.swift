//
//  SettingsViewModel.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class SettingsViewModel {
    var settings: AppSettings?
    var isEditing: Bool = false
    var editedBusinessName: String = ""
    var editedBusinessEmail: String = ""
    var editedBusinessPhone: String = ""
    var editedBusinessAddress: String = ""
    var editedDefaultTaxRate: String = ""
    var editedDefaultPaymentTerms: String = ""
    
    var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func loadSettings() {
        let descriptor = FetchDescriptor<AppSettings>()
        
        do {
            if let existingSettings = try modelContext.fetch(descriptor).first {
                settings = existingSettings
                populateEditFields()
            } else {
                let newSettings = AppSettings()
                modelContext.insert(newSettings)
                settings = newSettings
                populateEditFields()
            }
        } catch {
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            settings = newSettings
            populateEditFields()
        }
    }
    
    func populateEditFields() {
        guard let settings = settings else { return }
        editedBusinessName = settings.businessName
        editedBusinessEmail = settings.businessEmail
        editedBusinessPhone = settings.businessPhone
        editedBusinessAddress = settings.businessAddress
        editedDefaultTaxRate = settings.defaultTaxRate.description
        editedDefaultPaymentTerms = settings.defaultPaymentTerms.description
    }
    
    func saveChanges() {
        guard let settings = settings else { return }
        
        settings.businessName = editedBusinessName
        settings.businessEmail = editedBusinessEmail
        settings.businessPhone = editedBusinessPhone
        settings.businessAddress = editedBusinessAddress
        settings.defaultTaxRate = Decimal(string: editedDefaultTaxRate) ?? 0
        settings.defaultPaymentTerms = Int(editedDefaultPaymentTerms) ?? 30
        
        isEditing = false
    }
    
    func cancelEditing() {
        populateEditFields()
        isEditing = false
    }
}
