//
//  SysMonitor.swift
//  SysMonitor
//
//  Created by Noah Zitsman on 3/12/25.
//

import WidgetKit
import SwiftUI

// Disk usage data structure to hold our metrics data
struct DiskUsageData {
    let total: UInt64
    let free: UInt64
    let used: UInt64
    let usedPercentage: Double
    
    var totalFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(total), countStyle: .file)
    }
    
    var freeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(free), countStyle: .file)
    }
    
    var usedFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(used), countStyle: .file)
    }
    
    // Helper function to get disk usage information
    static func getCurrentDiskUsage() -> DiskUsageData {
        let fileURL = URL(fileURLWithPath: "/")
        var total: UInt64 = 0
        var free: UInt64 = 0
        var used: UInt64 = 0
        var percentage: Double = 0
        
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
            if let totalCapacity = values.volumeTotalCapacity, let availableCapacity = values.volumeAvailableCapacity {
                total = UInt64(totalCapacity)
                free = UInt64(availableCapacity)
                used = total - free
                percentage = Double(used) / Double(total) * 100
            }
        } catch {
            print("Error getting disk usage: \(error)")
        }
        
        return DiskUsageData(
            total: total,
            free: free,
            used: used,
            usedPercentage: percentage
        )
    }
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        let diskUsage = DiskUsageData.getCurrentDiskUsage()
        return SimpleEntry(date: Date(), diskUsage: diskUsage, configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let diskUsage = DiskUsageData.getCurrentDiskUsage()
        return SimpleEntry(date: Date(), diskUsage: diskUsage, configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        let diskUsage = DiskUsageData.getCurrentDiskUsage()

        // Current date
        let currentDate = Date()
        
        // Add the current entry
        let entry = SimpleEntry(date: currentDate, diskUsage: diskUsage, configuration: configuration)
        entries.append(entry)
        
        // Set refresh time based on user preference
        let nextUpdateDate = Calendar.current.date(byAdding: .second, value: Int(configuration.updateFrequency.timeInterval), to: currentDate)!
        
        return Timeline(entries: entries, policy: .after(nextUpdateDate))
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let diskUsage: DiskUsageData
    let configuration: ConfigurationAppIntent
}

struct SysMonitorEntryView : View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: Provider.Entry

    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallDiskMonitorView(entry: entry)
        case .systemMedium:
            MediumDiskMonitorView(entry: entry)
        case .systemLarge:
            LargeDiskMonitorView(entry: entry)
        default:
            SmallDiskMonitorView(entry: entry)
        }
    }
}

struct SmallDiskMonitorView: View {
    var entry: SimpleEntry
    
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

struct MediumDiskMonitorView: View {
    var entry: SimpleEntry
    
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

struct LargeDiskMonitorView: View {
    var entry: SimpleEntry
    
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

struct SysMonitor: Widget {
    let kind: String = "SysMonitor"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            SysMonitorEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Disk Space Monitor")
        .description("Shows free and used disk space on your system.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
