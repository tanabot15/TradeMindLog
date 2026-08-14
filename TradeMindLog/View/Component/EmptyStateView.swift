//
//  EmptyStateView.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/05/29.
//

import SwiftUI

struct EmptyStateView: View {
    
    enum EmptyType {
        case completelyEmpty
        case filterEmpty(timeFilterText: String)
    }
    
    let type: EmptyType
    let situation: Situation
    var onAddAction: (() -> Void)? = nil
    
    var body: some View {
        switch type {
        case .completelyEmpty:
            ContentUnavailableView {
                Label(
                    "最初の\(situation.rawValue)取引を記録しましょう",
                    systemImage: situation == .buy ? "tray.and.arrow.down" : "tray.and.arrow.up"
                )
            } description: {
                Text("投資した銘柄の情報を入力して、あなたのトレードの記録を始めましょう")
            }
            
        case .filterEmpty(let timeFilterText):
            ContentUnavailableView {
                Label(
                    "該当するデータがありません",
                    systemImage: situation == .buy ? "chart.pie" : "chart.bar.xaxis"
                )
            } description: { Text("選択された期間（\(timeFilterText)）に登録された\(situation.rawValue)実績がありません。上のカレンダーから期間を変更してみてください")
            }
        }
    }
}

#Preview {
    EmptyStateView(type: .completelyEmpty, situation: .buy)
}
