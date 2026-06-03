//
//  SettingViewModel.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/05/22.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Combine

// for csv document
struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    
    var text: String
    
    init(text: String) {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents,
           let string = String(data: data, encoding: .utf8) {
            self.text = string
        } else {
            self.text = ""
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}

@MainActor
class SettingViewModel: ObservableObject {
    @Published var exportDocument: CSVDocument? = nil
    @Published var isShowingExporter = false
    @Published var isShowingImporter = false
    @Published var isShowingImportAlert = false
    @Published var importAlertMessage = ""
    @Published var isShowingDeleteAleart = false
    
    // Tanabot Menbership, Privacy Policy,  Term of Service URLs
    let experimentURL = URL(string: "https://note.com/tanabot/membership")!
    let noteMembershipTitle = """
    株を勉強して半年で100銘柄買ったら、
    人生は変わるのか？
     （ noteメンバーシップページ ）
    """
    let privacyPolicyURL = URL(string: "https://sites.google.com/view/trademindlog/%E3%83%97%E3%83%A9%E3%82%A4%E3%83%90%E3%82%B7%E3%83%BC-%E3%83%9D%E3%83%AA%E3%82%B7%E3%83%BC")!
    let termsOfServiceURL = URL(string: "https://sites.google.com/view/trademindlog/%E3%81%94%E5%88%A9%E7%94%A8%E8%A6%8F%E5%89%87")!
    
    // delete all records
    func deleteAllRecords(modelContext: ModelContext) {
        do {
            try modelContext.delete(model: Record.self)
            try modelContext.save()
        } catch {
            print("Failed to delete all records: \(error)")
        }
    }
    
    // create csv export data
    func generateAndExportCSV(records: [Record], customBuyReasons: [String], customSellReasons: [String]) {
        var csvString = "ID,状況,銘柄名,ティッカーコード,数量,購入日,購入価格,売却日,売却価格,購入理由,売却理由,ノート,評価,振り返り\n"
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        
        for record in records {
            let id = record.id.uuidString
            let situation = record.situation.rawValue
            let stockName = "\"\(record.stockName.replacingOccurrences(of: "\"", with: "\"\""))\""
            let ticker = record.tickerCode
            let qty = record.quantity
            let buyDateStr = record.buyDate != nil ? formatter.string(from: record.buyDate!) : ""
            let buyPrice = record.buyPrice
            let sellDateStr = record.sellDate != nil ? formatter.string(from: record.sellDate!) : ""
            let sellPrice = record.sellPrice
            
            let buyReason = record.buyReasons.map { $0.rawValue }.joined(separator: "|")
            let sellReason = record.sellReasons.map { $0.rawValue }.joined(separator: "|")
            
            let note = "\"\(record.note.replacingOccurrences(of: "\"", with: "\"\""))\""
            let rating = record.rating
            let reflection = "\"\(record.reflection.replacingOccurrences(of: "\"", with: "\"\""))\""
            
            let row = "\(id),\(situation),\(stockName),\(ticker),\(qty),\(buyDateStr),\(buyPrice),\(sellDateStr),\(sellPrice),\(buyReason),\(sellReason),\(note),\(rating),\(reflection)\n"
            csvString.append(row)
        }
        
        self.exportDocument = CSVDocument(text: csvString)
        self.isShowingExporter = true
    }
    
    // csv import
    func importCSV(from url: URL, modelContext: ModelContext, customBuyReasons: [String], customSellReasons: [String], records: [Record]) {
        guard url.startAccessingSecurityScopedResource() else {
            showImportResult(message: "ファイルへのアクセス権限がありません")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            guard let contentString = String(data: data, encoding: .utf8) else {
                showImportResult(message: "ファイルを文字コードUTF-8として読み込めませんでした")
                return
            }
            
            let rows = parseCSV(contentString)
            if rows.isEmpty {
                showImportResult(message: "有効なデータ行が見つかりませんでした")
                return
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy/MM/dd"
            
            var successCount = 0
            var skipCount = 0
            
            let existingIDs = Set(records.map { $0.id.uuidString })
            
            for fields in rows {
                if fields.first == "ID" || fields.count < 14 { continue }
                
                let idString = fields[0]
                
                if existingIDs.contains(idString) {
                    skipCount += 1
                    continue
                }
                
                guard let uuid = UUID(uuidString: idString) else { continue }
                
                let situationRaw = fields[1]
                let situation: Situation = (situationRaw == "売却") ? .sell : .buy
                let stockName = fields[2]
                let tickerCode = fields[3]
                let quantity = Int(fields[4]) ?? 100
                let buyDate = dateFormatter.date(from: fields[5])
                let buyPrice = Double(fields[6]) ?? 0.0
                let sellDate = dateFormatter.date(from: fields[7])
                let sellPrice = Double(fields[8]) ?? 0.0
                
                let buyReasonsRaw = fields[9].components(separatedBy: "|")
                let buyReasons = buyReasonsRaw.compactMap { BuyReason(rawValue: $0) }
                let sellReasonsRaw = fields[10].components(separatedBy: "|")
                let sellReasons = sellReasonsRaw.compactMap { SellReason(rawValue: $0) }
                
                let note = fields[12]
                let rating = Int(fields[13]) ?? 0
                let reflection = fields[14]
                
                let record = Record(
                    id: uuid,
                    stockName: stockName,
                    tickerCode: tickerCode,
                    buyDate: buyDate,
                    sellDate: sellDate,
                    buyPrice: buyPrice,
                    sellPrice: sellPrice,
                    quantity: quantity,
                    situation: situation,
                    buyReasons: buyReasons.isEmpty ? [.others] : buyReasons,
                    sellReasons: sellReasons.isEmpty ? [.others] : sellReasons,
                    note: note,
                    rating: rating,
                    reflection: reflection
                )
                
                modelContext.insert(record)
                successCount += 1
            }
            
            try modelContext.save()
            showImportResult(message: "\(successCount)件の取引を正常にインポートしました。\(skipCount > 0 ? "\n(既に存在する \(skipCount) 件のデータはスキップされました)" : "")")
        } catch {
            showImportResult(message: "インポートエラー：\(error.localizedDescription)")
        }
    }
    
    // parser logic
    private func parseCSV(_ text: String) -> [[String]] {
        var result: [[String]] = []
        var currentFields: [String] = []
        var currentField = ""
        var inQuotes = false
        
        let characters = Array(text)
        var index = 0
        
        while index < characters.count {
            let char = characters[index]
            
            if char == "\"" {
                if inQuotes && index + 1 < characters.count && characters[index + 1] == "\"" {
                    currentField.append("\"")
                    index += 1
                } else {
                    inQuotes.toggle()
                }
            } else if char == "," && !inQuotes {
                currentFields.append(currentField)
                currentField = ""
            } else if (char == "\n" || char == "\r") && !inQuotes {
                if char == "\r" && index + 1 < characters.count && characters[index + 1] == "\n" {
                    index += 1
                }
                currentFields.append(currentField)
                result.append(currentFields)
                currentFields = []
                currentField = ""
            } else {
                currentField.append(char)
            }
            index += 1
        }
        
        if !currentField.isEmpty || !currentFields.isEmpty {
            currentFields.append(currentField)
            result.append(currentFields)
        }
        
        return result
    }
    
    private func showImportResult(message: String) {
        self.importAlertMessage = message
        self.isShowingImportAlert = true
    }
}
