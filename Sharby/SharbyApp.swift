//
//  SharbyApp.swift
//  Sharby
//
//  Created by Larry Brewer on 1/16/24.
//

import SwiftUI
import SwiftData

@main
struct SharbyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Coin.self,
            Network.self,
            Pool.self,
            Exchange.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .modelContainer(sharedModelContainer)

      
    }
}
