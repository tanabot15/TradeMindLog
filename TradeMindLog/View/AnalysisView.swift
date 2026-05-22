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
    @State private var selectedTimeFilter: TimeFilter = .all
    
    @AppStorage("customBuyReasons") private var customBuyReasons: [String] = []
    @AppStorage("customSellReasons") private var customSellReasons: [String] = []
    
    enum TimeFilter: String, CaseIterable, Identifiable {
        case all = "全期間"
        case thisYear = "今年"
        case thisMonth = "今月"
        
        var id: String { self.rawValue }
    }
    
    var filteredRecords: [Record] {
        let situationRecords = records.filter { $0.situation.rawValue == selectedSituation }
        
        let now = Date()
        let calendar = Calendar.current
        
        return situationRecords.filter { record in
            guard let targetDate = (record.situation == .buy ? record.buyDate : record.sellDate) else {
                return false
            }
            
            switch selectedTimeFilter {
            case .all:
                return true
            case .thisYear:
                return calendar.isDate(targetDate, equalTo: now, toGranularity: .year)
            case .thisMonth:
                return calendar.isDate(targetDate, equalTo: now, toGranularity: .month)
            }
        }
    }
    
    struct ReasonStat: Identifiable {
        let id = UUID()
        let reason: String
        let count: Int
        let percentage: Double
    }
    
    var buyReasonStats: [ReasonStat] {
        let groupedByReason = Dictionary(grouping: filteredRecords) { record in
            record.buyReason.localizedName(customNames: customBuyReasons)
        }
        let total = Double(filteredRecords.count)
        return groupedByReason.map { key, value in
            ReasonStat(
                reason: key,
                count: value.count,
                percentage: total > 0 ? (Double(value.count) / total) * 100 : 0
            )
        }.sorted { $0.count > $1.count }
    }
    
    var sellReasonStats: [ReasonStat] {
        let groupedByReason = Dictionary(grouping: filteredRecords) { record in
            record.sellReason.localizedName(customNames: customSellReasons)
        }
        let total = Double(filteredRecords.count)
        return groupedByReason.map { key, value in
            ReasonStat(
                reason: key,
                count: value.count,
                percentage: total > 0 ? (Double(value.count) / total) * 100 : 0
            )
        }.sorted { $0.count > $1.count}
    }
    
    var currentStats: [ReasonStat] {
        if selectedSituation == "購入" {
            return buyReasonStats
        } else {
            return sellReasonStats
        }
    }
    
    let chartColors: [Color] = [
        .teal, .orange, .green, .cyan, .yellow, .indigo, .mint
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Buy or Sell", selection: $selectedSituation) {
                    Text("購入").tag("購入")
                    Text("売却").tag("売却")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 10)
                
                Picker("Time Filter", selection: $selectedTimeFilter) {
                    ForEach(TimeFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            
            ScrollView {
                VStack(spacing: 12) {
                    if filteredRecords.isEmpty {
                        ContentUnavailableView(
                            "表示できるRecordがありません",
                            systemImage: "chart.pie",
                            description: Text("\(selectedTimeFilter.rawValue)の\(selectedSituation)取引が存在しません")
                        )
                        .padding(.top, 60)
                    } else {
                        VStack {
                            Text("\(selectedSituation)理由の比率")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ZStack {
                                Chart(selectedSituation == "購入" ? buyReasonStats : sellReasonStats) { stat in
                                    SectorMark (
                                        angle: .value("count", stat.count),
                                        innerRadius: .ratio(0.5),
                                        angularInset: 1
                                    )
                                    .cornerRadius(6)
                                    .foregroundStyle(by: .value("理由", stat.reason))
                                    .annotation(position: .overlay) {
                                        if stat.percentage > 10 {
                                            VStack {
                                                Text("\(stat.reason)")
                                                Text(String(format: "%.0f%%", stat.percentage))
                                            }
                                            .font(.caption2)
                                            .bold()
                                            .foregroundStyle(.white)
                                        }
                                    }
                                }
                                .chartForegroundStyleScale(
                                    domain: (selectedSituation == "購入" ? buyReasonStats : sellReasonStats).map { $0.reason },
                                    range: chartColors
                                )
                                .chartLegend(.hidden)
                                .frame(height: 280)
                                
                                VStack(spacing: 2) {
                                    Text("TOTAL")
                                        .font(.caption2)
                                        .bold()
                                        .foregroundStyle(.secondary)
                                    Text("\(filteredRecords.count)")
                                        .font(.system(.title, design: .rounded))
                                        .bold()
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                    
                        VStack(alignment: .leading) {
                            Text("売買理由の集計詳細")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top, 10)
                            
                            VStack(spacing: 0) {
                                let currentStats = selectedSituation == "購入" ? buyReasonStats : sellReasonStats
                                
                                ForEach(Array(currentStats.enumerated()), id: \.element.id) { index,stat in
                                    HStack(spacing: 12) {
                                        Circle()
                                            .fill(chartColors[index % chartColors.count])
                                            .frame(width: 10, height: 10)
                                        
                                        Text(stat.reason)
                                            .font(.body)
                                        
                                        Spacer()
                                        
                                        Text("\(stat.count) 回")
                                            .font(.body)
                                            .bold()
                                        
                                        Text(String(format: "%.1f%%", stat.percentage))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .frame(width: 60, alignment: .trailing)
                                    }
                                    .padding()
                                    
                                    if index < currentStats.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
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
