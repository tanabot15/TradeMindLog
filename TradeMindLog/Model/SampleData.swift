//
//  SampleData.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/05/13.
//

import Foundation

struct SampleData {
    static var records: [Record] = [
        Record(id: UUID(), stockName: "Toyota", tickerCode: "1111", buyDate: .now.addingTimeInterval(10), sellDate: .now.addingTimeInterval(86400), buyPrice: 1000.0, sellPrice: 1200.0, quantity: 200, situation: Situation.buy, buyReason: BuyReason.valuationAttractive, sellReason: SellReason.profitTaking, note: "Good choice", reflection: "Bad choice"),
        Record(id: UUID(), stockName: "NTT", tickerCode: "2222", buyDate: .now.addingTimeInterval(43200), sellDate: .now.addingTimeInterval(86400), buyPrice: 2000.0, sellPrice: 2200.0, quantity: 300, situation: Situation.sell, buyReason: BuyReason.emotionalDecision, sellReason: SellReason.emotionalDecision, note: "Nice choice", reflection: "So-so choice"),
        Record(id: UUID(), stockName: "Obayashi", tickerCode: "3333", buyDate: .now.addingTimeInterval(86400), sellDate: .now.addingTimeInterval(172800), buyPrice: 3000.0, sellPrice: 3200.0, quantity: 400, situation: Situation.buy, buyReason: BuyReason.highProfitMargin, sellReason: SellReason.others, note: "Bad choice", reflection: "very bad choice"),
    ]
}
