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
    
}

struct EvaluationView: View {
    @Query private var records: [Record]
    
    @AppStorage("customBuyReasons") private var customBuyReasons: [String] = []
    @AppStorage("customSellReasons") private var customSellReasons: [String] = []
    
    @Binding var selectedSituation: Situation
    @Binding var selectedTimeFilter: TimeFilter
    
    private var isCompletelyEmptyForSituation: Bool {
        !records.contains { $0.situation == selectedSituation }
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
    
    var evaluationResults: [ReasonEvaluationData] {
        if selectedSituation == .buy {
            return BuyReason.allCases.map { reason in
                let targetRecords = filteredRecords.filter { $0.buyReason == reason }
                let name = reason.localizedName(customNames: customBuyReasons)
                return calculateAverage(records: targetRecords, name: name)
            }
            .filter { $0.count > 0 }
            .sorted { $0.averageRating > $1.averageRating }
        } else {
            return SellReason.allCases.map { reason in
                let targetRecords = filteredRecords.filter { $0.sellReason == reason }
                let name = reason.localizedName(customNames: customSellReasons)
                return calculateAverage(records: targetRecords, name: name)
            }
            .filter { $0.count > 0 }
            .sorted { $0.averageRating > $1.averageRating }
        }
    }
    
    var bestMetric: ReasonEvaluationData? {
        evaluationResults.first
    }
    
    var worstMetric: ReasonEvaluationData? {
        if evaluationResults.count > 1 {
            return evaluationResults.last
        }
        return nil
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Situation", selection: $selectedSituation) {
                    Text("購入").tag(Situation.buy)
                    Text("売却").tag(Situation.sell)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 4)
                
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
                                                .foregroundColor(.green)
                                            Text("最優秀パターン")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Text(best.reasonName)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .lineLimit(1)
                                        
                                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                                            Text(String(format: "%.1f", best.averageRating))
                                                .font(.system(.title, design: .rounded))
                                                .fontWeight(.bold)
                                                .foregroundColor(.green)
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.green)
                                                .font(.caption)
                                            Text("(\(best.count)件)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
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
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Text(worst.reasonName)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .lineLimit(1)
                                        
                                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                                            Text(String(format: "%.1f", worst.averageRating))
                                                .font(.system(.title, design: .rounded))
                                                .fontWeight(.bold)
                                                .foregroundColor(.pink)
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.pink)
                                                .font(.caption)
                                            Text("(\(worst.count)件)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
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
                                    .foregroundStyle(selectedSituation == .buy ? Color.blue.gradient : Color.red.gradient)
                                    .cornerRadius(4)
                                    .annotation(position: .trailing, alignment: .leading) {
                                        Text(String(format: "%.1f★", data.averageRating))
                                            .font(.caption)
                                            .bold()
                                            .foregroundColor(.secondary)
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
                                Text("傾向評価")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                
                                ForEach(Array(evaluationResults.enumerated()), id: \.element.id) { index, data in
                                    HStack {
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .bold()
                                            .foregroundStyle(.primary)
                                            .frame(width: 20, height: 20)
                                            .background(index == 0 ? Color.yellow : (index == 1 ? Color.gray : Color.secondary))
                                            .clipShape(Circle())
                                        
                                        Text(data.reasonName)
                                            .font(.subheadline)
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 2) {
                                            Text("平均")
                                            Text(String(format: "%.1f", data.averageRating))
                                                .bold()
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                                .font(.caption)
                                            Text("(\(data.count)件)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        .font(.subheadline)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 4)
                                    
                                    if index < evaluationResults.count - 1 {
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
    
    private func calculateAverage(records: [Record], name: String) -> ReasonEvaluationData {
        let validRecords = records.filter { $0.rating > 0 }
        let count = validRecords.count
        
        if count == 0 {
            return ReasonEvaluationData(reasonName: name, averageRating: 0.0, count: 0)
        }
        
        let totalRating = validRecords.reduce(0) { $0 + $1.rating }
        let average = Double(totalRating) / Double(count)
        
        return ReasonEvaluationData(reasonName: name, averageRating: average, count: count)
    }
}

#Preview {
    EvaluationView(selectedSituation: .constant(.buy), selectedTimeFilter: .constant(.all))
        .modelContainer(previewContainer)
//        .preferredColorScheme(.dark)
}
