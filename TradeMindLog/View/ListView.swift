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
    
    @AppStorage("customBuyReasons") private var customBuyReasons: [String] = []
    @AppStorage("customSellReasons") private var customSellReasons: [String] = []
    
    @State private var selectedSituation = "購入"
    @State private var recordToCreate: Record?
    
    @State private var searchText = ""
    
    var currentSituationRecords: [Record] {
        records.filter { $0.situation.rawValue == selectedSituation}
    }
    
    var filteredRecords: [Record] {
        if searchText.isEmpty {
            return currentSituationRecords
        } else {
            return currentSituationRecords.filter { record in
                record.stockName.localizedStandardContains(searchText) ||
                record.tickerCode.localizedStandardContains(searchText)
            }
        }
    }
    
    // delete afterwords
    var buyRecords: [Record] {
        records.filter { $0.situation.rawValue == "購入" }
    }
    
    var sellRecords: [Record] {
        records.filter { $0.situation.rawValue == "売却" }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Buy or Sell", selection: $selectedSituation) {
                    Text("購入").tag("購入")
                    Text("売却").tag("売却")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 10)
                .padding(.bottom, 5)
                
                if currentSituationRecords.isEmpty {
                    emptyStateView(for: selectedSituation)
                } else if filteredRecords.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    recordListView(for: filteredRecords)
                }
            }
            
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            .navigationTitle("Records")
            .searchable(text: $searchText, prompt: "銘柄名またはコードで検索")
            .onChange(of: selectedSituation) { oldValue, newValue in
                searchText = ""
            }
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
    
    @ViewBuilder
    private func emptyStateView(for situation: String) -> some View {
        ContentUnavailableView(
            "最初の\(situation)取引を記録しましょう",
            systemImage: situation == "購入" ? "tray.and.arrow.down" : "tray.and.arrow.up",
            description: Text("右上の「+」ボタンから、投資した銘柄の情報を入力して記録を始めましょう。")
        )
    }
    
    @ViewBuilder
    private func recordListView(for filterRecords: [Record]) -> some View {
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
                            Text("理由：\(record.situation == .buy ? record.buyReason.localizedName(customNames: customBuyReasons) : record.sellReason.localizedName(customNames: customSellReasons))")
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
                .listRowBackground(selectedSituation == "購入" ? Color.blue.opacity(0.40) : Color.red.opacity(0.40))
            }
            .onDelete { offsets in
                deleteRecords(at: offsets, from: filterRecords)
            }
        }
    }
    
    func deleteRecords(at offsets: IndexSet, from filteredList: [Record]) {
        for offset in offsets {
            let record = filteredList[offset]
            modelContext.delete(record)
        }
    }
    
    private func createNewRecord() {
        let newRecord = Record(
            id: UUID(),
            stockName: "",
            tickerCode: "",
            buyDate: .now,
            sellDate: nil,
            buyPrice: 0.0,
            sellPrice: 0.0,
            quantity: 100,
            situation: .buy,
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
//        .preferredColorScheme(.dark)
}
