//
//  ReasonTagsView.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/06/05.
//

import SwiftUI
import SwiftData

struct ReasonTagsView: View {
    let record: Record
    
    @AppStorage("customBuyReasons") private var customBuyReasons: [String] = []
    @AppStorage("customSellReasons") private var customSellReasons: [String] = []
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                if record.situation == .buy {
                    ForEach(record.buyReasons) { reason in
                        tagCapsule(
                            name: reason.localizedName(customNames: customBuyReasons),
                            color: .blue
                        )
                    }
                } else {
                    ForEach(record.sellReasons) { reason in
                        tagCapsule(
                            name: reason.localizedName(customNames: customSellReasons),
                            color: .orange
                        )
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }
    
    private func tagCapsule(name: String, color: Color) -> some View {
        Text(name)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(.primary)
            .background(color.opacity(0.4))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.7), lineWidth: 0.5)
            )
    }
}

#Preview {
    ReasonTagsView(record: SampleData.records[0])
        .modelContainer(previewContainer)
//        .preferredColorScheme(.dark)
}
