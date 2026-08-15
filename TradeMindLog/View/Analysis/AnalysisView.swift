//
//  AnalysisView.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/05/13.
//

import SwiftUI
import SwiftData
import Charts

struct ReasonAnalyticsData: Identifiable {
    let id = UUID()
    let reasonName: String
    let count: Int
    let percentage: Double
    let averageRating: Double
    let buyReasonKey: BuyReason?
    let sellReasonKey: SellReason?
    let themeColor: Color
}

struct ReasonTrendData: Identifiable {
    let id = UUID()
    let timeLabel: String
    let sortValue: Int
    let reasonName: String
    let count: Int
    let themeColor: Color
}

struct AnalysisView: View {
    @Query var records: [Record]
    
    @Binding var selectedSituation: Situation
    @Binding var selectedTimeFilter: TimeFilter
    
    @AppStorage("customBuyReasons") private var customBuyReasons: [String] = []
    @AppStorage("customSellReasons") private var customSellReasons: [String] = []
    
    @AppStorage("analysisPartOrder") private var analysisPartOrder: [String] = ["pie", "trend", "cards", "bar", "list"]
    @AppStorage("showAnalysisPieChart") private var showAnalysisPieChart = true
    @AppStorage("showAnalysisTrendChart") private var showAnalysisTrendChart = true
    @AppStorage("showAnalysisBestWorstCards") private var showAnalysisBestWorstCards = true
    @AppStorage("showAnalysisBarChart") private var showAnalysisBarChart = true
    @AppStorage("showAnalysisStatsList") private var showAnalysisStatsList = true
    
    @State private var isShowingFilterSheet = false
    @State private var selectedBuyFilters: Set<BuyReason> = []
    @State private var selectedSellFilters: Set<SellReason> = []
    @State private var isAndFilterMode = false
    
    @StateObject private var adManager = AdMobManager.shared
    
    // MARK: - Caluculate, Data Logic
    private var isCompletelyEmptyForSituation: Bool {
        !records.contains { $0.situation == selectedSituation }
    }
    
    private var isReasonFilterActive: Bool {
        selectedSituation == .buy ? !selectedBuyFilters.isEmpty : !selectedSellFilters.isEmpty
    }
    
    private var isAnyFilterActive: Bool {
        isReasonFilterActive || selectedTimeFilter != .all
    }
    
    private var filteredRecords: [Record] {
        let situationRecords = records.filter { $0.situation == selectedSituation }
        
        let now = Date()
        let calendar = Calendar.current
        
        let timeFiltered = situationRecords.filter { record in
            if selectedTimeFilter == .all { return true }
            let targetDate = (record.situation == .buy ? record.buyDate : record.sellDate) ?? .now
            switch selectedTimeFilter {
            case .all:
                return true
            case .thisYear:
                return calendar.isDate(targetDate, equalTo: now, toGranularity: .year)
            case .thisMonth:
                return calendar.isDate(targetDate, equalTo: now, toGranularity: .month)
            }
        }
        
        if selectedSituation == .buy {
            if selectedBuyFilters.isEmpty { return timeFiltered }
            return timeFiltered.filter { record in
                if isAndFilterMode {
                    return selectedBuyFilters.isSubset(of: record.buyReasons)
                } else {
                    return !selectedBuyFilters.isDisjoint(with: record.buyReasons)
                }
            }
        } else {
            if selectedSellFilters.isEmpty { return timeFiltered }
            return timeFiltered.filter { record in
                if isAndFilterMode {
                    return selectedSellFilters.isSubset(of: record.sellReasons)
                } else {
                    return !selectedSellFilters.isDisjoint(with: record.sellReasons)
                }
            }
        }
    }
    
    private var aggregatedData: [ReasonAnalyticsData] {
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
        
        return counts.map { key, value in
            let percent = totalReasonCount > 0 ? (Double(value) / Double(totalReasonCount)) * 100 : 0.0
            let ratingInfo = ratings[key, default: (0, 0)]
            let avg = ratingInfo.ratedCounts > 0 ? Double(ratingInfo.totalStars) / Double(ratingInfo.ratedCounts) : 0.0
            
            let color: Color
            if selectedSituation == .buy {
                color = buyKeys[key]?.color(customNames: customBuyReasons) ?? .gray
            } else {
                color = sellKeys[key]?.color(customNames: customSellReasons) ?? .gray
            }
            
            return ReasonAnalyticsData(
                reasonName: key,
                count: value,
                percentage: percent,
                averageRating: avg,
                buyReasonKey: buyKeys[key],
                sellReasonKey: sellKeys[key],
                themeColor: color
            )
        }
    }
    
    private var scoreSortedStat: [ReasonAnalyticsData] {
        aggregatedData.sorted {
            if $0.averageRating != $1.averageRating {
                return $0.averageRating > $1.averageRating
            }
            
            if $0.count != $1.count {
                return $0.count > $1.count
            }
            
            return $0.reasonName > $1.reasonName
        }
    }
    
