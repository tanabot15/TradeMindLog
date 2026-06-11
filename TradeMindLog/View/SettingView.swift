//
//  SettingView.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/05/13.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Record.tickerCode, order: .forward) private var records: [Record]
    
    @StateObject private var viewModel = SettingViewModel()
    
    @AppStorage("colorScheme") var colorScheme = 0
    @AppStorage("firstWeekday") private var firstWeekday = 1
    @AppStorage("customBuyReasons") private var customBuyReasons: [String] = BuyReason.allCases.map { $0.rawValue }
    @AppStorage("customSellReasons") private var customSellReasons: [String] = SellReason.allCases.map { $0.rawValue }
    
    static let defaultReflectionTemplate = """
        【1. 当初の想定と違った点】
        
        【2. 今回の気付き・反省点】
        
        【3. 次回にどう活かすか】
        
        """
    @AppStorage("reflectionTemplate") private var reflectionTemplate: String = SettingView.defaultReflectionTemplate
    
    @AppStorage("showReflectionBanner") private var showReflectionBanner = true
    
    @AppStorage("showAnalysisPieChart") private var showAnalysisPieChart = true
    @AppStorage("showAnalysisTrendChart") private var showAnalysisTrendChart = true
    @AppStorage("showAnalysisBestWorstCards") private var showAnalysisBestWorstCards = true
    @AppStorage("showAnalysisBarChart") private var showAnalysisBarChart = true
    @AppStorage("showAnalysisStatsList") private var showAnalysisStatsList = true
    
    @State private var isShowingReasonEditSheet = false
    @State private var isShowingTemplateEditSheet = false
    @State private var isShowingAnalysisDisplaySheet = false
    
    // MARK: - Main View
    var body: some View {
        NavigationStack {
            List {
                experimentSection
                generalSettingSection
                dataManagementSection
                appInfoSection
                footerSection
            }
            .navigationTitle("設定")
            .sheet(isPresented: $isShowingReasonEditSheet) {
                ReasonEditSheetView(
                    customBuyReasons: $customBuyReasons,
                    customSellReasons: $customSellReasons
                )
            }
            .sheet(isPresented: $isShowingTemplateEditSheet) {
                TemplateEditSheetView(
                    reflectionTemplate: $reflectionTemplate
                )
            }
            .sheet(isPresented: $isShowingAnalysisDisplaySheet) {
                AnalysisDisplayEditSheetView(
                    showAnalysisPieChart: $showAnalysisPieChart,
                    showAnalysisTrendChart: $showAnalysisTrendChart,
                    showAnalysisBestWorstCards: $showAnalysisBestWorstCards,
                    showAnalysisBarChart: $showAnalysisBarChart,
                    showAnalysisStatsList: $showAnalysisStatsList
                )
            }
            .fileExporter(
                isPresented: $viewModel.isShowingExporter,
                document: viewModel.exportDocument,
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
                isPresented: $viewModel.isShowingImporter,
                allowedContentTypes: [.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let url):
                    guard let selectedURL = url.first else { return }
                    viewModel.importCSV(from: selectedURL, modelContext: modelContext, customBuyReasons: customBuyReasons, customSellReasons: customSellReasons, records: records)
                case .failure(let error):
                    print("CSV selection error: \(error.localizedDescription)")
                }
            }
            .alert("CSVをインポートします", isPresented: $viewModel.isShowingImportAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.importAlertMessage)
            }
            .alert("すべてのデータを削除しますか？", isPresented: $viewModel.isShowingDeleteAleart) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    viewModel.deleteAllRecords(modelContext: modelContext)
                }
            } message: {
                Text("この操作は取り消せません。これまでに登録したすべてのデータが完全に消去されます。")
            }
        }
    }
}

// MARK: - Subviews (Section)
private extension SettingView {
    private var experimentSection: some View {
        Section(header: Text("このアプリはこの実験から始まった...")) {
            Link(destination: viewModel.experimentURL) {
                HStack {
                    Text(viewModel.noteMembershipTitle)
                    Spacer()
                    Image(systemName: "link")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var generalSettingSection: some View {
        Section(header: Text("アプリ設定")) {
            Picker("外観モード", selection: $colorScheme) {
                Text("端末の設定を使う").tag(0)
                Text("ライトモード").tag(1)
                Text("ダークモード").tag(2)
            }
            
            Picker("週の始まり", selection: $firstWeekday) {
                Text("日曜日").tag(1)
                Text("月曜日").tag(2)
            }
                        
            Button {
                isShowingReasonEditSheet = true
            } label: {
                HStack {
                    Text("売買理由のカスタマイズ")
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.secondary)
                }
            }
            
            Button {
                isShowingTemplateEditSheet = true
            } label: {
                HStack {
                    Text("振り返りテンプレートのカスタマイズ")
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.secondary)
                }
            }
            
            Button {
                isShowingAnalysisDisplaySheet = true
            } label: {
                HStack {
                    Text("分析画面のカスタマイズ")
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.secondary)
                }
            }
            
            Toggle("振り返り待ち通知バナーを表示", isOn: $showReflectionBanner)
        }
        
        
    }
    
    private var dataManagementSection: some View {
        Section(header: Text("データ管理")) {
            Button {
                viewModel.generateAndExportCSV(records: records, customBuyReasons: customBuyReasons, customSellReasons: customSellReasons)
            } label: {
                HStack {
                    Text("CSVファイルをエクスポート")
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(Color.secondary)
                }
            }
            
            Button {
                viewModel.isShowingImporter = true
            } label: {
                HStack {
                    Text("CSVファイルをインポート")
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "square.and.arrow.down")
                        .foregroundStyle(Color.secondary)
                }
            }
            
            Button(role: .destructive) {
                viewModel.isShowingDeleteAleart = true
            } label: {
                HStack {
                    Text("すべての記録を削除")
                    Spacer()
                        .font(.subheadline)
                }
            }
        }
    }
    
