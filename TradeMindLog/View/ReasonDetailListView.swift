//
//  ReasonDetailListView.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/06/04.
//

import SwiftUI
import SwiftData

struct ReasonDetailListView: View {
    let targetReasonName: String
    let buyReason: BuyReason?
    let sellReason: SellReason?
    let allFilteredRecords: [Record]
    
    @AppStorage("customBuyReasons") private var customBuyReasons: [String] = []
    @AppStorage("customSellReasons") private var customSellReasons: [String] = []
    
    var recordsWithThisReason: [Record] {
        allFilteredRecords.filter { record in
            if let buyTarget = buyReason {
                return record.buyReasons.contains(buyTarget)
            }
            if let sellTarget = sellReason {
                return record.sellReasons.contains(sellTarget)
            }
            return false
        }
    }
    
    var body: some View {
        List {
            Section(header: Text("\(targetReasonName)に該当するレコードは、\(recordsWithThisReason.count)件")) {
                ForEach(recordsWithThisReason) { record in
                    NavigationLink(destination: AddRecordView(record: record, isNew: false)) {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .bottom, spacing: 6) {
                                    Text(record.stockName)
                                        .font(.headline)
                                        .fontWeight(.bold)
                                    Text(record.tickerCode)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Text("理由: \(formatAllReasons(for: record))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(record.quantity) 株")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text(String(format: "%.0f 円", record.situation == .buy ? record.buyPrice : record.sellPrice))
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundStyle(record.situation == .buy ? .blue : .orange)
                                
                                if record.rating > 0 {
                                    HStack(spacing: 2) {
                                        ForEach(1...5, id: \.self) { star in
                                            Image(systemName: star <= record.rating ? "star.fill" : "star")
                                                .foregroundStyle(.yellow)
                                                .font(.caption2)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(targetReasonName)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatAllReasons(for record: Record) -> String {
        if record.situation == .buy {
            return record.buyReasons.map { $0.localizedName(customNames: customBuyReasons) }.joined(separator: ", ")
        } else {
            return record.sellReasons.map { $0.localizedName(customNames: customSellReasons) }.joined(separator: ", ")
        }
    }
}

#Preview {
    NavigationStack {
        ReasonDetailListView(
            targetReasonName: "感情的判断",
            buyReason: .emotionalDecision,
            sellReason: nil,
            allFilteredRecords: SampleData.records)
    }
    .modelContainer(previewContainer)
//    .preferredColorScheme(.dark)
}
