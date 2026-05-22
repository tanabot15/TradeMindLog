//
//  SettingView.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/05/13.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// csv document
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

struct SettingView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Record.tickerCode, order: .forward) private var records: [Record]
    
    @AppStorage("colorScheme") var colorScheme = 0
    @AppStorage("firstWeekday") private var firstWeekday = 1
    
    @AppStorage("customBuyReasons") private var customBuyReasons: [String] = BuyReason.allCases.map { $0.rawValue }
    @AppStorage("customSellReasons") private var customSellReasons: [String] = SellReason.allCases.map { $0.rawValue }
    
    @State private var isShowingDeleteAleart = false
    @State private var isShowingEditSheet = false
    
    // csv export, import
    @State private var exportDocument: CSVDocument? = nil
    @State private var isShowingExporter = false
//    @State private var isShowingExportAlert = false
//    @State private var exportAlertMessage = ""
    @State private var isShowingImporter = false
    @State private var isShowingImportAlert = false
    @State private var importAlertMessage = ""
    
    // Tanabot Menbership URL
    let experimentURL = URL(string: "https://note.com/tanabot/membership")!
    let noteMembershipTitle = """
    株を勉強して半年で100銘柄買ったら、
    人生は変わるのか？
     （ noteメンバーシップページ ）
    """
    
    let privacyPolicyURL = URL(string: "https://sites.google.com/view/trademindlog/%E3%83%97%E3%83%A9%E3%82%A4%E3%83%90%E3%82%B7%E3%83%BC-%E3%83%9D%E3%83%AA%E3%82%B7%E3%83%BC")!
    let termsOfServiceURL = URL(string: "https://sites.google.com/view/trademindlog/%E3%81%94%E5%88%A9%E7%94%A8%E8%A6%8F%E5%89%87")!
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("このアプリはこの実験から始まった...")) {
                    Link(destination: experimentURL) {
                        HStack {
                            Text(noteMembershipTitle)
                            Spacer()
                            Image(systemName: "link")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("設定")) {
                    Picker("週の始まり", selection: $firstWeekday) {
                        Text("日曜日").tag(1)
                        Text("月曜日").tag(2)
                    }
                    
                    Picker("外観モード", selection: $colorScheme) {
                        Text("端末の設定を使う").tag(0)
                        Text("ライトモード").tag(1)
                        Text("ダークモード").tag(2)
                    }
                    
                    Button {
                        isShowingEditSheet = true
                    } label: {
                        HStack {
                            Text("売買理由のカスタマイズ")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("データ管理")) {
                    Button {
                        generateAndExportCSV()
                    } label: {
                        HStack {
                            Text("CSVファイルをエクスポート")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button {
                         isShowingImporter = true
                    } label: {
                        HStack {
                            Text("CSVファイルをインポート")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "square.and.arrow.down")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(role: .destructive) {
                        isShowingDeleteAleart = true
                    } label: {
                        HStack {
                            Text("すべての記録を削除")
                            Spacer()
                            Image(systemName: "trash")
                                .font(.subheadline)
                        }
                    }
                }
                
                Section(header: Text("アプリ情報")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.9")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: termsOfServiceURL) {
                        HStack {
                            Text("ご利用規約")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "link")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                                        
                    Link(destination: privacyPolicyURL) {
                        HStack {
                            Text("プライバシー ポリシー")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "link")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    Text("© 2026 Tanabot")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Setting")
            .sheet(isPresented: $isShowingEditSheet) {
                ReasonEditSheetView(
                    customBuyReasons: $customBuyReasons,
                    customSellReasons: $customSellReasons
                )
            }
            .fileExporter(
                isPresented: $isShowingExporter,
                document: exportDocument,
                contentType: .commaSeparatedText,
                defaultFilename: "TradeMindLog_\(Date().formattedString())"
            ) { result in
                switch result {
                case .success(let url):
                    print("CSVを正常に保存しました： \(url.lastPathComponent)")
                case .failure(let error):
                    print("CSV保存エラー： \(error.localizedDescription)")
                }
            }
            .fileImporter(
                isPresented: $isShowingImporter,
                allowedContentTypes: [.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let url):
                    guard let selectedURL = url.first else { return }
                    importCSV(from: selectedURL)
                case .failure(let error):
                    print("CSV selection error: \(error.localizedDescription)")
                }
            }
            .alert("CSVをインポートします", isPresented: $isShowingImportAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(importAlertMessage)
            }
            .alert("すべてのデータを削除しますか？", isPresented: $isShowingDeleteAleart) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    deleteAllRecords()
                }
            } message: {
                Text("この操作は取り消せません。これまでに登録したすべてのデータが完全に消去されます。")
            }
        }
    }
    
    private func generateAndExportCSV() {
        var csvString = "ID,状況,銘柄名,ティッカーコード,数量,購入日,購入価格,売却日,売却価格,購入理由,売却理由,ノート,振り返り\n"
        
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
            
            let buyReason = record.buyReason.localizedName(customNames: customBuyReasons)
            let sellReason = record.sellReason.localizedName(customNames: customSellReasons)
            
            let note = "\"\(record.note.replacingOccurrences(of: "\"", with: "\"\""))\""
            let reflection = "\"\(record.reflection.replacingOccurrences(of: "\"", with: "\"\""))\""
            
            let row = "\(id),\(situation),\(stockName),\(ticker),\(qty),\(buyDateStr),\(buyPrice),\(sellDateStr),\(sellPrice),\(buyReason),\(sellReason),\(note),\(reflection)\n"
            csvString.append(row)
        }
        
        self.exportDocument = CSVDocument(text: csvString)
        self.isShowingExporter = true
    }
    
    private func importCSV(from url: URL) {
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
                
                let buyReason = BuyReason.allCases.first { $0.localizedName(customNames: customBuyReasons) == fields[10] } ?? .others
                let sellReason = SellReason.allCases.first { $0.localizedName(customNames: customSellReasons) == fields[11] } ?? .others
                
                let note = fields[12]
                let reflection = fields[13]
                
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
                    buyReason: buyReason,
                    sellReason: sellReason,
                    note: note,
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
        
    private func deleteAllRecords() {
        do {
            try modelContext.delete(model: Record.self)
            try modelContext.save()
        } catch {
            print("Failed to delete all records: \(error)")
        }
    }
}

struct ReasonEditSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var customBuyReasons: [String]
    @Binding var customSellReasons: [String]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("購入理由")) {
                    ForEach(0..<customBuyReasons.count, id: \.self) { index in
                        TextField("理由を入力", text: $customBuyReasons[index])
                    }
                }
                
                Section(header: Text("売却理由")) {
                    ForEach(0..<customSellReasons.count, id: \.self) { index in
                        TextField("理由を入力", text: $customSellReasons[index])
                    }
                }
            }
            .navigationTitle("売買理由のカスタマイズ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

extension Date {
    func formattedString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmmss"
        return f.string(from: self)
    }
}

#Preview {
    SettingView()
//        .preferredColorScheme(.dark)
}
