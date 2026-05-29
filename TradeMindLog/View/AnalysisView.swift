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
    
    @State private var selectedSituation: Situation = .buy
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
        let situationRecords = records.filter { $0.situation == selectedSituation }
        
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
    
    struct Stat: Identifiable {
        let id = UUID()
        let reason: String
        let count: Int
        let percentage: Double
    }
    
    var currentStats: [Stat] {
        let totalCount = filteredRecords.count
        guard totalCount > 0 else { return [] }
        
        if selectedSituation == .buy {
            var counts: [BuyReason: Int] = [:]
            for r in filteredRecords {
                counts[r.buyReason, default: 0] += 1
            }
            return BuyReason.allCases.map { reason in
                let count = counts[reason, default: 0]
                let pct = (Double(count) / Double(totalCount)) * 100.0
                let name = reason.localizedName(customNames: customBuyReasons)
                return Stat(reason: name, count: count, percentage: pct)
            }
            .filter { $0.count > 0 }
            .sorted { $0.count > $1.count }
        } else {
            var counts: [SellReason: Int] = [:]
            for r in filteredRecords {
                counts[r.sellReason, default: 0] += 1
            }
            return SellReason.allCases.map { reason in
                let count = counts[reason, default: 0]
                let pct = (Double(count) / Double(totalCount)) * 100.0
                let name = reason.localizedName(customNames: customSellReasons)
                return Stat(reason: name, count: count, percentage: pct)
            }
            .filter { $0.count > 0 }
            .sorted { $0.count > $1.count }
        }
    }
    
    private let chartColors: [Color] = [
        .teal, .orange, .green, .cyan, .yellow, .indigo, .mint
    ]
    
    var body: some View {
        NavigationStack {            
            ScrollView {
                VStack(spacing: 12) {
                    Picker("Situation", selection: $selectedSituation) {
                        Text("購入").tag(Situation.buy)
                        Text("売却").tag(Situation.sell)
                    }
                    .pickerStyle(.segmented)
                    
                    if currentStats.isEmpty {
                        Spacer()
                        ContentUnavailableView(
                            "表示できるレコードがありません",
                            systemImage: "chart.pie",
                            description: Text("\(selectedTimeFilter.rawValue)の\(selectedSituation.rawValue)取引が存在しません")
                        )
                        Spacer()
                    } else {
                        VStack {
                            Text("\(selectedSituation.rawValue)理由の比率")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .bold()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ZStack {
                                Chart(Array(currentStats.enumerated()), id: \.element.id) { index, stat in
                                    SectorMark (
                                        angle: .value("count", stat.count),
                                        innerRadius: .ratio(0.5),
                                        angularInset: 1
                                    )
                                    .foregroundStyle(chartColors[index % chartColors.count])
                                    .cornerRadius(6)
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
                                    domain: (currentStats).map { $0.reason },
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
                    
                        VStack(alignment: .leading) {
                            Text("売買理由の集計詳細")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top, 10)
                            
                            VStack(spacing: 0) {
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
                        }
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("トレード分析")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("期間", selection: $selectedTimeFilter) {
                            ForEach(TimeFilter.allCases) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text(selectedTimeFilter.rawValue)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    AnalysisView()
        .modelContainer(previewContainer)
//        .preferredColorScheme(.dark)
}
