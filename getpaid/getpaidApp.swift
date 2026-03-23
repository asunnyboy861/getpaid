//
//  getpaidApp.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct getpaidApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var storeManager = StoreManager.shared
    @State private var showOnboarding = false
    @State private var isLoading = true

    init() {
        setupAppearance()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isLoading {
                    ProgressView()
                } else {
                    MainTabView()
                        .fullScreenCover(isPresented: $showOnboarding) {
                            OnboardingView(isPresented: $showOnboarding)
                        }
                }
            }
            .modelContainer(AppContainer.shared.container)
            .task {
                await initializeApp()
            }
        }
    }

    private func initializeApp() async {
        let context = AppContainer.shared.mainContext

        EmailService.shared.configure(with: context)

        let settings = getOrCreateSettings(context: context)
        showOnboarding = !settings.hasCompletedOnboarding

        let granted = await EscalationService.shared.requestNotificationPermission()
        if granted {
            print("Notification permission granted")
        }

        EscalationService.shared.updateInvoiceStatuses(context: context)

        await storeManager.loadProducts()

        isLoading = false
        print("App initialization complete")
    }

    private func getOrCreateSettings(context: ModelContext) -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        
        do {
            let settings = try context.fetch(descriptor)
            if let existing = settings.first {
                return existing
            }
        } catch {}
        
        let newSettings = AppSettings()
        context.insert(newSettings)
        return newSettings
    }

    private func setupAppearance() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()

        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        Task {
            _ = await EscalationService.shared.requestNotificationPermission()
        }
        
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Task {
            let context = AppContainer.shared.container.mainContext
            
            await EscalationService.shared.processDueReminders(context: context)
            EscalationService.shared.updateInvoiceStatuses(context: context)
            
            completionHandler(.newData)
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let invoiceIdString = userInfo["invoiceId"] as? String,
           let invoiceId = UUID(uuidString: invoiceIdString) {
            print("Tapped notification for invoice: \(invoiceId)")
        }
        
        completionHandler()
    }
}
