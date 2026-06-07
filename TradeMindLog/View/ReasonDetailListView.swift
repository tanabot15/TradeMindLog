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
                        VStack(spacing: 4) {
                            HStack {
                                Text(record.stockName)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Text(record.tickerCode)
                                    .font(.footnote)
                                
                                Spacer()
                                
                                HStack(spacing: 2) {
                                    Text("評価：")
                                        .font(.headline)
                                    
                                    if record.rating > 0 {
                                        ForEach(1...5, id: \.self) { star in
                                            Image(systemName: star <= record.rating ? "star.fill" : "star")
                                                .foregroundStyle(.yellow)
                                                .font(.caption2)
                                        }
                                    } else {
                                        Text("未実施         ")
                                            .font(.subheadline)
                                            .italic()
                                    }
                                }
                            }
                            
                            HStack {
                                Text("\(record.situation.rawValue)理由：")
                                    .font(.caption)
                                ReasonTagsView(record: record)
                            }
                        }
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
