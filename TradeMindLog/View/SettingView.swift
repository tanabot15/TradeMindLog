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
    
    @State private var isShowingReasonEditSheet = false
    @State private var isShowingTemplateEditSheet = false
    
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
            // sheet modifier
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
            // alert modifier
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

// MARK: Subviews (Section)
private extension SettingView {
    
    private var experimentSection: some View {
        Section(header: Text("このアプリはこの実験から始まった...")) {
            Link(destination: viewModel.experimentURL) {
                HStack {
                    Text(viewModel.noteMembershipTitle)
                    Spacer()
                    Image(systemName: "link")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
            }
            
            Button {
                isShowingTemplateEditSheet = true
            } label: {
                HStack {
                    Text("振り返りテンプレートのカスタマイズ")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
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
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.secondary)
                }
            }
            
            Button {
                viewModel.isShowingImporter = true
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
                Text("2.7")
                    .foregroundColor(.secondary)
            }
            
            Link(destination: viewModel.termsOfServiceURL) {
                HStack {
                    Text("ご利用規約")
                        .foregroundColor(.primary)
                    Spacer()
                    Image(systemName: "link")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
                                
            Link(destination: viewModel.privacyPolicyURL) {
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
    }
    
    private var footerSection: some View {
        Section {
            Text("© 2026 Tanabot")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .listRowBackground(Color.clear)
    }
}

// MARK: ReasonEditSheetView
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
                        TextField("理由を入力", text: $customBuyReasons[index])
                    }
                }
                
                Section(header: Text("売却理由")) {
                    ForEach(0..<customSellReasons.count, id: \.self) { index in
                        TextField("理由を入力", text: $customSellReasons[index])
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

// MARK: TemplateEditSheetView
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
                    .foregroundColor(.red)
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
