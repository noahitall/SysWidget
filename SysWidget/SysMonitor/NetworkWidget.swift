import WidgetKit
import SwiftUI

// MARK: - Network Widget Entry

struct NetworkEntry: TimelineEntry {
    let date: Date
    let networkTraffic: NetworkTrafficData
    let downloadHistory: [TimeSeriesDataPoint]
    let uploadHistory: [TimeSeriesDataPoint]
    let configuration: NetworkTrafficConfigIntent
}

// MARK: - Network Provider

struct NetworkProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> NetworkEntry {
        return NetworkEntry(
            date: Date(),
            networkTraffic: NetworkTrafficData.getCurrentNetworkTraffic(for: "all"),
            downloadHistory: generateSampleData(min: 5000, max: 3 * 1024 * 1024),
            uploadHistory: generateSampleData(min: 1000, max: 1024 * 1024),
            configuration: NetworkTrafficConfigIntent()
        )
    }

    func snapshot(for configuration: NetworkTrafficConfigIntent, in context: Context) async -> NetworkEntry {
        let interfaceName = configuration.networkInterface.id
        let networkTraffic = NetworkTrafficData.getCurrentNetworkTraffic(for: interfaceName)
        
        return NetworkEntry(
            date: Date(),
            networkTraffic: networkTraffic,
            downloadHistory: HistoricalDataManager.shared.getNetworkDownloadHistory(),
            uploadHistory: HistoricalDataManager.shared.getNetworkUploadHistory(),
            configuration: configuration
        )
    }
    
    func timeline(for configuration: NetworkTrafficConfigIntent, in context: Context) async -> Timeline<NetworkEntry> {
        var entries: [NetworkEntry] = []
        let interfaceName = configuration.networkInterface.id
        let networkTraffic = NetworkTrafficData.getCurrentNetworkTraffic(for: interfaceName)
        let currentDate = Date()
        let downloadHistory = HistoricalDataManager.shared.getNetworkDownloadHistory()
        let uploadHistory = HistoricalDataManager.shared.getNetworkUploadHistory()
        
        // Add current entry
        entries.append(NetworkEntry(
            date: currentDate,
            networkTraffic: networkTraffic,
            downloadHistory: downloadHistory,
            uploadHistory: uploadHistory,
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
                entries.append(NetworkEntry(
                    date: futureDate,
                    networkTraffic: networkTraffic,
                    downloadHistory: downloadHistory,
                    uploadHistory: uploadHistory,
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
    
    // Generate sample network data for placeholder
    private func generateSampleData(min: Double, max: Double) -> [TimeSeriesDataPoint] {
        var dataPoints: [TimeSeriesDataPoint] = []
        let now = Date()
        
        // Create 15 minutes of data (90 points, every 10 seconds)
        for i in 0..<90 {
            let timestamp = now.addingTimeInterval(Double(-i * 10))
            let value = Double.random(in: min...max)
            dataPoints.append(TimeSeriesDataPoint(timestamp: timestamp, value: value))
        }
        
        // Reverse to get chronological order
        return dataPoints.reversed()
    }
}

// MARK: - Network Widget Views

struct NetworkWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: NetworkProvider.Entry
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallNetworkView(entry: entry)
        case .systemMedium:
            MediumNetworkView(entry: entry)
        case .systemLarge:
            LargeNetworkView(entry: entry)
        default:
            SmallNetworkView(entry: entry)
        }
    }
}

struct SmallNetworkView: View {
    var entry: NetworkEntry
    
    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Image(systemName: "network")
                    .foregroundStyle(.purple)
                Text("Network")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            VStack(spacing: 8) {
                // Download speed with sparkline
                VStack(spacing: 2) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 12))
                        
                        Text(entry.networkTraffic.downloadFormatted)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.green)
                        
                        Spacer()
                    }
                    
                    SparklineView(
                        dataPoints: entry.downloadHistory,
                        lineColor: .green,
                        fillColor: .green.opacity(0.2),
                        showMinMaxLabels: true
                    )
                    .frame(height: 24)
                }
                
                // Upload speed with sparkline
                VStack(spacing: 2) {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 12))
                        
                        Text(entry.networkTraffic.uploadFormatted)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.blue)
                        
                        Spacer()
                    }
                    
                    SparklineView(
                        dataPoints: entry.uploadHistory,
                        lineColor: .blue,
                        fillColor: .blue.opacity(0.2),
                        showMinMaxLabels: true
                    )
                    .frame(height: 24)
                }
            }
            
            Spacer(minLength: 2)
            
            // Display selected interface
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                Text(interfaceDisplayName)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
    }
    
    var interfaceDisplayName: String {
        entry.configuration.networkInterface.name
    }
}