    private var appInfoSection: some View {
        Section(header: Text("アプリ情報")) {
            HStack {
                Text("Version")
                Spacer()
                // change when updating
                Text("3.8")
                    .foregroundStyle(.secondary)
            }
            
            Link(destination: viewModel.termsOfServiceURL) {
                HStack {
                    Text("ご利用規約")
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "link")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
            }
                                
            Link(destination: viewModel.privacyPolicyURL) {
                HStack {
                    Text("プライバシー ポリシー")
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Image(systemName: "link")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }
            }
        }
    }
    
    private var footerSection: some View {
        Section {
            Text("© 2026 Tanabot")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .listRowBackground(Color.clear)
    }
}

// MARK: - Sheets
// Reason Edit Sheet
struct ReasonEditSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var customBuyReasons: [String]
    @Binding var customSellReasons: [String]
    
    @State private var isShowingResetAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("購入理由")) {
                    ForEach(0..<customBuyReasons.count, id: \.self) { index in
                        HStack(spacing: 12) {
                            let reasonKey = BuyReason.allCases[index]
                            let themeColor = reasonKey.color(customNames: customBuyReasons)
                            
                            Circle()
                                .fill(themeColor)
                                .frame(width: 12, height: 12)
                            
                            TextField("理由を入力", text: $customBuyReasons[index])
                        }
                    }
                }
                
                Section(header: Text("売却理由")) {
                    ForEach(0..<customSellReasons.count, id: \.self) { index in
                        HStack(spacing: 12) {
                            let reasonKey = SellReason.allCases[index]
                            let themeColor = reasonKey.color(customNames: customSellReasons)
                            
                            Circle()
                                .fill(themeColor)
                                .frame(width: 12, height: 12)
                            
                            TextField("理由を入力", text: $customSellReasons[index])
                        }
                    }
                }
                
                Section(header: Text("データ管理")) {
                    Button("売買理由を初期値に戻す", role: .destructive) {
                        isShowingResetAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("売買理由のカスタマイズ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        dismiss()
                    }
                }
            }
            .alert("売買理由を初期値に戻しますか？", isPresented: $isShowingResetAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("初期値に戻す", role: .destructive) {
                    resetToDefaultReasons()
                }
            } message: {
                Text("カスタマイズされた売買理由がすべて初期状態の文言に戻ります。")
            }
        }
    }
    
    private func resetToDefaultReasons() {
        self.customBuyReasons = BuyReason.allCases.map { $0.rawValue }
        self.customSellReasons = SellReason.allCases.map { $0.rawValue }
    }
}

// Template Edit Sheet
struct TemplateEditSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var reflectionTemplate: String
    @State private var isShowingResetAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("テンプレートの文章")) {
                    TextEditor(text: $reflectionTemplate)
                        .frame(minHeight: 180)
                        .font(.body)
                }
                
                Section(header: Text("データ管理")) {
                    Button("売買理由を初期値に戻す", role: .destructive) {
                        isShowingResetAlert = true
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("振り返りテンプレートのカスタマイズ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        dismiss()
                    }
                }
            }
            .alert("テンプレートを初期値に戻しますか？", isPresented: $isShowingResetAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("初期値に戻す", role: .destructive) {
                    resetToDefaultTemplate()
                }
            } message: {
                Text("カスタマイズされた売買理由がすべて初期状態の文言に戻ります。")
            }
        }
    }
    
    private func resetToDefaultTemplate() {
        self.reflectionTemplate = SettingView.defaultReflectionTemplate
    }
}

// Analysis Display Edit Sheet
struct AnalysisDisplayEditSheetView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var showAnalysisPieChart: Bool
    @Binding var showAnalysisTrendChart: Bool
    @Binding var showAnalysisBestWorstCards: Bool
    @Binding var showAnalysisBarChart: Bool
    @Binding var showAnalysisStatsList: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("表示・非表示の切り替え")) {
                    Toggle("理由の比率（円グラフ）", isOn: $showAnalysisPieChart)
                    Toggle("出現トレンド（折れ線グラフ）", isOn: $showAnalysisTrendChart)
                    Toggle("最優秀/要改善パターン（カード）", isOn: $showAnalysisBestWorstCards)
                    Toggle("理由別の平均スコア（棒グラフ）", isOn: $showAnalysisBarChart)
                    Toggle("理由統計データ（リスト）", isOn: $showAnalysisStatsList)
                }
            }
            .navigationTitle("分析画面のカスタマイズ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
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
