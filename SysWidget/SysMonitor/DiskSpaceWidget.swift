import WidgetKit
import SwiftUI

// MARK: - Disk Space Widget Entry

struct DiskSpaceEntry: TimelineEntry {
    let date: Date
    let diskUsage: DiskUsageData
    let configuration: DiskSpaceConfigIntent
}

// MARK: - Disk Space Provider

struct DiskSpaceProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> DiskSpaceEntry {
        DiskSpaceEntry(
            date: Date(),
            diskUsage: DiskUsageData.getCurrentDiskUsage(),
            configuration: DiskSpaceConfigIntent()
        )
    }

    func snapshot(for configuration: DiskSpaceConfigIntent, in context: Context) async -> DiskSpaceEntry {
        DiskSpaceEntry(
            date: Date(),
            diskUsage: DiskUsageData.getCurrentDiskUsage(),
            configuration: configuration
        )
    }
    
    func timeline(for configuration: DiskSpaceConfigIntent, in context: Context) async -> Timeline<DiskSpaceEntry> {
        var entries: [DiskSpaceEntry] = []
        let diskUsage = DiskUsageData.getCurrentDiskUsage()
        let currentDate = Date()
        
        // Add current entry
        entries.append(DiskSpaceEntry(
            date: currentDate,
            diskUsage: diskUsage,
            configuration: configuration
        ))
        
        // Generate future entries to ensure the widget has data even if refresh fails
        for i in 1...3 {
            if let futureDate = Calendar.current.date(
                byAdding: .second,
                value: Int(configuration.updateFrequency.timeInterval) * i,
                to: currentDate
            ) {
                entries.append(DiskSpaceEntry(
                    date: futureDate,
                    diskUsage: diskUsage,
                    configuration: configuration
                ))
            }
        }
        
        // Set refresh policy
        let nextRefreshDate = Calendar.current.date(
            byAdding: .second,
            value: min(Int(configuration.updateFrequency.timeInterval), 3600),
            to: currentDate
        ) ?? Date().addingTimeInterval(3600)
        
        return Timeline(entries: entries, policy: .after(nextRefreshDate))
    }
}

// MARK: - Disk Space Widget Views

struct DiskSpaceWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: DiskSpaceProvider.Entry
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallDiskView(entry: entry)
        case .systemMedium:
            MediumDiskView(entry: entry)
        case .systemLarge:
            LargeDiskView(entry: entry)
        default:
            SmallDiskView(entry: entry)
        }
    }
}

struct SmallDiskView: View {
    var entry: DiskSpaceEntry
    
    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Image(systemName: "internaldrive")
                    .foregroundStyle(.blue)
                Text("Disk Space")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                    .frame(width: 90, height: 90)
                
                Circle()
                    .trim(from: 0, to: entry.diskUsage.usedPercentage / 100)
                    .stroke(usageColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text("\(Int(entry.diskUsage.usedPercentage))%")
                        .font(.system(size: 16, weight: .bold))
                    
                    Text("Used")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text("\(entry.diskUsage.freeFormatted) free")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .padding(12)
    }
    
    var usageColor: Color {
        let percentage = entry.diskUsage.usedPercentage
        if percentage < 70 {
            return .green
        } else if percentage < 85 {
            return .orange
        } else {
            return .red
        }
    }
}

struct MediumDiskView: View {
    var entry: DiskSpaceEntry
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: entry.diskUsage.usedPercentage / 100)
                    .stroke(usageColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(Int(entry.diskUsage.usedPercentage))%")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("Used")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.trailing, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "internaldrive")
                        .foregroundStyle(.blue)
                    Text("Disk Space")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Free: \(entry.diskUsage.freeFormatted)")
                        .font(.system(size: 14))
                }
                
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    Text("Used: \(entry.diskUsage.usedFormatted)")
                        .font(.system(size: 14))
                }
                
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.secondary)
                    Text("Updated: \(formattedTime(entry.date))")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
    
    var usageColor: Color {
        let percentage = entry.diskUsage.usedPercentage
        if percentage < 70 {
            return .green
        } else if percentage < 85 {
            return .orange
        } else {
            return .red
        }
    }
    
    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct LargeDiskView: View {
    var entry: DiskSpaceEntry
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "internaldrive")
                    .foregroundStyle(.blue)
                Text("Disk Space Monitor")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: entry.diskUsage.usedPercentage / 100)
                    .stroke(usageColor, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(Int(entry.diskUsage.usedPercentage))%")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("Used")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                HStack {
                    Spacer()
                    VStack {
                        Text("Total")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text(entry.diskUsage.totalFormatted)
                            .font(.system(size: 16, weight: .bold))
                    }
                    Spacer()
                    VStack {
                        Text("Used")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text(entry.diskUsage.usedFormatted)
                            .font(.system(size: 16, weight: .bold))
                    }
                    Spacer()
                    VStack {
                        Text("Free")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text(entry.diskUsage.freeFormatted)
                            .font(.system(size: 16, weight: .bold))
                    }
                    Spacer()
                }
                
                Divider()
                
                // Progress bar
                ProgressView(value: entry.diskUsage.usedPercentage, total: 100) {
                    HStack {
                        Text("Usage")
                            .font(.caption)
                        Spacer()
                        Text("\(Int(entry.diskUsage.usedPercentage))%")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                }
                .tint(usageColor)
            }
            .padding(.horizontal)
            
            Text("Last updated: \(formattedDateTime(entry.date))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
    
    var usageColor: Color {
        let percentage = entry.diskUsage.usedPercentage
        if percentage < 70 {
            return .green
        } else if percentage < 85 {
            return .orange
        } else {
            return .red
        }
    }
    
    func formattedDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Disk Space Widget

struct DiskSpaceWidget: Widget {
    let kind: String = "DiskSpaceWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: DiskSpaceConfigIntent.self, provider: DiskSpaceProvider()) { entry in
            DiskSpaceWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Disk Space")
        .description("Shows disk space usage on your system.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
} 