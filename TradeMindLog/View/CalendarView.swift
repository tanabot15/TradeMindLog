//
//  CalendarView.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/05/13.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \Record.sellDate, order: .reverse) private var records: [Record]
    
    @AppStorage("firstWeekday") private var firstWeekday = 1
    @AppStorage("customBuyReasons") private var customBuyReasons: [String] = []
    @AppStorage("customSellReasons") private var customSellReasons: [String] = []
    
    @State private var selectedDate: DateComponents? = nil
    @State private var recordToCreate: Record?
    
    var filteredRecords: (buy: [Record], sell: [Record]) {
        guard let date = selectedDate?.date else { return ([], []) }
        
        let buy = records.filter { record in
            if let bDate = record.buyDate {
                return Calendar.current.isDate(bDate, inSameDayAs: date) && record.situation == .buy
            }
            return false
        }
        let sell = records.filter { record in
            if let sDate = record.sellDate {
                return Calendar.current.isDate(sDate, inSameDayAs: date) && record.situation == .sell
            }
            return false
        }
        return (buy, sell)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    CalendarViewRepresentable(
                        records: records,
                        firstWeekday: firstWeekday,
                        selectedDate: $selectedDate
                    )
                        .id("\(records.count)-\(firstWeekday)")
                        .frame(height: 400)
                        .listRowInsets(EdgeInsets())
                        .padding(3)
                }
                .listRowBackground(Color.clear)
                
                if filteredRecords.buy.isEmpty && filteredRecords.sell.isEmpty {
                    Text("Recordがありません")
                } else {
                    // buy section
                    recordSection(title: "購入Record", records: filteredRecords.buy, color: .blue)
                    // sell section
                    recordSection(title: "売却Records", records: filteredRecords.sell, color: .red)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            .navigationTitle("Calendar")
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
    
    // Section
    @ViewBuilder
    private func recordSection(title: String, records: [Record], color: Color) -> some View {
        if !records.isEmpty {
            Section(header: Text(title)) {
                ForEach(records) { record in
                    NavigationLink(destination: AddRecordView(record: record, isNew: false)) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(record.tickerCode)
                                    .font(.footnote)
                                Text(record.stockName)
                                    .font(.title3).fontWeight(.semibold)
                                }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                let reason = record.situation == .buy ? record.buyReason.localizedName(customNames: customBuyReasons) : record.buyReason.localizedName(customNames: customSellReasons)
                                let price = record.situation == .buy ? record.buyPrice : record.sellPrice
                                        
                                Text("理由：\(reason)").font(.subheadline).bold()
                                HStack(spacing: 4) {
                                    Text("\(record.quantity)株")
                                    Text("/")
                                    Text("\(price, specifier: "%.1f")円")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .listRowBackground(color.opacity(0.40))
                }
                .onDelete(perform: { offsets in deleteSpecificRecords(at: offsets, from: records) })
            }
        }
    }
    
    private func deleteSpecificRecords(at offsets: IndexSet, from list: [Record]) {
        for offset in offsets {
            modelContext.delete(list[offset])
        }
    }
    
    // UICalendarView Wrapper
    struct CalendarViewRepresentable: UIViewRepresentable {
        let records: [Record]
        let firstWeekday: Int
        @Binding var selectedDate: DateComponents?
        
        func makeUIView(context: Context) -> UICalendarView {
            let calendarView = UICalendarView()
            calendarView.calendar = Calendar.current
            calendarView.calendar.firstWeekday = firstWeekday
            calendarView.locale = Locale(identifier: "ja_JP")
            
            let dateSelection = UICalendarSelectionSingleDate(delegate: context.coordinator)
            calendarView.selectionBehavior = dateSelection
            calendarView.delegate = context.coordinator
            
            calendarView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
            calendarView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                
            return calendarView
        }
        
        func updateUIView(_ uiView: UICalendarView, context: Context) {
            uiView.calendar.firstWeekday = firstWeekday

            let buyDates = records.compactMap { record -> DateComponents? in
                guard let bDate = record.buyDate else { return nil }
                return Calendar.current.dateComponents([.year, .month, .day], from: bDate)
            }
            let sellDates = records.compactMap { record -> DateComponents? in
                guard let sDate = record.sellDate else { return nil }
                return Calendar.current.dateComponents([.year, .month, .day], from: sDate)
            }
            let allComponents = Array(Set(buyDates + sellDates))
            
            DispatchQueue.main.async {
                uiView.reloadDecorations(forDateComponents: allComponents, animated: true)
            }
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator(parent: self)
        }
        
        class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
            var parent: CalendarViewRepresentable
            
            init(parent: CalendarViewRepresentable) {
                self.parent = parent
            }
            
            // show dots under date
            func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
                guard let date = dateComponents.date else { return nil }
                
                let hasBuyRecord = parent.records.contains { record in
                    guard record.situation == .buy, let bDate = record.buyDate else { return false }
                    return Calendar.current.isDate(bDate, inSameDayAs: date)
                }
                
                let hasSellRecord = parent.records.contains { record in
                    guard record.situation == .sell, let sDate = record.sellDate else { return false }
                    return Calendar.current.isDate(sDate, inSameDayAs: date)
                }
                        
                if hasBuyRecord && hasSellRecord {
                    return .default(color: .systemPurple, size: .medium)
                } else if hasBuyRecord {
                    return .default(color: .systemBlue, size: .medium)
                } else if hasSellRecord {
                    return .default(color: .systemRed, size: .medium)
                }
                
                return nil
            }
            
            func calendar(_ calendar: UICalendarView, didSelect dateComponents: DateComponents) {
                parent.selectedDate = dateComponents
            }
            
            func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
                parent.selectedDate = dateComponents
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
        let defaultDate = selectedDate?.date ?? .now
        
        let newRecord = Record(
            id: UUID(),
            stockName: "",
            tickerCode: "",
            buyDate: defaultDate,
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
    CalendarView()
        .modelContainer(previewContainer)
//        .preferredColorScheme(.dark)
}
