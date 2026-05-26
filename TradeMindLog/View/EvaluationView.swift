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
    
    @State private var selectedSituation: Situation = .buy
    
    var evaluationResults: [ReasonEvaluationData] {
        let filteredRecords = records.filter { $0.situation == selectedSituation }
        
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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Situation", selection: $selectedSituation) {
                    Text("購入").tag(Situation.buy)
                    Text("売却").tag(Situation.sell)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 10)
                
                if evaluationResults.isEmpty {
                    ContentUnavailableView(
                        "データが不足しています",
                        systemImage: "chart.bar.yaxis",
                        description: Text("評価が登録されたトレード記録を視覚化します")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
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
                            .padding()
                            
                            Divider()
                            
                            VStack(alignment: .leading,spacing: 12) {
                                Text("傾向評価")
                                    .font(.headline)
                                    .padding(.top, 8)
                                
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
                                        
                                        VStack(alignment: .trailing, spacing: 2) {
                                            HStack(spacing: 2) {
                                                Text("平均")
                                                Text(String(format: "%.1f", data.averageRating))
                                                    .bold()
                                                Image(systemName: "star.fill")
                                                    .foregroundColor(.yellow)
                                                    .font(.caption)
                                            }
                                            .font(.subheadline)
                                            
                                            Text("(\(data.count)件の評価")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 4)
                                    
                                    if index < evaluationResults.count - 1 {
                                        Divider()
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Evaluation")
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
    EvaluationView()
        .modelContainer(previewContainer)
//        .preferredColorScheme(.dark)
}
