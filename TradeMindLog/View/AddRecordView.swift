//
//  AddRecordView.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/05/13.
//

import SwiftUI
import SwiftData

struct AddRecordView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("customBuyReasons") private var customBuyReasons: [String] = []
    @AppStorage("customSellReasons") private var customSellReasons: [String] = []
    @AppStorage("reflectionTemplate") private var reflectionTemplate: String = """
        【1. 当初の想定と違った点】
        
        【2. 今回の気付き・反省点】
        
        【3. 次回にどう活かすか】
        
        """
            
    @Bindable var record: Record
    let isNew: Bool
    @State private var isShowingDeleteAlert = false
    
    @State private var priceString: String = ""
    
    enum Field: Hashable {
        case stockName
        case tickerCode
        case price
    }
    @FocusState private var focusedField: Field?
    
    var body: some View {
        NavigationStack {
            Form {
                if !isNew {
                    Section("トレードの振り返り") {
                        HStack {
                            Text("評価：")
                            HStack(spacing: 8) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= record.rating ? "star.fill" : "star")
                                        .foregroundColor(.yellow)
                                        .font(.title3)
                                        .onTapGesture {
                                            record.rating = star
                                        }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        
                        TextEditor(text: $record.reflection)
                            .frame(minHeight: 80)
                            .overlay(alignment: .topLeading) {
                                if record.reflection.isEmpty {
                                    Text("一定期間が経ってからの気付きや、反省点、詳細な評価、今後の学習ポイントなどを記述しましょう")
                                        .foregroundColor(.gray)
                                }
                            }
                        
                        if record.reflection.isEmpty {
                            Button(action: {
                                insertTemplate()
                            }) {
                                Label("振り返りテンプレートを挿入", systemImage: "doc.text.badge.plus")
                            }
                            .buttonStyle(.bordered)
                            .tint(.indigo)
                            .padding(.vertical, 2)
                        }
                    }
                }
                
                Section("株式情報") {
                    TextField("株式名", text: $record.stockName)
                        .focused($focusedField, equals: .stockName)
                        .submitLabel(.next)
                    
                    TextField("銘柄コード", text: $record.tickerCode)
                        .focused($focusedField, equals: .tickerCode)
                        .submitLabel(.next)
                }
                
                Section("取引情報") {
                    if isNew {
                        Picker("Situation", selection: $record.situation) {
                            Text("購入").tag(Situation.buy)
                            Text("売却").tag(Situation.sell)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    } else {
                        Text("取引別：　\(record.situation.rawValue)")
                    }
                    
                    if record.situation == .buy {
                        DatePicker("購入日：", selection: Binding(
                            get: { record.buyDate ?? Date() },
                            set: { record.buyDate = $0 }
                        ), displayedComponents: .date)
                    } else {
                        DatePicker("売却日", selection: Binding(
                            get: { record.sellDate ?? Date() },
                            set: { record.sellDate = $0 }
                        ), displayedComponents: .date)
                    }
                    
                    HStack {
                        Text(record.situation == .buy ? "購入額：" : "売却額：")
                        Spacer()
                        TextField("0", text: $priceString)
                            .focused($focusedField, equals: .price)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: priceString) { oldValue, newValue in
                                if oldValue == "0" && newValue.count > 1 {
                                    priceString = String(newValue.dropFirst())
                                }
                            }
                            .padding(.horizontal)
                    }
                    
                    Stepper("株式数：    \(record.quantity)", value: $record.quantity, in: 100...100000, step: 100)
                }
                
                Section("売買理由（複数選択可）") {
                    if record.situation == .buy {
                        ForEach(BuyReason.allCases) { reason in
                            Button {
                                toggleBuyReason(reason)
                            } label: {
                                HStack {
                                    Text(reason.localizedName(customNames: customBuyReasons))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if record.buyReasons.contains(reason) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                            .fontWeight(.bold)
                                    }
                                }
                            }
                        }
                    } else {
                        ForEach(SellReason.allCases) { reason in
                            Button {
                                toggleSellReason(reason)
                            } label: {
                                HStack {
                                    Text(reason.localizedName(customNames: customSellReasons))
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if record.sellReasons.contains(reason) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.orange)
                                            .fontWeight(.bold)
                                    }
                                }
                            }
                        }
                    }
                    
                    TextEditor(text: $record.note)
                        .frame(minHeight: 80)
                        .overlay(alignment: .topLeading) {
                            if record.note.isEmpty {
                                Text("なぜ売買したのか、その時の感情や判断をメモしましょう")
                                    .foregroundColor(.gray)
                            }
                        }
                }
                
                if !isNew {
                    Section {
                        Button(role: .destructive) {
                            isShowingDeleteAlert = true
                        } label: {
                            Text("この記録を削除")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                
            }
            .navigationTitle(isNew ? "レコードの追加" : "レコードの評価・編集")
            .onAppear {
                let currentPrice = record.situation == .buy ? record.buyPrice : record.sellPrice
                
                if currentPrice == 0.0 {
                    priceString = "0"
                } else {
                    priceString = currentPrice.truncatingRemainder(dividingBy: 1) == 0 ? "\(currentPrice.rounded())" : "\(currentPrice)"
                }
            }
            .onChange(of: record.situation) { oldValue, newValue in
                if newValue == .buy {
                    if let savedDate = record.sellDate {
                        record.buyDate = savedDate
                    }
                    record.sellDate = nil
                } else {
                    if let savedDate = record.buyDate {
                        record.sellDate = savedDate
                    }
                    record.buyDate = nil
                }
                
                let currentPrice = newValue == .buy ? record.buyPrice : record.sellPrice
                priceString = currentPrice == 0.0 ? "0" : (currentPrice.truncatingRemainder(dividingBy: 1) == 0 ? "\(currentPrice.rounded())" : "\(currentPrice)")
            }
            .alert("この記録を削除しますか？", isPresented: $isShowingDeleteAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("削除する", role: .destructive) {
                    modelContext.delete(record)
                    try? modelContext.save()
                    dismiss()
                }
            } message: {
                Text("この操作は取り消せません。この取引記録が完全に削除されます。")
            }
            .onSubmit {
                switch focusedField {
                case .stockName:
                    focusedField = .tickerCode
                default:
                    focusedField = nil
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "保存" : "完了") {
                        do {
                            try modelContext.save()
                            dismiss()
                        } catch {
                            print("Save Error: \(error)")
                        }
                    }
                    .disabled(record.stockName.isEmpty || record.tickerCode.isEmpty)
                }
                if isNew {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") {
                            modelContext.delete(record)
                            try? modelContext.save()
                            dismiss()
                        }
                    }
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") {
                        focusedField = nil
                    }
                    .bold()
                }
            }
        }
    }
    
    private func toggleBuyReason(_ reason: BuyReason) {
        if record.buyReasons.contains(reason) {
            record.buyReasons.removeAll { $0 == reason }
        } else {
            record.buyReasons.append(reason)
        }
    }
    
    private func toggleSellReason(_ reason: SellReason) {
        if record.sellReasons.contains(reason) {
            record.sellReasons.removeAll { $0 == reason }
        } else {
            record.sellReasons.append(reason)
        }
    }
    
    private func insertTemplate() {
        if record.reflection.isEmpty {
            record.reflection = reflectionTemplate
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Record.self, configurations: config)
    
    let testRecord = Record(
        id: UUID(),
        stockName: "Test",
        tickerCode: "0000",
        buyDate: .now,
        sellDate: .now,
        buyPrice: 1000.0,
        sellPrice: 1200.0,
        quantity: 200,
        situation: .buy,
        buyReasons: [.highProfitMargin, .technicalAnalysis],
        sellReasons: [.profitTaking],
        note: "memomemomemo",
        rating: 3,
        reflection: ""
    )
    
    container.mainContext.insert(testRecord)
    
    return AddRecordView(record: testRecord, isNew: true)
        .modelContainer(container)
//        .preferredColorScheme(.dark)
}
