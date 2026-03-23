//
//  StoreManager.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import Foundation
import StoreKit
import SwiftUI

@MainActor
@Observable
final class StoreManager {
    static let shared = StoreManager()
    
    var products: [Product] = []
    var purchasedSubscriptions: [Product] = []
    var currentSubscription: Product?
    var isLoading: Bool = false
    var errorMessage: String?
    
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        updateListenerTask = Task {
            await listenForTransactions()
        }
    }
    
    private func listenForTransactions() async {
        for await result in StoreKit.Transaction.updates {
            do {
                let transaction = try checkVerified(result)
                
                await updateSubscriptionStatus()
                
                await transaction.finish()
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }
    }
    
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let storeProducts = try await Product.products(for: [
                ProductID.proMonthly,
                ProductID.proYearly,
                ProductID.businessMonthly,
                ProductID.businessYearly
            ])
            
            products = storeProducts.sorted { $0.price < $1.price }
            
            await updateSubscriptionStatus()
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("Failed to load products: \(error)")
        }
    }
    
    func updateSubscriptionStatus() async {
        var activeSubscriptions: [Product] = []
        
        for await result in StoreKit.Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if let product = products.first(where: { $0.id == transaction.productID }) {
                    activeSubscriptions.append(product)
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        purchasedSubscriptions = activeSubscriptions
        
        currentSubscription = activeSubscriptions.first
    }
    
    func purchase(_ product: Product) async throws -> StoreKit.Transaction? {
        isLoading = true
        defer { isLoading = false }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            
            await updateSubscriptionStatus()
            
            await transaction.finish()
            
            return transaction
            
        case .userCancelled:
            throw StoreError.purchaseCancelled
            
        case .pending:
            throw StoreError.purchasePending
            
        @unknown default:
            throw StoreError.unknown
        }
    }
    
    func restorePurchases() async throws {
        try await AppStore.sync()
        await updateSubscriptionStatus()
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    var isSubscribed: Bool {
        return !purchasedSubscriptions.isEmpty
    }
    
    var subscriptionTier: SubscriptionTier {
        guard let subscription = currentSubscription else {
            return .free
        }
        
        switch subscription.id {
        case ProductID.proMonthly, ProductID.proYearly:
            return .pro
        case ProductID.businessMonthly, ProductID.businessYearly:
            return .business
        default:
            return .free
        }
    }
    
    func product(for tier: SubscriptionTier, period: SubscriptionPeriod) -> Product? {
        return products.first { product in
            switch (tier, period) {
            case (.pro, .monthly):
                return product.id == ProductID.proMonthly
            case (.pro, .yearly):
                return product.id == ProductID.proYearly
            case (.business, .monthly):
                return product.id == ProductID.businessMonthly
            case (.business, .yearly):
                return product.id == ProductID.businessYearly
            case (.free, _):
                return false
            }
        }
    }
}

enum ProductID {
    static let proMonthly = "getpaid_pro_monthly"
    static let proYearly = "getpaid_pro_yearly"
    static let businessMonthly = "getpaid_business_monthly"
    static let businessYearly = "getpaid_business_yearly"
    
    static let all: Set<String> = [
        proMonthly,
        proYearly,
        businessMonthly,
        businessYearly
    ]
}

enum SubscriptionTier: Int, Comparable, CaseIterable {
    case free = 0
    case pro = 1
    case business = 2
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .business: return "Business"
        }
    }
    
    var maxInvoices: Int {
        switch self {
        case .free: return 5
        case .pro: return 100
        case .business: return .max
        }
    }
    
    var maxClients: Int {
        switch self {
        case .free: return 10
        case .pro: return 100
        case .business: return .max
        }
    }
    
    var hasAutomation: Bool {
        return self != .free
    }
    
    var hasAnalytics: Bool {
        return self == .business
    }
    
    var hasTeamFeatures: Bool {
        return self == .business
    }
    
    static func < (lhs: SubscriptionTier, rhs: SubscriptionTier) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

enum SubscriptionPeriod {
    case monthly
    case yearly
}

enum StoreError: LocalizedError {
    case purchaseCancelled
    case purchasePending
    case verificationFailed
    case productNotFound
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .purchaseCancelled:
            return "Purchase was cancelled"
        case .purchasePending:
            return "Purchase is pending approval"
        case .verificationFailed:
            return "Transaction verification failed"
        case .productNotFound:
            return "Product not found"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
