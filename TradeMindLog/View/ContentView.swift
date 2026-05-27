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
                    Label("レコード", systemImage: "list.bullet")
                }
            
            CalendarView()
                .tabItem {
                    Label("カレンダー", systemImage: "calendar")
                }
            
            AnalysisView()
                .tabItem {
                    Label("分析", systemImage: "chart.pie")
                }
            
            EvaluationView()
                .tabItem {
                    Label("評価", systemImage: "chart.bar.yaxis")
                }
            
            SettingView()
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(previewContainer)
//        .preferredColorScheme(.dark)
}
