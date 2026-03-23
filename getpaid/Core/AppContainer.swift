//
//  AppContainer.swift
//  getpaid
//
//  Created by MacMini4 on 2026/3/16.
//

import Foundation
import SwiftData

@MainActor
final class AppContainer {
    static let shared = AppContainer()

    let container: ModelContainer

    var mainContext: ModelContext {
        return container.mainContext
    }

    private init() {
        let schema = Schema([
            Invoice.self,
            Client.self,
            AppSettings.self,
            EmailTemplate.self,
            ReminderSchedule.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            container = try ModelContainer(
                for: schema,
                configurations: modelConfiguration
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
}
