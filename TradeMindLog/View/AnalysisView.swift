//
//  AnalysisView.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/05/13.
//

import SwiftUI
import SwiftData
import Charts

struct AnalysisView: View {
    @Query var records: [Record]
    
    @State private var selectedSituation = "購入"
    
    var filteredRecords: [Record] {
        records.filter { $0.situation.rawValue == selectedSituation}
    }
    
    struct ReasonStat: Identifiable {
        let id = UUID()
        let reason: String
        let count: Int
    }
    
    var buyReasonStats: [ReasonStat] {
        let groupedByReason = Dictionary(grouping: filteredRecords) { $0.buyReason }
        return groupedByReason.map { ReasonStat(reason: $0.key.rawValue, count: $0.value.count)}
    }
    
    var sellReasonStats: [ReasonStat] {
        let groupedByReason = Dictionary(grouping: filteredRecords) { $0.sellReason }
        return groupedByReason.map { ReasonStat(reason: $0.key.rawValue, count: $0.value.count)}
    }
    
    var body: some View {
        NavigationStack {
            Picker("Buy or Sell", selection: $selectedSituation) {
                Text("購入").tag("購入")
                Text("売却").tag("売却")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 10)

            ScrollView {
                VStack {
                    if filteredRecords.isEmpty {
                        ContentUnavailableView(
                            "Recordがありません",
                            systemImage: "chart.pie",
                            description: Text("Recordが追加されると、あなたの投資における売買傾向が視覚化されます")
                        )
                        .padding(.top, 50)
                    } else if selectedSituation == "購入" {
                        Chart(buyReasonStats) { stat in
                            SectorMark (
                                angle: .value("count", stat.count),
                                innerRadius: .ratio(0.5),
                                angularInset: 1
                            )
                            .cornerRadius(5)
                            .foregroundStyle(by: .value("購入理由", stat.reason))
                        }
                        .frame(height: 300)
                        .chartLegend(position: .bottom, alignment: .center, spacing: 20)
                        .padding()
                    } else if selectedSituation == "売却" {
                        Chart(sellReasonStats) { stat in
                            SectorMark (
                                angle: .value("count", stat.count),
                                innerRadius: .ratio(0.5),
                                angularInset: 1
                            )
                            .cornerRadius(5)
                            .foregroundStyle(by: .value("売却理由", stat.reason))
                        }
                        .frame(height: 300)
                        .chartLegend(position: .bottom, alignment: .center, spacing: 20)
                        .padding()
                    }
                    
                    VStack(alignment: .leading) {
                        if !filteredRecords.isEmpty {
                            Text("売買理由集計")
                                .font(.headline)
                                .padding()
                        }
                        
                        if selectedSituation == "購入" {
                            ForEach(buyReasonStats) { stat in
                                HStack {
                                    Text(stat.reason)
                                    Spacer()
                                    Text("\(stat.count)")
                                    
                                    // ration
                                    Text(String(format: "(%.1f%%)", Double(stat.count) / Double(filteredRecords.count) * 100))
                                        .font(.caption2)
                                }
                                .padding(.horizontal)
                                Divider()
                            }
                        } else if selectedSituation == "売却" {
                            ForEach(sellReasonStats) { stat in
                                HStack {
                                    Text(stat.reason)
                                    Spacer()
                                    Text("\(stat.count)")
                                    
                                    // ration
                                    Text(String(format: "(%.1f%%)", Double(stat.count) / Double(filteredRecords.count) * 100))
                                        .font(.caption2)
                                }
                                .padding(.horizontal)
                                Divider()
                            }
                        }
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("Analysis")
        }
    }
}

#Preview {
    AnalysisView()
        .modelContainer(previewContainer)
//        .preferredColorScheme(.dark)
}
