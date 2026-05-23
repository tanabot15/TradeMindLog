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
            
    @Bindable var record: Record
    let isNew: Bool
    @State private var isShowingDeleteAlert = false
    
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
                    Picker("Situation", selection: $record.situation) {
                        Text("購入").tag(Situation.buy)
                        Text("売却").tag(Situation.sell)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    if record.situation == .buy {
                        DatePicker("購入日", selection: Binding(
                            get: { record.buyDate ?? Date() },
                            set: { record.buyDate = $0 }
                        ), displayedComponents: .date)
                    } else {
                        DatePicker("売却日", selection: Binding(
                            get: { record.sellDate ?? Date() },
                            set: { record.sellDate = $0 }
                        ), displayedComponents: .date)
                    }
                    
                    if record.situation == .buy {
                        HStack {
                            Text("購入額：")
                            Spacer()
                            TextField("0", value: $record.buyPrice, format: .number)
                                .focused($focusedField, equals: .price)
                                .keyboardType(.decimalPad)
                        }
                    } else {
                        HStack {
                            Text("売却額：")
                            Spacer()
                            TextField("0", value: $record.sellPrice, format: .number)
                                .focused($focusedField, equals: .price)
                                .keyboardType(.decimalPad)
                        }
                    }

                    Stepper("株式数：    \(record.quantity)", value: $record.quantity, in: 100...100000, step: 100)
                }
                
                Section("売買理由") {
                    if record.situation == .buy {
                        Picker("購入理由を選んでください", selection: $record.buyReason) {
                            ForEach(BuyReason.allCases) { reason in
                                Text(reason.localizedName(customNames: customBuyReasons)).tag(reason)
                                
                            }
                        }
                    } else {
                        Picker("売却理由を選んでください", selection: $record.sellReason) {
                            ForEach(SellReason.allCases) { reason in
                                Text(reason.localizedName(customNames: customSellReasons)).tag(reason)
                                
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
            .navigationTitle(isNew ? "Recordの追加" : "Recordの評価・編集")
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
        buyReason: .highProfitMargin,
        sellReason: .profitTaking,
        note: "memomemomemo",
        rating: 3,
        reflection: ""
    )
    
    container.mainContext.insert(testRecord)
    
    return AddRecordView(record: testRecord, isNew: false)
        .modelContainer(container)
//        .preferredColorScheme(.dark)
}
