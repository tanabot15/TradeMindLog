//
//  SampleData.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/05/13.
//

import Foundation

struct SampleData {
    static var records: [Record] = [
        Record(id: UUID(), stockName: "Toyota", tickerCode: "1111", buyDate: .now.addingTimeInterval(86400), sellDate: nil, buyPrice: 1000.0, sellPrice: 1200.0, quantity: 200, situation: Situation.buy, buyReasons: [BuyReason.highProfitMargin], sellReasons: [SellReason.profitTaking], note: "Good choice", rating: 3, reflection: "So-so choice"),
        Record(id: UUID(), stockName: "NTT", tickerCode: "2222", buyDate: .now.addingTimeInterval(-86200), sellDate: .now, buyPrice: 2000.0, sellPrice: 2200.0, quantity: 300, situation: Situation.sell, buyReasons: [BuyReason.emotionalDecision], sellReasons: [SellReason.emotionalDecision], note: "Nice choice", rating: 4, reflection: "Good choice"),
        Record(id: UUID(), stockName: "Obayashi", tickerCode: "3333", buyDate: .now.addingTimeInterval(172800), sellDate: nil, buyPrice: 3000.0, sellPrice: 3200.0, quantity: 400, situation: Situation.buy, buyReasons: [BuyReason.highProfitMargin], sellReasons: [SellReason.others], note: "Bad choice", rating: 0, reflection: "very bad choice"),
        Record(id: UUID(), stockName: "Marubeni", tickerCode: "3333", buyDate: nil, sellDate: .now.addingTimeInterval(172800), buyPrice: 3000.0, sellPrice: 3200.0, quantity: 400, situation: Situation.buy, buyReasons: [BuyReason.others], sellReasons: [SellReason.profitTaking], note: "OK", rating: 4, reflection: "Nice"),
    ]
}
