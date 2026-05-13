//
//  PreviewContainer.swift
//  TradeMindLog
//
//  Created by Kenichiro Suzuki on 2026/05/13.
//

import Foundation
import SwiftData

@MainActor
let previewContainer: ModelContainer = {
    do {
        let container = try ModelContainer(
            for: Record.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let modelContext = container.mainContext
        
        if try modelContext.fetch(FetchDescriptor<Record>()).isEmpty {
            SampleData.records.forEach { modelContext.insert($0) }
        }
        
        return container
    } catch {
        fatalError("Failed to create container")
    }
} ()
