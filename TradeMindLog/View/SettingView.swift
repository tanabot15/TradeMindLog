//
//  SettingView.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/05/13.
//

import SwiftUI

struct SettingView: View {
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
                
                Section(header: Text("This App")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
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
}
