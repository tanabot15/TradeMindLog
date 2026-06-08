//
//  AnalysisView.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/05/13.
//

import SwiftUI
import SwiftData
import Charts

struct ReasonEvaluationData: Identifiable {
    let id = UUID()
    let reasonName: String
    let averageRating: Double
    let count: Int
    let buyReasonKey: BuyReason?
    let sellReasonKey: SellReason?
}

struct StatData: Identifiable {
    let id = UUID()
    let reason: String
    let count: Int
    let percentage: Double
    let buyReason: BuyReason?
    let sellReason: SellReason?
}

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
    
    private var filteredRecords: [Record] {
        let situationRecords = records.filter { $0.situation == selectedSituation }
        if selectedTimeFilter == .all { return situationRecords }
        
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
    
    private var aggregatedData: (stats: [StatData], evaluations: [ReasonEvaluationData]) {
        let currentRecords = filteredRecords
        
        var counts: [String: Int] = [:]
        var ratings: [String: (totalStars: Int, ratedCounts: Int)] = [:]
        
        var buyKeys: [String: BuyReason] = [:]
        var sellKeys: [String: SellReason] = [:]
        
        if selectedSituation == .buy {
            for reason in BuyReason.allCases {
                let name = reason.localizedName(customNames: customBuyReasons)
                counts[name] = 0
                ratings[name] = (0, 0)
                buyKeys[name] = reason
            }
        } else {
            for reason in SellReason.allCases {
                let name = reason.localizedName(customNames: customSellReasons)
                counts[name] = 0
                ratings[name] = (0, 0)
                sellKeys[name] = reason
            }
        }
        
        var totalReasonCount = 0
        for record in currentRecords {
            let targetReasons = selectedSituation == .buy ? record.buyReasons.map { $0.localizedName(customNames: customBuyReasons) } : record.sellReasons.map { $0.localizedName(customNames: customSellReasons) }
            
            for name in targetReasons {
                counts[name, default: 0] += 1
                totalReasonCount += 1
                
                if record.rating > 0  {
                    let currentRating = ratings[name, default: (0, 0)]
                    ratings[name] = (currentRating.totalStars + record.rating, currentRating.ratedCounts + 1)
                }
            }
        }
        
        let stats = counts.map { key, value in
            let percent = totalReasonCount > 0 ? (Double(value) / Double(totalReasonCount)) * 100 : 0.0
            return StatData(
                reason: key,
                count: value,
                percentage: percent,
                buyReason: buyKeys[key],
                sellReason: sellKeys[key]
            )
        }.sorted { $0.count > $1.count }
        
        let evaluations = counts.map { key, count in
            let ratingInfo = ratings[key, default: (0, 0)]
            let avg = ratingInfo.ratedCounts > 0 ? Double(ratingInfo.totalStars) / Double(ratingInfo.ratedCounts) : 0.0
            return ReasonEvaluationData(reasonName: key, averageRating: avg, count: count, buyReasonKey: buyKeys[key], sellReasonKey: sellKeys[key])
        }.sorted { $0.averageRating > $1.averageRating }
        
        return (stats, evaluations)
    }
    
    private var currentStat: [StatData] { aggregatedData.stats }
    private var evaluationData: [ReasonEvaluationData] { aggregatedData.evaluations }
    
    private var activeEvaluationData: [ReasonEvaluationData] {
        evaluationData.filter { $0.count > 0 }
    }
    
    var bestReason: ReasonEvaluationData? {
        let rated = evaluationData.filter { $0.averageRating > 0 }
        return rated.first
    }
    
    var worstReason: ReasonEvaluationData? {
        let rated = evaluationData.filter { $0.averageRating > 0 }
        return rated.count > 2 ? rated.last : nil
    }
    
    var body: some View {
        NavigationStack {            
            VStack(spacing: 12) {
                if isCompletelyEmptyForSituation {
                    Spacer()
                    EmptyStateView(type: .completelyEmpty, situation: selectedSituation)
                    Spacer()
                } else if filteredRecords.isEmpty {
                    Spacer()
                    EmptyStateView(type: .filterEmpty(timeFilterText: selectedTimeFilter.rawValue), situation: selectedSituation)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            pieChartSection
                            
                            bestWorstCardsSection
                            
                            barChartSection
                            
                            statsListSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("トレード分析")
            .navigationBarTitleDisplayMode(.inline)
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
    
    // Pie Chart Section
    @ViewBuilder
    private var pieChartSection: some View {
        VStack {
            Text("\(selectedSituation.rawValue)理由の比率")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ZStack {
                Chart(currentStat.filter { $0.count > 0 }) { stat in
                    SectorMark(
                        angle: .value("Count", stat.count),
                        innerRadius: .ratio(0.4),
                        angularInset: 1
                    )
                    .cornerRadius(5)
                    .foregroundStyle(by: .value("Reason", stat.reason))
                    .annotation(position: .overlay) {
                        if stat.percentage > 10 {
                            VStack {
                                Text("\(stat.reason)")
                                Text(String(format: "%.0f%%", stat.percentage))
                            }
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        }
                    }
                }
                .chartLegend(.hidden)
                .frame(height:260)
                
                VStack(spacing: 2) {
                    Text("TOTAL")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.secondary)
                    Text("\(filteredRecords.count)")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // Cards Section
    @ViewBuilder
    private var bestWorstCardsSection: some View {
        HStack(spacing: 12) {
            // best card
            if let best = bestReason {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                        Text("最優秀パターン")
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                    
                    Text(best.reasonName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.1f", best.averageRating))
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                        Image(systemName: "star.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                        Text("(\(best.count)件)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
            }
            
            // worst card
            if let worst = worstReason {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.pink)
                        Text("要改善パターン")
                            .font(.caption)
                            .foregroundStyle(.primary)
                    }
                    
                    Text(worst.reasonName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.1f", worst.averageRating))
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundStyle(.pink)
                        Image(systemName: "star.fill")
                            .foregroundStyle(.pink)
                            .font(.caption)
                        Text("(\(worst.count)件)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.pink.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.pink.opacity(0.2), lineWidth: 1)
                )
            }
        }
    }
    
    // Bar Chart Section
    @ViewBuilder
    private var barChartSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("理由別の平均スコア")
                .font(.subheadline)
                .fontWeight(.bold)
            
            Chart(evaluationData.filter{ $0.count > 0 }) { data in
                BarMark(
                    x: .value("評価", data.averageRating),
                    y: .value("理由", data.reasonName)
                )
                .foregroundStyle(selectedSituation == .buy ? Color.blue.gradient : Color.orange.gradient)
                .cornerRadius(4)
                .annotation(position: .trailing, alignment: .leading) {
                    Text(String(format: "%.1f★", data.averageRating))
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }
            }
            .chartXScale(domain: 0...5)
            .chartXAxis {
                AxisMarks(values: [0, 1, 2, 3, 4, 5])
            }
            .frame(height: CGFloat(max(100, evaluationData.filter { $0.count > 0 }.count * 50)))
            .padding(.trailing, 30)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // Statictics List Section
    @ViewBuilder
    private var statsListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("統計データ")
                .font(.subheadline)
                .fontWeight(.bold)
            
            ForEach(currentStat) { stat in
                NavigationLink(destination: {
                    ReasonDetailListView(
                        targetReasonName: stat.reason,
                        buyReason: stat.buyReason,
                        sellReason: stat.sellReason,
                        allFilteredRecords: filteredRecords,
                    )
                }) {
                    HStack {
                        Circle()
                            .frame(width: 10, height: 10)
                            .foregroundStyle(selectedSituation == .buy ? .blue : .orange)
                        Text(stat.reason)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(stat.count)件")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                        Text(String(format: "(%.1f%%)", stat.percentage))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .trailing)
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
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
