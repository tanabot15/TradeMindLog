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
    var buyDate: Date?
    var sellDate: Date?
    var buyPrice: Double
    var sellPrice: Double
    var quantity: Int
    var buyReason: BuyReason
    var sellReason: SellReason
    var situation: Situation
    var note: String
    var reflection: String
    
    init(
        id: UUID,
        stockName: String,
        tickerCode: String,
        buyDate: Date? = nil,
        sellDate: Date? = nil,
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

extension Array: @retroactive RawRepresentable where Element == String {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([String].self, from: data) else {
            return nil
        }
        self = result
    }
    
    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return result
    }
}

extension BuyReason {
    func localizedName(customNames: [String]) -> String {
        let index = BuyReason.allCases.firstIndex(of: self) ?? 0
        if index < customNames.count {
            return customNames[index]
        }
        return self.rawValue
    }
}

extension SellReason {
    func localizedName(customNames: [String]) -> String {
        let index = SellReason.allCases.firstIndex(of: self) ?? 0
        if index < customNames.count {
            return customNames[index]
        }
        return self.rawValue
    }
}
