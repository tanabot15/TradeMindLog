//
//  SettingView.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/05/13.
//

import SwiftUI

struct SettingView: View {
    @AppStorage("colorScheme") var colorScheme = 0
    // @AppStorage("isMondayStart") private var isMondayStart = false
    
    // Tanabot Menbership URL
    let experimentURL = URL(string: "https://note.com/tanabot/membership")!
//    let privacyPolicyURL = URL(string: "")!
//    let termsAndConditionsURL = URL(string: "")!
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("noteのURL")) {
                    Link(destination: experimentURL) {
                        HStack {
                            Label("note：株を勉強して半年で100銘柄買ったら、人生は変わるのか？", systemImage: "link")
                        }
                    }
                }
                
                Section(header: Text("画面")) {
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
                
//                Section(header: Text("App Settings")) {
//                    Toggle(isOn: $isMondayStart) {
//                        Text("from Monday")
//                    }
//                    .onChange(of: isMondayStart) {
//
//                    }
//                }

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
