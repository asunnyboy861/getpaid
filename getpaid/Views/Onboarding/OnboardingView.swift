//
//  OnboardingView.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/20.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var currentPage = 0
    @State private var viewModel: OnboardingViewModel?
    @Binding var isPresented: Bool
    
    var body: some View {
        TabView(selection: $currentPage) {
            WelcomePage {
                currentPage = 1
            }
            .tag(0)
            
            BusinessSetupPage(
                businessName: Binding(
                    get: { viewModel?.businessName ?? "" },
                    set: { viewModel?.businessName = $0 }
                ),
                businessEmail: Binding(
                    get: { viewModel?.businessEmail ?? "" },
                    set: { viewModel?.businessEmail = $0 }
                ),
                businessPhone: Binding(
                    get: { viewModel?.businessPhone ?? "" },
                    set: { viewModel?.businessPhone = $0 }
                ),
                onContinue: {
                    currentPage = 2
                }
            )
            .tag(1)
            
            FirstClientPage(
                clientName: Binding(
                    get: { viewModel?.clientName ?? "" },
                    set: { viewModel?.clientName = $0 }
                ),
                clientEmail: Binding(
                    get: { viewModel?.clientEmail ?? "" },
                    set: { viewModel?.clientEmail = $0 }
                ),
                clientCompany: Binding(
                    get: { viewModel?.clientCompany ?? "" },
                    set: { viewModel?.clientCompany = $0 }
                ),
                onComplete: {
                    completeOnboarding()
                },
                onSkip: {
                    skipClientAndComplete()
                }
            )
            .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .ignoresSafeArea()
        .onAppear {
            if viewModel == nil {
                viewModel = OnboardingViewModel(modelContext: modelContext)
            }
        }
    }
    
    private func completeOnboarding() {
        viewModel?.completeOnboarding()
        isPresented = false
    }
    
    private func skipClientAndComplete() {
        viewModel?.skipClientCreation()
        isPresented = false
    }
}
