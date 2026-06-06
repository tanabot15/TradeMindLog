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
    
    @Binding var selectedSituation: Situation
    @Binding var selectedTimeFilter: TimeFilter
    
    @State private var recordToCreate: Record?
    @State private var searchText = ""
    @State private var showUnratedOnly = false
    @State private var isShowingCalendar = false
    
    @State private var isShowingFilterSheet = false
    @State private var selectedBuyFilters: Set<BuyReason> = []
    @State private var selectedSellFilters: Set<SellReason> = []
    @State private var isAndFilterMode = false
    
    private var isCompletelyEmptyForSituation: Bool {
        !records.contains { $0.situation == selectedSituation }
    }
    
    private var isReasonFilterActive: Bool {
        selectedSituation == .buy ? !selectedBuyFilters.isEmpty : !selectedSellFilters.isEmpty
    }
    
    private var isAnyFilterActive: Bool {
        isReasonFilterActive || selectedTimeFilter != .all
    }
    
    var currentSituationRecords: [Record] {
        let situationRecords = records.filter { $0.situation == selectedSituation }
        let now = Date()
        let calendar = Calendar.current
        
        return situationRecords.filter { record in
            let targetDate = (record.situation == .buy ? record.buyDate : record.sellDate) ?? now
            
            switch selectedTimeFilter {
            case .all:
                return true
            case .thisYear:
                return calendar.isDate(targetDate, equalTo: now, toGranularity: .year)
            case .thisMonth:
                return calendar.isDate(targetDate, equalTo: now, toGranularity: .month)
            }
        }
    }
    
    var filteredRecords: [Record] {
        var result = currentSituationRecords
        
        if showUnratedOnly {
            result = result.filter { $0.rating == 0 }
        }
        
        if !searchText.isEmpty {
            result = result.filter { record in
                record.stockName.localizedStandardContains(searchText) ||
                record.tickerCode.localizedStandardContains(searchText) ||
                record.note.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if selectedSituation == .buy && isReasonFilterActive {
            result = result.filter { record in
                if isAndFilterMode {
                    return selectedBuyFilters.allSatisfy { record.buyReasons.contains($0) }
                } else {
                    return selectedBuyFilters.contains { record.buyReasons.contains($0) }
                }
            }
        } else if selectedSituation == .sell && isReasonFilterActive {
            result = result.filter { record in
                if isAndFilterMode {
                    return selectedSellFilters.allSatisfy { record.sellReasons.contains($0) }
                } else {
                    return selectedSellFilters.contains { record.sellReasons.contains($0) }
                }
            }
        }
        
        return result
    }
    
    var unratedCount: Int {
        currentSituationRecords.filter { $0.rating == 0 }.count
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isCompletelyEmptyForSituation {
                    VStack {
                        Spacer()
                        EmptyStateView(type: .completelyEmpty, situation: selectedSituation) {
                            createNewRecord()
                        }
                        Spacer()
                    }
                } else if currentSituationRecords.isEmpty {
                    VStack {
                        Spacer()
                        EmptyStateView(type: .filterEmpty(timeFilterText: selectedTimeFilter.rawValue), situation: selectedSituation)
                        Spacer()
                    }
                } else {
                    VStack(spacing: 0) {
                        notificationBannerView
                        recordListView(for: filteredRecords)
                    }
                }
                
                VStack {
                    Spacer()
                    bottomAddRecordButton
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            .navigationTitle("トレードレコード")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "銘柄名またはコードで検索")
            .onChange(of: selectedSituation) { oldValue, newValue in
                searchText = ""
                showUnratedOnly = false
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingCalendar = true
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Picker("Situation", selection: $selectedSituation) {
                        Text("購入").tag(Situation.buy)
                        Text("売却").tag(Situation.sell)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 140)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingFilterSheet = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .fontWeight(isReasonFilterActive ? .semibold : .regular)
                            .foregroundStyle(isReasonFilterActive ? .blue : .primary)
                        
                    }
                }
            }
            .sheet(item: $recordToCreate) { newRecord in
                AddRecordView(record: newRecord, isNew: true)
            }
            .sheet(isPresented: $isShowingCalendar) {
                CalendarView()
                    .presentationDetents([.large, .medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isShowingFilterSheet) {
                filterSheet
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
                        .foregroundStyle(.pink)
                    
                    Text(showUnratedOnly ? "振り返り待ちの \(unratedCount) 件を表示中（タップで解除）" : "振り返り待ちのレコードが \(unratedCount) 件あります")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.primary)
                    
                    Spacer()
                    
                    Image(systemName: showUnratedOnly ? "xmark.circle.fill" : "chevron.right")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
                .padding()
                .background(showUnratedOnly ? Color.pink.opacity(0.2) : Color(.secondarySystemBackground))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }
    
    // List View
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
                        VStack(spacing: 4) {
                            HStack {
                                Text(record.tickerCode)
                                    .font(.footnote)
                                Text(record.stockName)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                HStack(spacing: 2) {
                                    Text("評価：")
                                        .font(.headline)
                                    
                                    if record.rating > 0 {
                                        ForEach(1...5, id: \.self) { star in
                                            Image(systemName: star <= record.rating ? "star.fill" : "star")
                                                .foregroundStyle(.yellow)
                                                .font(.caption2)
                                        }
                                    } else {
                                        Text("未実施         ")
                                            .font(.subheadline)
                                            .italic()
                                    }
                                }
                            }
                            
                            HStack {
                                Text("\(record.situation.rawValue)理由：")
                                    .font(.caption)
                                ReasonTagsView(record: record)
                            }
                        }
                    }
                    .listRowBackground(selectedSituation == Situation.buy ? Color.blue.opacity(0.40) : Color.orange.opacity(0.40))
                }
                .onDelete { offsets in
                    deleteRecords(at: offsets, from: filterRecords)
                }
            }
        }
    }
    
    // bottomAddRecordButton
    @ViewBuilder
    private var bottomAddRecordButton: some View {
        Button {
            createNewRecord()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("新規\(selectedSituation.rawValue)レコードを追加")
                    .font(.subheadline)
                    .bold()
            }
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: selectedSituation == .buy ? [.blue, Color.blue.opacity(0.8)] : [.orange, Color.orange.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .shadow(color: (selectedSituation == .buy ? Color.blue : Color.orange).opacity(0.25), radius: 3, x: 0, y: 2)
        }
        .padding(.vertical, 12)
        .background(.clear)
    }
    
    // Filter Sheet
    @ViewBuilder
    private var filterSheet: some View {
        NavigationStack {
            Form {
                Section(header: Text("期間")) {
                    Picker("期間", selection: $selectedTimeFilter) {
                        ForEach(TimeFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("売買理由")) {
                    Picker("マッチ条件", selection: $isAndFilterMode) {
                        Text("OR検索").tag(false)
                        Text("AND検索").tag(true)
                    }
                    .pickerStyle(.segmented)
                    
                    if selectedSituation == .buy {
                        ForEach(BuyReason.allCases) { reason in
                            Button {
                                if selectedBuyFilters.contains(reason) {
                                    selectedBuyFilters.remove(reason)
                                } else {
                                    selectedBuyFilters.insert(reason)
                                }
                            } label: {
                                HStack {
                                    Text(reason.localizedName(customNames: customBuyReasons))
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                    if selectedBuyFilters.contains(reason) {
                                        Image(systemName: "checkmark")
                                            .bold()
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                        }
                    } else {
                        ForEach(SellReason.allCases) { reason in
                            Button {
                                if selectedSellFilters.contains(reason) {
                                    selectedSellFilters.remove(reason)
                                } else {
                                    selectedSellFilters.insert(reason)
                                }
                            } label: {
                                HStack {
                                    Text(reason.localizedName(customNames: customBuyReasons))
                                        .foregroundStyle(Color.primary)
                                    Spacer()
                                    if selectedSellFilters.contains(reason) {
                                        Image(systemName: "checkmark")
                                            .bold()
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("フィルター")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        isShowingFilterSheet = false
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    if isAnyFilterActive {
                        Button {
                            withAnimation {
                                selectedBuyFilters.removeAll()
                                selectedSellFilters.removeAll()
                                selectedTimeFilter = .all
                                isShowingFilterSheet = false
                            }
                        } label: {
                            Text("クリア")
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func formatFirstReason(for record: Record) -> String {
        if record.situation == .buy {
            guard let firstReason = record.buyReasons.first else { return "なし" }
            return firstReason.localizedName(customNames: customBuyReasons)
        } else {
            guard let firstReason = record.sellReasons.first else { return "なし" }
            return firstReason.localizedName(customNames: customSellReasons)
        }
    }
    
    private func getExtraReasonsCount(for record: Record) -> Int? {
        let count = record.situation == .buy ? record.buyReasons.count : record.sellReasons.count
        return count > 1 ? (count - 1) : nil
    }
    
    func deleteRecords(at offsets: IndexSet, from filteredList: [Record]) {
        for offset in offsets {
            let record = filteredList[offset]
            modelContext.delete(record)
        }
    }
    
    private func createNewRecord() {
        let isBuy = selectedSituation == .buy
        
        let newRecord = Record(
            id: UUID(),
            stockName: "",
            tickerCode: "",
            buyDate: isBuy ? .now : nil,
            sellDate: isBuy ? nil : .now,
            buyPrice: 0.0,
            sellPrice: 0.0,
            quantity: 100,
            situation: isBuy ? .buy : .sell,
            buyReasons: [],
            sellReasons: [],
            note: "",
            rating: 0,
            reflection: ""
        )
        modelContext.insert(newRecord)
        recordToCreate = newRecord
    }
}

#Preview {
    ListView(selectedSituation: .constant(.buy), selectedTimeFilter: .constant(.all))
        .modelContainer(previewContainer)
//        .preferredColorScheme(.dark)
}
