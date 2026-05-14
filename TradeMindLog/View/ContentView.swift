//
//  ContentView.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/05/13.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            ListView()
                .tabItem {
                    Label("List", systemImage: "list.bullet")
                }
            
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            
            AnalysisView()
                .tabItem {
                    Label("Analysis", systemImage: "chart.pie")
                        .environment(\.symbolVariants, .none)
                }
            
            SettingView()
                .tabItem {
                    Label("Setting", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(previewContainer)
//        .preferredColorScheme(.dark)
}
