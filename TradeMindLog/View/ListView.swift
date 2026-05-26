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
    @AppStorage("showReflectionBanner") private var showReflectionBanner = true
    
    @State private var selectedSituation: Situation = .buy
    @State private var recordToCreate: Record?
    @State private var searchText = ""
    
    @State private var showUnratedOnly = false
    
    var currentSituationRecords: [Record] {
        records.filter { $0.situation == selectedSituation}
    }
    
    var unratedCount: Int {
        currentSituationRecords.filter { $0.rating == 0 }.count
    }
    
    var filteredRecords: [Record] {
        var baseRecords = currentSituationRecords
        
        if showUnratedOnly {
            baseRecords = baseRecords.filter { $0.rating == 0 }
        }
        
        if searchText.isEmpty {
            return baseRecords
        } else {
            return baseRecords.filter { record in
                record.stockName.localizedStandardContains(searchText) ||
                record.tickerCode.localizedStandardContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            if currentSituationRecords.isEmpty {
                VStack(spacing: 0) {
                    pickerView
                    emptyStateView(for: selectedSituation.rawValue)
                }
                .navigationTitle("Records")
                .toolbar {
                    Button("Add Record", systemImage: "plus") {
                        createNewRecord()
                    }
                }
                .sheet(item: $recordToCreate) { newRecord in
                    AddRecordView(record: newRecord, isNew: true)
                }
            } else {
                VStack(spacing: 0) {
                    notificationBannerView
                    pickerView
                    recordListView(for: filteredRecords)
                        .scrollContentBackground(.hidden)
                        .background(Color(.systemBackground))
                        .navigationTitle("Records")
                        .searchable(text: $searchText, prompt: "銘柄名またはコードで検索")
                        .onChange(of: selectedSituation) { oldValue, newValue in
                            searchText = ""
                            showUnratedOnly = false
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
        }
    }
    
    // Notification Banner View
    @ViewBuilder
    private var notificationBannerView: some View {
        if showReflectionBanner && unratedCount > 0 {
            Button(action: {
                withAnimation {
                    showUnratedOnly.toggle()
                }
            }) {
                HStack {
                    Image(systemName: showUnratedOnly ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    
                    Text(showUnratedOnly ? "振り返り待ちの \(unratedCount) 件を表示中（タップで解除）" : "振り返り待ちのレコードが \(unratedCount) 件あります")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: showUnratedOnly ? "xmark.circle.fill" : "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }
                .padding()
                .background(showUnratedOnly ? Color.orange.opacity(0.2) : Color(.secondarySystemBackground))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
    
    private var pickerView: some View {
        Picker("Situation", selection: $selectedSituation) {
            Text("購入").tag(Situation.buy)
            Text("売却").tag(Situation.sell)
        }
        .pickerStyle(.segmented)
        .padding()
    }
    
    @ViewBuilder
    private func emptyStateView(for situation: String) -> some View {
        ContentUnavailableView {
            Label(
                "最初の\(situation)取引を記録しましょう",
                systemImage: situation == "購入" ? "tray.and.arrow.down" : "tray.and.arrow.up"
            )
        } description: {
            Text("投資した銘柄の情報を入力して、あなたのトレードの記録を始めましょう")
        } actions: {
            Button(action: {
                createNewRecord()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("\(situation)の記録を追加")
                }
                .bold()
                .font(.headline)
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(situation == "購入" ? .blue.opacity(0.8) : .red.opacity(0.8))
        }
    }
    
    @ViewBuilder
    private func recordListView(for filterRecords: [Record]) -> some View {
        List {
            if filterRecords.isEmpty {
                if showUnratedOnly {
                    ContentUnavailableView {
                        Label("振り返りまちはありません", systemImage: "checkmark.circle")
                    } description: {
                        Text("すべての\(selectedSituation.rawValue)レコードの振り返りが完了しています")
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ContentUnavailableView.search(text: searchText)
                        .listRowBackground(Color.clear)
                }
            } else {
                ForEach(filterRecords) { record in
                    NavigationLink(destination: AddRecordView(record: record, isNew: false)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(record.tickerCode)
                                    .font(.footnote)
                                Text(record.stockName)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                HStack {
                                    Text(" \(record.quantity)株")
                                    Text("/")
                                    Text("\(record.situation == .buy ? record.buyPrice : record.sellPrice, specifier: "%.0f") 円")
                                }
                                .font(.callout)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 8) {
                                Text("理由：\(record.situation == .buy ? record.buyReason.localizedName(customNames: customBuyReasons) : record.sellReason.localizedName(customNames: customSellReasons))")
                                    .font(.headline)
                                
                                HStack(spacing: 2) {
                                    Text("評価：")
                                        .font(.headline)
                                    
                                    if record.rating > 0 {
                                        ForEach(1...5, id: \.self) { star in
                                            Image(systemName: star <= record.rating ? "star.fill" : "star")
                                                .foregroundColor(.yellow)
                                                .font(.caption2)
                                        }
                                    } else {
                                        Text("未実施")
                                            .font(.subheadline)
                                            .italic()
                                    }
                                }
                            }
                        }
                    }
                    .listRowBackground(selectedSituation == Situation.buy ? Color.blue.opacity(0.40) : Color.red.opacity(0.40))
                }
                .onDelete { offsets in
                    deleteRecords(at: offsets, from: filterRecords)
                }
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
            situation: selectedSituation == Situation.buy ? .buy : .sell,
            buyReason: .others,
            sellReason: .others,
            note: "",
            rating: 0,
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
