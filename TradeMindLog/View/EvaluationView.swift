//
//  EvaluationView.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/05/26.
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

struct EvaluationView: View {
    @Query private var records: [Record]
    
    @AppStorage("customBuyReasons") private var customBuyReasons: [String] = []
    @AppStorage("customSellReasons") private var customSellReasons: [String] = []
    
    @Binding var selectedSituation: Situation
    @Binding var selectedTimeFilter: TimeFilter
    
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
    
    var evaluationResults: [ReasonEvaluationData] {
        if selectedSituation == .buy {
            return BuyReason.allCases.map { reason in
                let targetRecords = filteredRecords.filter { $0.buyReasons.contains(reason) }
                let name = reason.localizedName(customNames: customBuyReasons)
                return calculateAverage(records: targetRecords, name: name, buyKey: reason, sellKey: nil)
            }
            .filter { $0.count > 0 }
            .sorted { $0.averageRating > $1.averageRating }
        } else {
            return SellReason.allCases.map { reason in
                let targetRecords = filteredRecords.filter { $0.sellReasons.contains(reason) }
                let name = reason.localizedName(customNames: customSellReasons)
                return calculateAverage(records: targetRecords, name: name, buyKey: nil, sellKey: reason)
            }
            .filter { $0.count > 0 }
            .sorted { $0.averageRating > $1.averageRating }
        }
    }
    
    var bestMetric: ReasonEvaluationData? {
        evaluationResults.first { $0.averageRating > 0 }
    }
    
    var worstMetric: ReasonEvaluationData? {
        let ratedResults = evaluationResults.filter { $0.averageRating > 0 }
        if ratedResults.count > 1 {
            return ratedResults.last
        }
        return nil
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                if isCompletelyEmptyForSituation {
                    Spacer()
                    EmptyStateView(type: .completelyEmpty, situation: selectedSituation)
                    Spacer()
                } else if evaluationResults.isEmpty {
                    Spacer()
                    EmptyStateView(type: .filterEmpty(timeFilterText: selectedTimeFilter.rawValue), situation: selectedSituation)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            HStack(spacing: 12) {
                                // best card
                                if let best = bestMetric {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "checkmark.seal.fill")
                                                .foregroundStyle(.green)
                                            Text("最優秀パターン")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.secondary)
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
                                if let worst = worstMetric {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.pink)
                                            Text("要改善パターン")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundStyle(.secondary)
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
                            
                            // bar chart
                            VStack(alignment: .leading, spacing: 6) {
                                Text("理由別の平均スコア")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                
                                Chart(evaluationResults) { data in
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
                                .frame(height: CGFloat(evaluationResults.count * 45) + 30)
                                .padding(.trailing, 30)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                                                        
                            // detail list
                            VStack(alignment: .leading,spacing: 12) {
                                Text("統計データ")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                
                                ForEach(evaluationResults) { data in
                                    NavigationLink(destination: ReasonDetailListView(
                                        targetReasonName: data.reasonName,
                                        buyReason: data.buyReasonKey,
                                        sellReason: data.sellReasonKey,
                                        allFilteredRecords: filteredRecords
                                    )) {
                                        HStack {
                                            Circle()
                                                .frame(width: 10, height: 10)
                                            
                                            Text(data.reasonName)
                                                .foregroundStyle(Color.primary)
                                                .font(.subheadline)
                                            
                                            Spacer()
                                            
                                            HStack(spacing: 4) {
                                                Text(String(format: "%.1f", data.averageRating))
                                                    .foregroundStyle(Color.primary)
                                                    .font(.headline)
                                                    .bold()
                                                Image(systemName: "star.fill")
                                                    .foregroundStyle(.yellow)
                                                    .font(.caption)
                                                Text("(\(data.count)件)")
                                                    .font(.body)
                                                    .foregroundStyle(Color.secondary)
                                                Image(systemName: "chevron.right")
                                                    .font(.body)
                                                    .foregroundStyle(.secondary)

                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 4)
                                    }
                                    
                                    if data.id != evaluationResults.last?.id {
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
            .navigationTitle("トレード評価")
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
    
    private func calculateAverage(records: [Record], name: String, buyKey: BuyReason?, sellKey: SellReason?) -> ReasonEvaluationData {
        let totalCount = records.count
        
        if totalCount == 0 {
            return ReasonEvaluationData(reasonName: name, averageRating: 0.0, count: 0, buyReasonKey: buyKey, sellReasonKey: sellKey)
        }
        
        let ratedRecords = records.filter { $0.rating > 0 }
        
        if ratedRecords.isEmpty {
            return ReasonEvaluationData(reasonName: name, averageRating: 0.0, count: totalCount, buyReasonKey: buyKey, sellReasonKey: sellKey)
        }
        
        let totalRating = ratedRecords.reduce(0) { $0 + $1.rating }
        let average = Double(totalRating) / Double(ratedRecords.count)
        
        return ReasonEvaluationData(reasonName: name, averageRating: average, count: totalCount, buyReasonKey: buyKey, sellReasonKey: sellKey)
    }
}

#Preview {
    EvaluationView(selectedSituation: .constant(.buy), selectedTimeFilter: .constant(.all))
        .modelContainer(previewContainer)
//        .preferredColorScheme(.dark)
}
