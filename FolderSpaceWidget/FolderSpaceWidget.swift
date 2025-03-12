import SwiftUI
import WidgetKit
import Intents
import Foundation

// Widget Entry
struct FolderSpaceEntry: TimelineEntry {
    let date: Date
    let configuration: FolderSpaceConfiguration
    let folderSize: FolderSpaceModel.FolderSize?
    
    static let placeholder = FolderSpaceEntry(
        date: Date(),
        configuration: FolderSpaceConfiguration.default,
        folderSize: FolderSpaceModel.FolderSize(
            url: URL(fileURLWithPath: NSHomeDirectory()),
            displayName: "Home",
            totalBytes: 1_000_000_000,
            fileCount: 1000,
            folderCount: 100
        )
    )
}

// Timeline Provider
struct Provider: TimelineProvider {
    private let userDefaults = UserDefaults(suiteName: "group.com.noahzitsman.syswidget")
    
    func placeholder(in context: Context) -> FolderSpaceEntry {
        return FolderSpaceEntry.placeholder
    }
    
    func getSnapshot(in context: Context, completion: @escaping (FolderSpaceEntry) -> Void) {
        // For the snapshot, use the placeholder or a saved configuration
        let configuration = loadSavedConfiguration() ?? FolderSpaceConfiguration.default
        
        if context.isPreview {
            completion(FolderSpaceEntry.placeholder)
        } else {
            // Try to calculate folder size quickly or use cached value
            if let folderSize = FolderSpaceModel.calculateFolderSize(
                url: configuration.folderURL,
                displayName: configuration.folderDisplayName
            ) {
                completion(FolderSpaceEntry(date: Date(), configuration: configuration, folderSize: folderSize))
            } else {
                completion(FolderSpaceEntry(date: Date(), configuration: configuration, folderSize: nil))
            }
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<FolderSpaceEntry>) -> Void) {
        // Load the saved configuration or use the default
        let configuration = loadSavedConfiguration() ?? FolderSpaceConfiguration.default
        
        // Calculate folder size asynchronously
        FolderSpaceModel.calculateFolderSizeAsync(
            url: configuration.folderURL,
            displayName: configuration.folderDisplayName
        ) { folderSize in
            var entries: [FolderSpaceEntry] = []
            
            // Create entries for the next 24 hours with the appropriate refresh interval
            let currentDate = Date()
            for offset in 0..<4 {  // Generate a few entries
                let entryDate = Calendar.current.date(
                    byAdding: .second,
                    value: Int(configuration.refreshInterval.timeInterval) * offset,
                    to: currentDate
                )!
                
                let entry = FolderSpaceEntry(
                    date: entryDate,
                    configuration: configuration,
                    folderSize: folderSize
                )
                entries.append(entry)
            }
            
            // Set the policy to refresh based on user's selection
            let timeline = Timeline(
                entries: entries,
                policy: .after(Calendar.current.date(
                    byAdding: .second,
                    value: Int(configuration.refreshInterval.timeInterval),
                    to: currentDate
                )!)
            )
            completion(timeline)
        }
    }
    
    // Helper method to load saved configuration
    private func loadSavedConfiguration() -> FolderSpaceConfiguration? {
        guard let data = userDefaults?.data(forKey: "folderSpaceConfiguration") else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(FolderSpaceConfiguration.self, from: data)
        } catch {
            print("Error decoding configuration: \(error)")
            return nil
        }
    }
}

// Main widget view that decides which size to display
struct FolderSpaceWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        if let folderSize = entry.folderSize {
            switch family {
            case .systemSmall:
                FolderSpaceSmallView(
                    folderSize: folderSize, 
                    folderName: entry.configuration.folderDisplayName
                )
            case .systemMedium:
                FolderSpaceMediumView(
                    folderSize: folderSize, 
                    folderName: entry.configuration.folderDisplayName
                )
            case .systemLarge:
                FolderSpaceLargeView(
                    folderSize: folderSize, 
                    folderName: entry.configuration.folderDisplayName
                )
            @unknown default:
                FolderSpaceSmallView(
                    folderSize: folderSize, 
                    folderName: entry.configuration.folderDisplayName
                )
            }
        } else {
            // Display loading state if we don't have folder size data
            VStack {
                Image(systemName: "folder.badge.questionmark")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                
                Text("Calculating size...")
                    .font(.headline)
                    .padding(.top, 10)
                
                Text("Folder: \(entry.configuration.folderDisplayName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
            }
            .padding()
        }
    }
}

// Widget definition
@main
struct FolderSpaceWidget: Widget {
    let kind: String = "FolderSpaceWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            FolderSpaceWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Folder Space Monitor")
        .description("Monitor disk space used by a specific folder.")
        #if os(macOS)
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        #else
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        #endif
    }
}

// Preview providers
struct FolderSpaceWidget_Previews: PreviewProvider {
    static var previews: some View {
        let entry = FolderSpaceEntry.placeholder
        
        Group {
            FolderSpaceWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            FolderSpaceWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            
            FolderSpaceWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
} 