//
//  SettingsView.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import SwiftData
import StoreKit
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: SettingsViewModel?
    @State private var storeManager = StoreManager.shared
    @State private var showContactSupport: Bool = false
    
    var body: some View {
        NavigationStack {
            List {
                subscriptionStatusSection
                subscriptionPlansSection
                businessSection
                invoiceDefaultsSection
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: Binding(
                get: { viewModel?.isEditing ?? false },
                set: { viewModel?.isEditing = $0 }
            )) {
                if let viewModel = viewModel {
                    EditSettingsSheet(viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showContactSupport) {
                ContactSupportView()
            }
            .alert("Purchase Error", isPresented: Binding(
                get: { storeManager.errorMessage != nil },
                set: { if !$0 { storeManager.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(storeManager.errorMessage ?? "")
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = SettingsViewModel(modelContext: modelContext)
                }
                viewModel?.loadSettings()
                Task {
                    await storeManager.loadProducts()
                }
            }
        }
    }
    
    private var subscriptionStatusSection: some View {
        Section("Current Plan") {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(storeManager.subscriptionTier.displayName)
                        .font(.headline)
                    
                    if storeManager.isSubscribed {
                        Text("Active")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Text("Limited features")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if let subscription = storeManager.currentSubscription {
                    Text(subscription.displayPrice)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            if storeManager.isSubscribed {
                Button {
                    Task {
                        try? await storeManager.restorePurchases()
                    }
                } label: {
                    Label("Manage Subscription", systemImage: "gear")
                }
            }
        }
    }
    
    private var subscriptionPlansSection: some View {
        Section("Upgrade Plan") {
            if storeManager.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if storeManager.products.isEmpty {
                Text("Loading subscriptions...")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(SubscriptionTier.allCases.filter { $0 != .free }, id: \.self) { tier in
                    SubscriptionTierRow(
                        tier: tier,
                        monthlyProduct: storeManager.product(for: tier, period: .monthly),
                        yearlyProduct: storeManager.product(for: tier, period: .yearly),
                        currentTier: storeManager.subscriptionTier,
                        isPurchasing: storeManager.isLoading
                    ) { product in
                        Task {
                            do {
                                _ = try await storeManager.purchase(product)
                            } catch {
                                storeManager.errorMessage = error.localizedDescription
                            }
                        }
                    }
                }
            }
            
            Button {
                Task {
                    try? await storeManager.restorePurchases()
                }
            } label: {
                Label("Restore Purchases", systemImage: "arrow.clockwise")
            }
        }
    }
    
    private var businessSection: some View {
        Section("Business Information") {
            if let settings = viewModel?.settings {
                LabeledContent("Business Name", value: settings.businessName.isEmpty ? "Not set" : settings.businessName)
                LabeledContent("Email", value: settings.businessEmail.isEmpty ? "Not set" : settings.businessEmail)
                LabeledContent("Phone", value: settings.businessPhone.isEmpty ? "Not set" : settings.businessPhone)
            }
            
            Button("Edit Business Information") {
                viewModel?.isEditing = true
            }
        }
    }
    
    private var invoiceDefaultsSection: some View {
        Section("Invoice Defaults") {
            if let settings = viewModel?.settings {
                LabeledContent("Default Tax Rate", value: "\(settings.defaultTaxRate)%")
                LabeledContent("Payment Terms", value: "\(settings.defaultPaymentTerms) days")
            }
            
            Button("Edit Invoice Defaults") {
                viewModel?.isEditing = true
            }
        }
    }
    
    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: "1.0.0")
            
            Link(destination: URL(string: "https://getpaid.app/privacy")!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            
            Link(destination: URL(string: "https://getpaid.app/terms")!) {
                Label("Terms of Service", systemImage: "doc.text")
            }
            
            Button {
                showContactSupport = true
            } label: {
                Label("Contact Support", systemImage: "envelope")
            }
        }
    }
}

struct SubscriptionTierRow: View {
    let tier: SubscriptionTier
    let monthlyProduct: Product?
    let yearlyProduct: Product?
    let currentTier: SubscriptionTier
    let isPurchasing: Bool
    let onPurchase: (Product) -> Void
    
    @State private var selectedPeriod: SubscriptionPeriod = .yearly
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tier.displayName)
                        .font(.headline)
                    
                    Text(tierFeatures)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if currentTier >= tier {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            
            Picker("Billing Period", selection: $selectedPeriod) {
                Text("Monthly").tag(SubscriptionPeriod.monthly)
                Text("Yearly (Save 40%)").tag(SubscriptionPeriod.yearly)
            }
            .pickerStyle(.segmented)
            .font(.caption)
            
            if let product = selectedPeriod == .monthly ? monthlyProduct : yearlyProduct {
                Button {
                    onPurchase(product)
                } label: {
                    HStack {
                        Text("Subscribe for \(product.displayPrice)")
                            .fontWeight(.semibold)
                        
                        if selectedPeriod == .yearly, let monthly = monthlyProduct {
                            Text("(\(savingsPercentage(from: monthly, to: product))% off)")
                                .font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isPurchasing || currentTier >= tier)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var tierFeatures: String {
        switch tier {
        case .free:
            return "5 invoices, 10 clients"
        case .pro:
            return "100 invoices, 100 clients, automated reminders"
        case .business:
            return "Unlimited everything, team features, analytics"
        }
    }
    
    private func savingsPercentage(from monthly: Product, to yearly: Product) -> Int {
        let monthlyYearlyCost = Double(truncating: (monthly.price * 12) as NSDecimalNumber)
        let yearlyCost = Double(truncating: yearly.price as NSDecimalNumber)
        let savings = monthlyYearlyCost - yearlyCost
        let percentage = (savings / monthlyYearlyCost) * 100
        return Int(percentage)
    }
}

struct ProductRow: View {
    let product: Product
    let isCurrentPlan: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.displayName)
                    .font(.headline)
                
                Text(product.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isCurrentPlan {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button(action: onPurchase) {
                    Text(product.displayPrice)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

struct EditSettingsSheet: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Business Information") {
                    TextField("Business Name", text: $viewModel.editedBusinessName)
                    TextField("Email", text: $viewModel.editedBusinessEmail)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Phone", text: $viewModel.editedBusinessPhone)
                        .keyboardType(.phonePad)
                    TextField("Address", text: $viewModel.editedBusinessAddress, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Invoice Defaults") {
                    HStack {
                        Text("Default Tax Rate (%)")
                        Spacer()
                        TextField("0", text: $viewModel.editedDefaultTaxRate)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    
                    HStack {
                        Text("Payment Terms (days)")
                        Spacer()
                        TextField("30", text: $viewModel.editedDefaultPaymentTerms)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
            }
            .navigationTitle("Edit Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        viewModel.cancelEditing()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        viewModel.saveChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    SettingsView()
        .modelContainer(AppContainer.shared.container)
}
