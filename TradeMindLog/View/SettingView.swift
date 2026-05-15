//
//  SettingView.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/05/13.
//

import SwiftUI

struct SettingView: View {
    @AppStorage("colorScheme") var colorScheme = 0
    // first weekday (1:Sunday, 2: Monday)
    @AppStorage("firstWeekday") private var firstWeekday = 1
    
    // Tanabot Menbership URL
    let experimentURL = URL(string: "https://note.com/tanabot/membership")!
//    let privacyPolicyURL = URL(string: "")!
//    let termsAndConditionsURL = URL(string: "")!
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("このアプリはここから始まった")) {
                    Link(destination: experimentURL) {
                        HStack {
                            Label("note：株を勉強して半年で100銘柄買ったら、人生は変わるのか？", systemImage: "link")
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
                        Text("1.0.1")
                            .foregroundColor(.secondary)
                    }
//                    
//                    NavigationLink(destination: Text("Privacy Policy")) {
//                        Text("Privacy Policy")
//                    }
//
//                    NavigationLink(destination: Text("Terms and Conditions")) {
//                        Text("Terms and Conditions")
//                    }
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
        }
    }
}

#Preview {
    SettingView()
//        .preferredColorScheme(.dark)
}
