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
    
    @Binding var selectedSituation: Situation
    @Binding var selectedTimeFilter: TimeFilter
    
    @AppStorage("customBuyReasons") private var customBuyReasons: [String] = []
    @AppStorage("customSellReasons") private var customSellReasons: [String] = []
    
    @State private var isShowingFilterSheet = false
    
    private var isCompletelyEmptyForSituation: Bool {
            !records.contains { $0.situation == selectedSituation }
        }
    
    private var isAnyFilterActive: Bool {
        selectedTimeFilter != .all
    }
    
    var filteredRecords: [Record] {
        let situationRecords = records.filter { $0.situation == selectedSituation }
        
        let now = Date()
        let calendar = Calendar.current
        
        return situationRecords.filter { record in
            let targetDate = (record.situation == .buy ? record.buyDate : record.sellDate) ?? now
            
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
        let buyReasonKey: BuyReason?
        let sellReasonKey: SellReason?
    }
    
    var currentStats: [Stat] {
        if selectedSituation == .buy {
            let buyStats = BuyReason.allCases.map { reason -> (BuyReason, String, Int) in
                let count = filteredRecords.filter { $0.buyReasons.contains(reason) }.count
                let name = reason.localizedName(customNames: customBuyReasons)
                return (reason, name, count)
            }.filter { $0.2 > 0 }
            
            let totalVotes = buyStats.reduce(0) { $0 + $1.2 }
            guard totalVotes > 0 else { return [] }
            
            return buyStats.map { reason, name, count in
                Stat(reason: name, count: count, percentage: (Double(count) / Double(totalVotes)) * 100, buyReasonKey: reason, sellReasonKey: nil)
            }.sorted { $0.count > $1.count }
        } else {
            let sellStats = SellReason.allCases.map { reason -> (SellReason, String, Int) in
                let count = filteredRecords.filter { $0.sellReasons.contains(reason) }.count
                let name = reason.localizedName(customNames: customSellReasons)
                return (reason, name, count)
            }.filter { $0.2 > 0 }
            
            let totalVotes = sellStats.reduce(0) { $0 + $1.2 }
            guard totalVotes > 0 else { return [] }
            
            return sellStats.map { reason, name, count in
                Stat(reason: name, count: count, percentage: (Double(count) / Double(totalVotes)) * 100, buyReasonKey: nil, sellReasonKey: reason)
            }.sorted { $0.count > $1.count }
        }
    }
    
    private let chartColors: [Color] = [
        .teal, .orange, .green, .cyan, .yellow, .indigo, .mint
    ]
    
    var body: some View {
        NavigationStack {            
            VStack(spacing: 12) {
                if isCompletelyEmptyForSituation {
                    Spacer()
                    EmptyStateView(type: .completelyEmpty, situation: selectedSituation)
                    Spacer()
                } else if currentStats.isEmpty {
                    Spacer()
                    EmptyStateView(type: .filterEmpty(timeFilterText: selectedTimeFilter.rawValue), situation: selectedSituation)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Pie Chart Card
                            VStack {
                                Text("\(selectedSituation.rawValue)理由の比率")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                
                                ZStack {
                                    Chart(Array(currentStats.enumerated()), id: \.element.id) { index, stat in
                                        SectorMark (
                                            angle: .value("Count", stat.count),
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
                                    .padding(.bottom)
                                    
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
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            
                            // Stats Breakdown List Card
                            VStack(alignment: .leading, spacing: 12) {
                                Text("統計データ")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                                
                                ForEach(Array(currentStats.enumerated()), id: \.element.id) { index, stat in
                                    NavigationLink(destination: ReasonDetailListView(
                                        targetReasonName: stat.reason,
                                        buyReason: stat.buyReasonKey,
                                        sellReason: stat.sellReasonKey,
                                        allFilteredRecords: filteredRecords
                                    )) {
                                        HStack(spacing: 12) {
                                            Circle()
                                                .fill(chartColors[index % chartColors.count])
                                                .frame(width: 10, height: 10)
                                            
                                            Text(stat.reason)
                                                .font(.body)
                                                .foregroundStyle(Color.primary)
                                            
                                            Spacer()
                                            
                                            Text("\(stat.count) 件")
                                                .font(.body)
                                                .bold()
                                                .foregroundStyle(Color.primary)
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.body)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.vertical, 6)
                                    }
                                    
                                    if index < currentStats.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("トレード分析")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Situation", selection: $selectedSituation) {
                        Text("購入").tag(Situation.buy)
                        Text("売却").tag(Situation.sell)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingFilterSheet = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .fontWeight(isAnyFilterActive ? .semibold : .regular)
                            .foregroundStyle(isAnyFilterActive ? .blue : .primary)
                        
                    }
                }
            }
            .sheet(isPresented: $isShowingFilterSheet) {
                filterSheet
            }
        }
    }
    
    // Filter Sheet
    @ViewBuilder
    private var filterSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("期間")) {
                    Picker("期間", selection: $selectedTimeFilter) {
                        ForEach(TimeFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("フィルター")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        isShowingFilterSheet = false
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    if isAnyFilterActive {
                        Button {
                            withAnimation {
                                selectedTimeFilter = .all
                                isShowingFilterSheet = false
                            }
                        } label: {
                            Text("クリア")
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    AnalysisView(selectedSituation: .constant(.buy), selectedTimeFilter: .constant(.all))
        .modelContainer(previewContainer)
//        .preferredColorScheme(.dark)
}
