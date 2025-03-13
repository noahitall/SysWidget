import WidgetKit
import SwiftUI

// MARK: - Memory Widget Entry

struct MemoryEntry: TimelineEntry {
    let date: Date
    let memoryUsage: MemoryUsageData
    let memoryHistory: [TimeSeriesDataPoint]
    let configuration: MemoryConfigIntent
}

// MARK: - Memory Provider

struct MemoryProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> MemoryEntry {
        let memoryUsage = MemoryUsageData.getCurrentMemoryUsage()
        return MemoryEntry(
            date: Date(),
            memoryUsage: memoryUsage,
            memoryHistory: generateSampleData(),
            configuration: MemoryConfigIntent()
        )
    }

    func snapshot(for configuration: MemoryConfigIntent, in context: Context) async -> MemoryEntry {
        let memoryUsage = MemoryUsageData.getCurrentMemoryUsage()
        return MemoryEntry(
            date: Date(),
            memoryUsage: memoryUsage,
            memoryHistory: HistoricalDataManager.shared.getMemoryUsageHistory(),
            configuration: configuration
        )
    }
    
    func timeline(for configuration: MemoryConfigIntent, in context: Context) async -> Timeline<MemoryEntry> {
        var entries: [MemoryEntry] = []
        let memoryUsage = MemoryUsageData.getCurrentMemoryUsage()
        let currentDate = Date()
        let memoryHistory = HistoricalDataManager.shared.getMemoryUsageHistory()
        
        // Add current entry
        entries.append(MemoryEntry(
            date: currentDate,
            memoryUsage: memoryUsage,
            memoryHistory: memoryHistory,
            configuration: configuration
        ))
        
        // Determine next refresh time based on widget configuration
        // The data will be sampled more frequently (every 15 seconds) regardless of widget refreshes
        let configuredInterval = configuration.updateFrequency.timeInterval
        let refreshInterval = max(configuredInterval, 60.0) // Refresh widget UI at minimum every minute
        
        // For longer refresh intervals, generate future entries to ensure data availability
        let numberOfEntries = 2 // Reduced number since we're sampling in the background anyway
        
        // Generate future entries to ensure the widget has data even if refresh fails
        for i in 1...numberOfEntries {
            if let futureDate = Calendar.current.date(
                byAdding: .second,
                value: Int(refreshInterval) * i,
                to: currentDate
            ) {
                entries.append(MemoryEntry(
                    date: futureDate,
                    memoryUsage: memoryUsage,
                    memoryHistory: memoryHistory, // Use same history for future entries
                    configuration: configuration
                ))
            }
        }
        
        // For normal intervals, set refresh policy using the configured interval
        let nextRefreshDate = Calendar.current.date(
            byAdding: .second,
            value: Int(refreshInterval),
            to: currentDate
        ) ?? Date().addingTimeInterval(refreshInterval)
        
        return Timeline(entries: entries, policy: .after(nextRefreshDate))
    }
    
    // Generate sample data for placeholder
    private func generateSampleData() -> [TimeSeriesDataPoint] {
        var dataPoints: [TimeSeriesDataPoint] = []
        let now = Date()
        
        // Create 15 minutes of data (90 points, every 10 seconds)
        for i in 0..<90 {
            let timestamp = now.addingTimeInterval(Double(-i * 10))
            let value = Double.random(in: 40...75) // Random memory usage between 40% and 75%
            dataPoints.append(TimeSeriesDataPoint(timestamp: timestamp, value: value))
        }
        
        // Reverse to get chronological order
        return dataPoints.reversed()
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
            
            // Small sparkline with min/max labels
            SparklineView(
                dataPoints: entry.memoryHistory,
                lineColor: usageColor,
                fillColor: usageColor.opacity(0.2),
                showDots: false,
                showMinMaxLabels: true
            )
            .frame(height: 30)
            
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
            // Left side - Circle
            VStack {
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
            }
            
            // Right side - Details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "memorychip")
                        .foregroundStyle(.green)
                    Text("Memory Usage")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                // Sparkline with min/max labels
                SparklineView(
                    dataPoints: entry.memoryHistory,
                    lineColor: usageColor,
                    fillColor: usageColor.opacity(0.2),
                    showDots: entry.memoryHistory.count < 30,
                    showMinMaxLabels: true
                )
                .frame(height: 40)
                
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
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "memorychip")
                    .foregroundStyle(.green)
                Text("Memory Monitor")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            // Top section with chart and circle
            HStack(spacing: 16) {
                // Left side - Circle
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: entry.memoryUsage.usedPercentage / 100)
                        .stroke(usageColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(Int(entry.memoryUsage.usedPercentage))%")
                            .font(.system(size: 24, weight: .bold))
                        
                        Text("Used")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Right side - Graph
                VStack(alignment: .leading, spacing: 2) {
                    Text("Memory Usage (15 min)")
                        .font(.system(size: 12, weight: .medium))
                    
                    SparklineView(
                        dataPoints: entry.memoryHistory,
                        lineColor: usageColor,
                        fillColor: usageColor.opacity(0.2),
                        showDots: entry.memoryHistory.count < 30,
                        showMinMaxLabels: true
                    )
                    .frame(height: 80)
                }
            }
            .padding(.vertical, 4)
            
            // Middle section with memory stats
            HStack {
                Spacer()
                VStack {
                    Text("Total")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text(entry.memoryUsage.totalFormatted)
                        .font(.system(size: 14, weight: .bold))
                }
                Spacer()
                VStack {
                    Text("Used")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text(entry.memoryUsage.usedFormatted)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.red)
                }
                Spacer()
                VStack {
                    Text("Free")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text(entry.memoryUsage.freeFormatted)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.green)
                }
                Spacer()
            }
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            // Bottom section with memory type breakdown
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
            
            Spacer()
            
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
        .description("Shows RAM usage on your system with historical graph.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
} 