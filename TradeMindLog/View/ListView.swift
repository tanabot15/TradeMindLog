//
//  ListView.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/05/13.
//

import SwiftUI
import SwiftData

struct ListView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Record.buyDate, order: .reverse) private var records: [Record]
    
    @State private var selectedSituation = "購入"
    @State private var recordToCreate: Record?
    
    var filterRecords: [Record] {
        records.filter { $0.situation.rawValue == selectedSituation}
    }
    
    var body: some View {
        NavigationStack {
            Picker("Buy or Sell", selection: $selectedSituation) {
                Text("購入").tag("購入")
                Text("売却").tag("売却")
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 10)
            
            List {
                ForEach(filterRecords) { record in
                    NavigationLink(destination: AddRecordView(record: record, isNew: false)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(record.tickerCode)
                                    .font(.footnote)
                                Text(record.stockName)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("理由：\(record.situation == .buy ? record.buyReason.rawValue : record.sellReason.rawValue)")
                                    .font(.headline)
                                HStack {
                                    Text("\(record.quantity)株")
                                    Text(" / ")
                                    Text("\(record.situation == .buy ? record.buyPrice : record.sellPrice, specifier: "%.1f") 円")
                                }
                                .font(.callout)
                            }
                        }
                    }
                    .listRowBackground(selectedSituation == "購入" ? Color.blue.opacity(0.1) : Color.red.opacity(0.1))
                }
                .onDelete(perform: deleteRecords)
            }
            .scrollContentBackground(.hidden)
            .background(Color.white)
            .navigationTitle("Records")
            .toolbar {
                Button("Add Record", systemImage: "plus") {
                    createNewRecord()
                }
            }
            .sheet(item: $recordToCreate) { newRecord in
                AddRecordView(record: newRecord, isNew: true)
            }
        }
    }
    
    func deleteRecords(at offsets: IndexSet) {
        for offset in offsets {
            let record = records[offset]
            modelContext.delete(record)
        }
    }
    
    private func createNewRecord() {
        let newRecord = Record(
            id: UUID(),
            stockName: "",
            tickerCode: "",
            buyDate: .now,
            sellDate: .now,
            buyPrice: 0.0,
            sellPrice: 0.0,
            quantity: 100,
            situation: selectedSituation == "購入" ? .buy : .sell,
            buyReason: .others,
            sellReason: .others,
            note: "",
            reflection: ""
        )
        modelContext.insert(newRecord)
        recordToCreate = newRecord
    }
}

#Preview {
    ListView()
        .modelContainer(previewContainer)
}
