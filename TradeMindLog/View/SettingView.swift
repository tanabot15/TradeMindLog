//
//  SettingView.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/05/13.
//

import SwiftUI
import SwiftData

struct SettingView: View {
    @Environment(\.modelContext) private var modelContext
    
    @AppStorage("colorScheme") var colorScheme = 0
    // first weekday (1:Sunday, 2: Monday)
    @AppStorage("firstWeekday") private var firstWeekday = 1
    
    @State private var isShowingDeleteAleart = false
    
    // Tanabot Menbership URL
    let experimentURL = URL(string: "https://note.com/tanabot/membership")!
    let noteMembershipTitle = """
    株を勉強して半年で100銘柄買ったら、
    人生は変わるのか？
     （ noteのメンバーシップページ ）
    """
    
    let privacyPolicyURL = URL(string: "https://sites.google.com/view/trademindlog/%E3%83%97%E3%83%A9%E3%82%A4%E3%83%90%E3%82%B7%E3%83%BC-%E3%83%9D%E3%83%AA%E3%82%B7%E3%83%BC")!
    let termsOfServiceURL = URL(string: "https://sites.google.com/view/trademindlog/%E3%81%94%E5%88%A9%E7%94%A8%E8%A6%8F%E5%89%87")!
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("このアプリはこの実験から始まった")) {
                    Link(destination: experimentURL) {
                        HStack {
                            Text(noteMembershipTitle)
                            Spacer()
                            Image(systemName: "link")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("設定")) {
                    Picker("週の始まり", selection: $firstWeekday) {
                        Text("日曜日").tag(1)
                        Text("月曜日").tag(2)
                    }
                    
                    Picker("外観モード", selection: $colorScheme) {
                        Text("端末の設定を使う").tag(0)
                        Text("ライトモード").tag(1)
                        Text("ダークモード").tag(2)
                    }
                }
                
                Section(header: Text("アプリ情報")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.4")
                            .foregroundColor(.secondary)
                    }
                    
                    Link(destination: termsOfServiceURL) {
                        HStack {
                            Text("ご利用規約")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "link")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                                        
                    Link(destination: privacyPolicyURL) {
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
                
                Section(header: Text("データ管理")) {
                    Button(role: .destructive) {
                        isShowingDeleteAleart = true
                    } label: {
                        HStack {
                            Text("すべての記録を削除")
                            Spacer()
                            Image(systemName: "trash")
                                .font(.subheadline)
                        }
                    }
                }

                Section {
                    Text("© 2026 Tanabot")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Setting")
            .alert("すべてのデータを削除しますか？", isPresented: $isShowingDeleteAleart) {
                Button("Cancel", role: .cancel) { }
                Button("Delete All", role: .destructive) {
                    deleteAllRecords()
                }
            } message: {
                Text("この操作は取り消せません。これまでに登録したすべてのデータが完全に消去されます。")
            }
        }
    }
    
    private func deleteAllRecords() {
        do {
            try modelContext.delete(model: Record.self)
            try modelContext.save()
        } catch {
            print("Failed to delete all records: \(error)")
        }
    }
}

#Preview {
    SettingView()
//        .preferredColorScheme(.dark)
}
