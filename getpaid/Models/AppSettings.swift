//
//  AppSettings.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import Foundation
import SwiftData

@Model
final class AppSettings {
    var id: UUID
    var businessName: String
    var businessEmail: String
    var businessPhone: String
    var businessAddress: String
    var defaultTaxRate: Decimal
    var defaultPaymentTerms: Int
    var currency: String
    var hasCompletedOnboarding: Bool
    
    init(
        id: UUID = UUID(),
        businessName: String = "",
        businessEmail: String = "",
        businessPhone: String = "",
        businessAddress: String = "",
        defaultTaxRate: Decimal = 0,
        defaultPaymentTerms: Int = 30,
        currency: String = "USD",
        hasCompletedOnboarding: Bool = false
    ) {
        self.id = id
        self.businessName = businessName
        self.businessEmail = businessEmail
        self.businessPhone = businessPhone
        self.businessAddress = businessAddress
        self.defaultTaxRate = defaultTaxRate
        self.defaultPaymentTerms = defaultPaymentTerms
        self.currency = currency
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}
