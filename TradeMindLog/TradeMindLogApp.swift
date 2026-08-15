//
//  TradeMindLogApp.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/05/13.
//

import SwiftUI
import SwiftData
import GoogleMobileAds

@main
struct TradeMindLogApp: App {
    @AppStorage("colorScheme") var colorScheme = 0
    
    init() {
        // Initialize the Mobile Ads SDK
        MobileAds.shared.start(completionHandler: nil)
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(
                    colorScheme == 1 ? .light :
                    colorScheme == 2 ? .dark : nil
                )
                .modelContainer(for: Record.self)
        }
    }
}