    private var trendData: [ReasonTrendData] {
        let calendar = Calendar.current
        let now = Date()
        
        func timeInfo(for record: Record) -> (sortValue: Int, label: String) {
            let date = (record.situation == .buy ? record.buyDate : record.sellDate) ?? .now
            switch selectedTimeFilter {
            case .all:
                let year = calendar.component(.year, from: date)
                return (year, "\(year)年")
            case .thisYear:
                let month = calendar.component(.month, from: date)
                return (month, "\(month)月")
            case .thisMonth:
                let day = calendar.component(.day, from: date)
                return (day, "\(day)日")
            }
        }
        
        var activeTimePoints: [Int: String] = [:]
        
        switch selectedTimeFilter {
        case .all:
            break
        case .thisYear:
            for m in 1...12 { activeTimePoints[m] = "\(m)月" }
        case .thisMonth:
            if let range = calendar.range(of: .day, in: .month, for: now) {
                for d in range { activeTimePoints[d] = "\(d)日" }
            }
        }
        
        for record in filteredRecords {
            let info = timeInfo(for: record)
            activeTimePoints[info.sortValue] = info.label
        }
        
        var trendCounts: [String: [Int: Int]] = [:]
        var reasonColors: [String: Color] = [:]
        
        let activeReasons = aggregatedData.filter { $0.count > 0 }
        
        for stat in activeReasons {
            reasonColors[stat.reasonName] = stat.themeColor
            trendCounts[stat.reasonName] = [Int:Int]()
        }
        
        for record in filteredRecords {
            let info = timeInfo(for: record)
            let reasons = selectedSituation == .buy ? record.buyReasons.map { $0.localizedName(customNames: customBuyReasons) } : record.sellReasons.map { $0.localizedName(customNames: customSellReasons) }
            
            for name in reasons {
                if trendCounts[name] != nil {
                    var timeCounts = trendCounts[name] ?? [:]
                    let currentCount = timeCounts[info.sortValue] ?? 0
                    timeCounts[info.sortValue] = currentCount + 1
                    trendCounts[name] = timeCounts
                }
            }
        }
        
        var result: [ReasonTrendData] = []
        let sortedTimeKeys = activeTimePoints.keys.sorted()
        
        let currentCalendar = Calendar.current
        let currentYear = currentCalendar.component(.year, from: now)
        let currentMonth = currentCalendar.component(.month, from: now)
        let currentDay = currentCalendar.component(.day, from: now)
        
        let todayKey: Int
        if let firstKey = sortedTimeKeys.first {
            if firstKey > 20000000 {
                todayKey = currentYear * 10000 + currentMonth * 100 + currentDay
            } else if firstKey > 200000 {
                todayKey = currentYear * 100 + currentMonth
            } else {
                todayKey = currentYear
            }
        } else {
            todayKey = Int.max
        }
        
        for stat in activeReasons {
            let name = stat.reasonName
            let color = stat.themeColor
            var runningTotal = 0
            
            for timeKey in sortedTimeKeys {
                if timeKey > todayKey {
                    continue
                }
                
                let count = trendCounts[name]?[timeKey] ?? 0
                runningTotal += count
                
                let label = activeTimePoints[timeKey] ?? ""
                
                result.append(ReasonTrendData(
                    timeLabel: label,
                    sortValue: timeKey,
                    reasonName: name,
                    count: runningTotal,
                    themeColor: color
                ))
            }
        }
        
        return result.sorted { $0.sortValue < $1.sortValue }
    }
    
    private var activeTrendReasons: [(name: String, color: Color)] {
        var seen = Set<String>()
        var list: [(name: String, color: Color)] = []
        for trend in trendData {
            if !seen.contains(trend.reasonName) && trend.count > 0 {
                seen.insert(trend.reasonName)
                list.append((name: trend.reasonName, color: trend.themeColor))
            }
        }
        
        return list
    }
    
    var bestReason: ReasonAnalyticsData? {
        let rated = scoreSortedStat.filter { $0.averageRating > 0 }
        return rated.first
    }
    
    var worstReason: ReasonAnalyticsData? {
        let rated = scoreSortedStat.filter { $0.averageRating > 0 }
        return rated.count > 2 ? rated.last : nil
    }
    
