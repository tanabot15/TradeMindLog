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
    
    var body: some View {
        NavigationStack {
            Form {
                Section() {
                    Picker("Situation", selection: $record.situation) {
                        Text("購入").tag(Situation.buy)
                        Text("売却").tag(Situation.sell)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("株式情報") {
                    TextField("Stock Name", text: $record.stockName)
                    TextField("Ticker Code", text: $record.tickerCode)
                }
                
                Section("取引日") {
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
                                .keyboardType(.decimalPad)
                        }
                    } else {
                        HStack {
                            Text("売却額：")
                            Spacer()
                            TextField("0", value: $record.sellPrice, format: .number)
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
                        .overlay(alignment: .topLeading) {
                            if record.note.isEmpty {
                                Text("なぜ売買したのか...感情や判断をメモ")
                                    .foregroundColor(.gray)
                                    .padding(8)
                            }
                        }
                }
                
                if !isNew {
                    Section {
                        Button(role: .destructive) {
                            modelContext.delete(record)
                            try? modelContext.save()
                            dismiss()
                        } label: {
                            Text("この記録を削除")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .onChange(of: record.situation) { oldValue, newValue in
                if newValue == .buy {
                    record.buyDate = .now
                    record.sellDate = nil
                } else {
                    record.buyDate = nil
                    record.sellDate = .now
                }
            }
            .navigationTitle(isNew ? "Recordの追加" : "Recorの確認・編集")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "Save" : "Done") {
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
                        Button("Cancel") {
                            modelContext.delete(record)
                            try? modelContext.save()
                            dismiss()
                        }
                    }
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
        note: "For Preview",
        reflection: ""
    )
    
    container.mainContext.insert(testRecord)
    
    return AddRecordView(record: testRecord, isNew: false)
        .modelContainer(container)
//        .preferredColorScheme(.dark)
}
