//
//  Record.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/05/13.
//

import Foundation
import SwiftData

enum BuyReason: String, Codable, CaseIterable, Identifiable {
    case valuationAttractive = "割安性"
    case innovationLaunch = "革新性"
    case highProfitMargin = "高利益率"
    case strongMoat = "強力な堀"
    case technicalAnalysis = "テクニカル"
    case emotionalDecision = "感情的判断"
    case others = "その他"
    
    var id: String { self.rawValue }
}

enum SellReason: String, Codable, CaseIterable, Identifiable {
    case profitTaking = "利益確定"
    case stopLoss = "損切り"
    case thesisChange = "シナリオ変化"
    case cashNeed = "資金確保"
    case technicalAnalysis = "テクニカル"
    case emotionalDecision = "感情的判断"
    case others = "その他"
    
    var id: String { self.rawValue }
}

enum Situation: String, Codable, CaseIterable, Identifiable {
    case buy = "購入"
    case sell = "売却"
    
    var id: String { self.rawValue }
}

@Model
class Record {
    var id: UUID = UUID()
    var stockName: String
    var tickerCode: String
    var buyDate: Date
    var sellDate: Date
    var buyPrice: Double
    var sellPrice: Double
    var quantity: Int
    var situation: Situation
    var buyReason: BuyReason
    var sellReason: SellReason
    var note: String
    var reflection: String
        
    // caluculate profit
    var profit: Double {
        (sellPrice - buyPrice) * Double(quantity)
    }
    
    init(
        id: UUID,
        stockName: String,
        tickerCode: String,
        buyDate: Date,
        sellDate: Date,
        buyPrice: Double,
        sellPrice: Double,
        quantity: Int,
        situation: Situation,
        buyReason: BuyReason,
        sellReason: SellReason,
        note: String,
        reflection: String
    ) {
        self.id = id
        self.stockName = stockName
        self.tickerCode = tickerCode
        self.buyDate = buyDate
        self.sellDate = sellDate
        self.buyPrice = buyPrice
        self.sellPrice = sellPrice
        self.quantity = quantity
        self.situation = situation
        self.buyReason = buyReason
        self.sellReason = sellReason
        self.note = note
        self.reflection = reflection
    }
}
