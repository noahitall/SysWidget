import WidgetKit
import SwiftUI

// MARK: - Memory Widget Entry

struct MemoryEntry: TimelineEntry {
    let date: Date
    let memoryUsage: MemoryUsageData
    let configuration: MemoryConfigIntent
}

// MARK: - Memory Provider

struct MemoryProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> MemoryEntry {
        MemoryEntry(
            date: Date(),
            memoryUsage: MemoryUsageData.getCurrentMemoryUsage(),
            configuration: MemoryConfigIntent()
        )
    }

    func snapshot(for configuration: MemoryConfigIntent, in context: Context) async -> MemoryEntry {
        MemoryEntry(
            date: Date(),
            memoryUsage: MemoryUsageData.getCurrentMemoryUsage(),
            configuration: configuration
        )
    }
    
    func timeline(for configuration: MemoryConfigIntent, in context: Context) async -> Timeline<MemoryEntry> {
        var entries: [MemoryEntry] = []
        let memoryUsage = MemoryUsageData.getCurrentMemoryUsage()
        let currentDate = Date()
        
        // Get the configured refresh interval
        let configuredInterval = configuration.updateFrequency.timeInterval
        
        // For very short intervals (like 10 seconds), we'll generate fewer future entries
        // but for longer intervals, we'll create more to ensure data availability
        let numberOfEntries = configuredInterval < 60 ? 2 : 4
        
        // Add current entry
        entries.append(MemoryEntry(
            date: currentDate,
            memoryUsage: memoryUsage,
            configuration: configuration
        ))
        
        // Generate future entries to ensure the widget has data even if refresh fails
        for i in 1...numberOfEntries {
            if let futureDate = Calendar.current.date(
                byAdding: .second,
                value: Int(configuredInterval) * i,
                to: currentDate
            ) {
                entries.append(MemoryEntry(
                    date: futureDate,
                    memoryUsage: memoryUsage,
                    configuration: configuration
                ))
            }
        }
        
        // Set refresh policy using the configured interval
        // For really short intervals, ensure the refresh time gives the system enough time
        let nextRefreshDate = Calendar.current.date(
            byAdding: .second,
            value: max(Int(configuredInterval), 5), // At least 5 seconds between refreshes
            to: currentDate
        ) ?? Date().addingTimeInterval(10) // Default to 10 seconds
        
        return Timeline(entries: entries, policy: .after(nextRefreshDate))
    }
}

// MARK: - Memory Widget Views

struct MemoryWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: MemoryProvider.Entry
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallMemoryView(entry: entry)
        case .systemMedium:
            MediumMemoryView(entry: entry)
        case .systemLarge:
            LargeMemoryView(entry: entry)
        default:
            SmallMemoryView(entry: entry)
        }
    }
}

struct SmallMemoryView: View {
    var entry: MemoryEntry
    
    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Image(systemName: "memorychip")
                    .foregroundStyle(.green)
                Text("Memory")
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
                    .trim(from: 0, to: entry.memoryUsage.usedPercentage / 100)
                    .stroke(usageColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 0) {
                    Text("\(Int(entry.memoryUsage.usedPercentage))%")
                        .font(.system(size: 16, weight: .bold))
                    
                    Text("Used")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text("\(entry.memoryUsage.freeFormatted) free")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.secondary)
        }
        .padding(12)
    }
    
    var usageColor: Color {
        let percentage = entry.memoryUsage.usedPercentage
        if percentage < 50 {
            return .green
        } else if percentage < 80 {
            return .orange
        } else {
            return .red
        }
    }
}

struct MediumMemoryView: View {
    var entry: MemoryEntry
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: entry.memoryUsage.usedPercentage / 100)
                    .stroke(usageColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(Int(entry.memoryUsage.usedPercentage))%")
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("Used")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.trailing, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "memorychip")
                        .foregroundStyle(.green)
                    Text("Memory Usage")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Free: \(entry.memoryUsage.freeFormatted)")
                        .font(.system(size: 14))
                }
                
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                    Text("Used: \(entry.memoryUsage.usedFormatted)")
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
        let percentage = entry.memoryUsage.usedPercentage
        if percentage < 50 {
            return .green
        } else if percentage < 80 {
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

struct LargeMemoryView: View {
    var entry: MemoryEntry
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "memorychip")
                    .foregroundStyle(.green)
                Text("Memory Monitor")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                    .frame(width: 110, height: 110)
                
                Circle()
                    .trim(from: 0, to: entry.memoryUsage.usedPercentage / 100)
                    .stroke(usageColor, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text("\(Int(entry.memoryUsage.usedPercentage))%")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("Used")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
            
            // Memory type breakdown
            VStack(spacing: 10) {
                HStack {
                    Spacer()
                    VStack {
                        Text("Total")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text(entry.memoryUsage.totalFormatted)
                            .font(.system(size: 16, weight: .bold))
                    }
                    Spacer()
                    VStack {
                        Text("Used")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text(entry.memoryUsage.usedFormatted)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.red)
                    }
                    Spacer()
                    VStack {
                        Text("Free")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        Text(entry.memoryUsage.freeFormatted)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.green)
                    }
                    Spacer()
                }
                
                Divider()
                
                // Memory type breakdown
                VStack(spacing: 8) {
                    Text("Memory Allocation")
                        .font(.system(size: 14, weight: .medium))
                    
                    HStack(spacing: 15) {
                        // Active memory
                        VStack(alignment: .leading) {
                            Text("Active")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Text(entry.memoryUsage.activeFormatted)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.blue)
                        }
                        
                        // Wired memory
                        VStack(alignment: .leading) {
                            Text("Wired")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Text(entry.memoryUsage.wiredFormatted)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.orange)
                        }
                        
                        // Inactive memory
                        VStack(alignment: .leading) {
                            Text("Inactive")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Text(entry.memoryUsage.inactiveFormatted)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.gray)
                        }
                    }
                }
                .padding(.vertical, 5)
                
                // Progress bar
                ProgressView(value: entry.memoryUsage.usedPercentage, total: 100) {
                    HStack {
                        Text("Memory Usage")
                            .font(.caption)
                        Spacer()
                        Text("\(Int(entry.memoryUsage.usedPercentage))%")
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
        let percentage = entry.memoryUsage.usedPercentage
        if percentage < 50 {
            return .green
        } else if percentage < 80 {
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

// MARK: - Memory Widget

struct MemoryUsageWidget: Widget {
    let kind: String = "MemoryUsageWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: MemoryConfigIntent.self, provider: MemoryProvider()) { entry in
            MemoryWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Memory Usage")
        .description("Shows RAM usage on your system.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
} 