//
//  Names_generatorApp.swift
//  Names-generator
//
//  Created by Dominik Bednorz on 23/09/2026.
//

import SwiftUI
import SwiftData

@main
struct Names_generatorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: NameEntry.self)
    }
}