struct MediumNetworkView: View {
    var entry: NetworkEntry
    
    var body: some View {
        HStack {
            // Left side - download & upload cards
            VStack(alignment: .center, spacing: 8) {
                // Download with sparkline
                VStack(spacing: 2) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 16))
                        
                        Text("Download")
                            .font(.system(size: 13, weight: .medium))
                    }
                    
                    Text(entry.networkTraffic.downloadFormatted)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                    
                    SparklineView(
                        dataPoints: entry.downloadHistory,
                        lineColor: .green,
                        fillColor: .green.opacity(0.2),
                        showMinMaxLabels: true
                    )
                    .frame(height: 30)
                    .padding(.horizontal, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                
                // Upload with sparkline
                VStack(spacing: 2) {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                        
                        Text("Upload")
                            .font(.system(size: 13, weight: .medium))
                    }
                    
                    Text(entry.networkTraffic.uploadFormatted)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                    
                    SparklineView(
                        dataPoints: entry.uploadHistory,
                        lineColor: .blue,
                        fillColor: .blue.opacity(0.2),
                        showMinMaxLabels: true
                    )
                    .frame(height: 30)
                    .padding(.horizontal, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .frame(width: 130)
            
            // Right side - general info
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "network")
                        .foregroundStyle(.purple)
                    Text("Network Traffic")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 5) {
                    Text("Interface")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundColor(.purple)
                        Text(interfaceDisplayName)
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                
                Spacer()
                
                Text("15-minute history shown in graphs")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.secondary)
                    Text("Updated: \(formattedTime(entry.networkTraffic.timestamp))")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.leading, 5)
        }
        .padding(12)
    }
    
    var interfaceDisplayName: String {
        entry.configuration.networkInterface.name
    }
    
    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct LargeNetworkView: View {
    var entry: NetworkEntry
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "network")
                    .foregroundStyle(.purple)
                Text("Network Traffic Monitor")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            // Interface info
            VStack(alignment: .leading, spacing: 5) {
                Text("Interface")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundColor(.purple)
                    Text(interfaceDisplayName)
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
            
            // Download section
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("Download")
                        .font(.system(size: 14, weight: .medium))
                    
                    Spacer()
                    
                    Text(entry.networkTraffic.downloadFormatted)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                }
                
                SparklineView(
                    dataPoints: entry.downloadHistory,
                    lineColor: .green,
                    fillColor: .green.opacity(0.2),
                    showMinMaxLabels: true
                )
                .frame(height: 50)
                .padding(.horizontal, 4)
            }
            .padding(8)
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
            
            // Upload section
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.blue)
                    
                    Text("Upload")
                        .font(.system(size: 14, weight: .medium))
                    
                    Spacer()
                    
                    Text(entry.networkTraffic.uploadFormatted)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                }
                
                SparklineView(
                    dataPoints: entry.uploadHistory,
                    lineColor: .blue,
                    fillColor: .blue.opacity(0.2),
                    showMinMaxLabels: true
                )
                .frame(height: 50)
                .padding(.horizontal, 4)
            }
            .padding(8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            Spacer()
            
            HStack {
                Text("15-minute history shown in graphs")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("Last updated: \(formattedDateTime(entry.networkTraffic.timestamp))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
    
    var interfaceDisplayName: String {
        entry.configuration.networkInterface.name
    }
    
    func formattedDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Network Widget

struct NetworkTrafficWidget: Widget {
    let kind: String = "NetworkTrafficWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: NetworkTrafficConfigIntent.self, provider: NetworkProvider()) { entry in
            NetworkWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Network Traffic")
        .description("Shows network upload and download speeds with historical graphs.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
} 