    // MARK: - Main View
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                BannerAdView(adUnitID: adManager.bannerAdUnitID)
                    .frame(height: 50)
                    .background(Color(.systemBackground))
                
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
                                ForEach(analysisPartOrder, id: \.self) { partKey in
                                    switch partKey {
                                    case "pie":
                                        if showAnalysisPieChart { pieChartSection }
                                    case "trend":
                                        if showAnalysisTrendChart { trendChartSection }
                                    case "cards":
                                        if showAnalysisBestWorstCards { bestWorstCardsSection }
                                    case "bar":
                                        if showAnalysisBarChart { barChartSection }
                                    case "list":
                                        if showAnalysisStatsList { statsListSection }
                                    default:
                                        EmptyView()
                                    }
                                }
                            }
                            .padding()
                        }
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
    
    // MARK: - Sub Views
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
                Chart(scoreSortedStat.filter { $0.count > 0 }) { stat in
                    SectorMark(
                        angle: .value("Count", stat.count),
                        innerRadius: .ratio(0.4),
                        angularInset: 1
                    )
                    .cornerRadius(5)
                    .foregroundStyle(stat.themeColor)
                    .annotation(position: .overlay) {
                        if stat.percentage > 10 {
                            VStack {
                                Text("\(stat.reasonName)")
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
    
    // Trend Chart Section
    @ViewBuilder
    private var trendChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(selectedSituation.rawValue)理由の出現トレンド")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if filteredRecords.isEmpty {
                Text("データがありません")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Chart(trendData) { trend in
                    LineMark(
                        x: .value("時間", trend.timeLabel),
                        y: .value("件数", trend.count),
                        series: .value("理由", trend.reasonName)
                    )
                    .foregroundStyle(trend.themeColor)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                    
                    PointMark(
                        x: .value("時間", trend.timeLabel),
                        y: .value("件数", trend.count),
                    )
                    .foregroundStyle(trend.themeColor)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4))
                }
                .overlay(alignment: .topLeading) {
                    if !activeTrendReasons.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(activeTrendReasons, id: \.name) { reason in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(reason.color)
                                        .frame(width: 6, height: 6)
                                    Text(reason.name)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(8)
                        .background(Color(.secondarySystemBackground).opacity(0.85))
                        .cornerRadius(6)
                        .padding([.top, .leading], 8)
                    }
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
            Text("\(selectedSituation.rawValue)理由別の平均スコア")
                .font(.subheadline)
                .fontWeight(.bold)
            
            Chart(scoreSortedStat.filter{ $0.count > 0 }) { data in
                BarMark(
                    x: .value("評価", data.averageRating),
                    y: .value("理由", data.reasonName)
                )
                .foregroundStyle(data.themeColor.gradient)
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
            .frame(height: CGFloat(max(100, scoreSortedStat.filter { $0.count > 0 }.count * 50)))
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
            Text("\(selectedSituation.rawValue)理由統計データ")
                .font(.subheadline)
                .fontWeight(.bold)
            
            ForEach(scoreSortedStat.filter { $0.count > 0 }) { stat in
                NavigationLink(destination: {
                    ReasonDetailListView(
                        targetReasonName: stat.reasonName,
                        buyReason: stat.buyReasonKey,
                        sellReason: stat.sellReasonKey,
                        allFilteredRecords: filteredRecords,
                    )
                }) {
                    HStack {
                        Circle()
                            .frame(width: 10, height: 10)
                            .foregroundStyle(stat.themeColor)
                        
                        Text(stat.reasonName)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        HStack(spacing: 2) {
                            Text(String(format: "%.1f", stat.averageRating))
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundStyle(.yellow)
                        }
                        
                        Spacer()
                            .frame(width: 20)
                        
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
                
                Section(header: Text("売買理由")) {
                    Picker("検索条件", selection: $isAndFilterMode) {
                        Text("OR検索").tag(false)
                        Text("AND検索").tag(true)
                    }
                    .pickerStyle(.segmented)
                    
                    if selectedSituation == .buy {
                        ForEach(BuyReason.allCases) { reason in
                            Button {
                                if selectedBuyFilters.contains(reason) {
                                    selectedBuyFilters.remove(reason)
                                } else {
                                    selectedBuyFilters.insert(reason)
                                }
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(reason.color(customNames: customBuyReasons))
                                        .frame(width: 10, height: 10)
                                    Text(reason.localizedName(customNames: customBuyReasons))
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                    if selectedBuyFilters.contains(reason) {
                                        Image(systemName: "checkmark")
                                            .bold()
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                        }
                    } else {
                        ForEach(SellReason.allCases) { reason in
                            Button {
                                if selectedSellFilters.contains(reason) {
                                    selectedSellFilters.remove(reason)
                                } else {
                                    selectedSellFilters.insert(reason)
                                }
                            } label: {
                                HStack {
                                    Text(reason.localizedName(customNames: customBuyReasons))
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                    if selectedSellFilters.contains(reason) {
                                        Image(systemName: "checkmark")
                                            .bold()
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                        }
                    }
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
                                selectedBuyFilters.removeAll()
                                selectedSellFilters.removeAll()
                                isAndFilterMode = false
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
    AnalysisView(selectedSituation: .constant(.buy), selectedTimeFilter: .constant(.thisYear))
        .modelContainer(previewContainer)
//        .preferredColorScheme(.dark)
}
