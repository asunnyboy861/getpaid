//
//  MainTabView.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            InvoiceListView()
                .tabItem {
                    Label("Invoices", systemImage: "doc.text.fill")
                }
                .tag(1)
            
            ClientListView()
                .tabItem {
                    Label("Clients", systemImage: "person.2.fill")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.blue)
    }
}

#Preview {
    MainTabView()
        .modelContainer(AppContainer.shared.container)
}
