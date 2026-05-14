//
//  TradeMindLogApp.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/05/13.
//

import SwiftUI
import SwiftData

@main
struct TradeMindLogApp: App {
    @AppStorage("colorScheme") var colorScheme = 0
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(
                    colorScheme == 1 ? .light :
                    colorScheme == 2 ? .dark : nil
                )
                .modelContainer(for: Record.self)
        }
    }
}
