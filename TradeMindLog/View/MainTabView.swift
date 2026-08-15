//
//  ContentView.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/05/13.
//

import SwiftUI
import SwiftData
import AppTrackingTransparency

struct MainTabView: View {
    @State private var sharedSituation: Situation = .buy
    @State private var sharedTimeFilter: TimeFilter = .all
    @StateObject private var adManager = AdMobManager.shared
    
    @Query private var records: [Record]

    private var totalUnratedCount: Int {
        records.filter { $0.rating == 0 }.count
    }
    
    var body: some View {
        TabView {
            ListView(
                selectedSituation: $sharedSituation,
                selectedTimeFilter: $sharedTimeFilter
            )
            .tabItem {
                Label("一覧", systemImage: "list.bullet")
            }
            .badge(totalUnratedCount > 0 ? totalUnratedCount : 0)
            
            AnalysisView(
                selectedSituation: $sharedSituation,
                selectedTimeFilter: $sharedTimeFilter
            )
            .tabItem {
                Label("分析", systemImage: "chart.pie")
                    .environment(\.symbolVariants, .none)
            }
            
            SettingView()
                .tabItem {
                    Label("設定", systemImage: "gear")
                }
        }
        .onAppear {
            adManager.loadInterstitialAd()
            requestATT()
        }
    }
    
    private func requestATT() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    print("ATT: Authorized")
                case .denied:
                    print("ATT: Denied")
                case .notDetermined:
                    print("ATT: Not Determined")
                case .restricted:
                    print("ATT: Restricted")
                @unknown default:
                    break
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(previewContainer)
//        .preferredColorScheme(.dark)
}
