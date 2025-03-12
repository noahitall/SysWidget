import WidgetKit
import SwiftUI

// MARK: - Network Widget Entry

struct NetworkEntry: TimelineEntry {
    let date: Date
    let networkTraffic: NetworkTrafficData
    let configuration: NetworkTrafficConfigIntent
}

// MARK: - Network Provider

struct NetworkProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> NetworkEntry {
        NetworkEntry(
            date: Date(),
            networkTraffic: NetworkTrafficData.getCurrentNetworkTraffic(for: "all"),
            configuration: NetworkTrafficConfigIntent()
        )
    }

    func snapshot(for configuration: NetworkTrafficConfigIntent, in context: Context) async -> NetworkEntry {
        let interfaceName = configuration.networkInterface.id
        
        return NetworkEntry(
            date: Date(),
            networkTraffic: NetworkTrafficData.getCurrentNetworkTraffic(for: interfaceName),
            configuration: configuration
        )
    }
    
    func timeline(for configuration: NetworkTrafficConfigIntent, in context: Context) async -> Timeline<NetworkEntry> {
        var entries: [NetworkEntry] = []
        let interfaceName = configuration.networkInterface.id
        let networkTraffic = NetworkTrafficData.getCurrentNetworkTraffic(for: interfaceName)
        let currentDate = Date()
        
        // Get the configured refresh interval
        let configuredInterval = configuration.updateFrequency.timeInterval
        
        // Add current entry
        entries.append(NetworkEntry(
            date: currentDate,
            networkTraffic: networkTraffic,
            configuration: configuration
        ))
        
        // For very short intervals (10 seconds or less), use a different approach
        if configuredInterval <= 10 {
            // For very short intervals, use .atEnd policy with only current entry
            return Timeline(entries: entries, policy: .atEnd)
        }
        
        // For longer intervals, generate future entries to ensure data availability
        let numberOfEntries = configuredInterval < 60 ? 2 : 4
        
        // Generate future entries to ensure the widget has data even if refresh fails
        for i in 1...numberOfEntries {
            if let futureDate = Calendar.current.date(
                byAdding: .second,
                value: Int(configuredInterval) * i,
                to: currentDate
            ) {
                entries.append(NetworkEntry(
                    date: futureDate,
                    networkTraffic: networkTraffic,
                    configuration: configuration
                ))
            }
        }
        
        // For normal intervals, set refresh policy using the configured interval
        let nextRefreshDate = Calendar.current.date(
            byAdding: .second,
            value: Int(configuredInterval),
            to: currentDate
        ) ?? Date().addingTimeInterval(configuredInterval)
        
        return Timeline(entries: entries, policy: .after(nextRefreshDate))
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
        VStack(spacing: 5) {
            HStack {
                Image(systemName: "network")
                    .foregroundStyle(.purple)
                Text("Network")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                // Download speed indicator
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.green)
                    
                    Text(entry.networkTraffic.downloadFormatted)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.green)
                }
                
                // Upload speed indicator
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.blue)
                    
                    Text(entry.networkTraffic.uploadFormatted)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            // Display selected interface
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                Text(interfaceDisplayName)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
    }
    
    var interfaceDisplayName: String {
        entry.configuration.networkInterface.name
    }
}

struct MediumNetworkView: View {
    var entry: NetworkEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .center, spacing: 10) {
                // Download
                VStack(spacing: 5) {
                    Text("Download")
                        .font(.system(size: 14, weight: .medium))
                    
                    HStack(alignment: .bottom, spacing: 3) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 18))
                        
                        Text(entry.networkTraffic.downloadFormatted)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                
                // Upload
                VStack(spacing: 5) {
                    Text("Upload")
                        .font(.system(size: 14, weight: .medium))
                    
                    HStack(alignment: .bottom, spacing: 3) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 18))
                        
                        Text(entry.networkTraffic.uploadFormatted)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.blue)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .frame(width: 130)
            
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
        .padding()
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
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "network")
                    .foregroundStyle(.purple)
                Text("Network Traffic Monitor")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            HStack(alignment: .top, spacing: 20) {
                // Left column - speeds
                VStack(spacing: 15) {
                    // Interface
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
                    .padding(.vertical, 8)
                    
                    Divider()
                    
                    // Speeds
                    HStack(alignment: .top, spacing: 0) {
                        // Download
                        VStack(spacing: 5) {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundColor(.green)
                                
                                Text("Download")
                                    .font(.system(size: 12))
                            }
                            
                            Text(entry.networkTraffic.downloadFormatted)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.green)
                                .padding(.top, 3)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Upload
                        VStack(spacing: 5) {
                            HStack {
                                Image(systemName: "arrow.up.circle.fill")
                                    .foregroundColor(.blue)
                                
                                Text("Upload")
                                    .font(.system(size: 12))
                            }
                            
                            Text(entry.networkTraffic.uploadFormatted)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.blue)
                                .padding(.top, 3)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                
                // Right column - visualization
                VStack(spacing: 10) {
                    // Download bar
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Download Speed")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        
                        GeometryReader { geo in
                            // This would normally use a real percentage, but we're using a simulated value
                            let percentage = min(entry.networkTraffic.download / (1024 * 1024), 1.0)
                            
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 12)
                                    .cornerRadius(6)
                                
                                Rectangle()
                                    .fill(Color.green)
                                    .frame(width: geo.size.width * CGFloat(percentage), height: 12)
                                    .cornerRadius(6)
                            }
                        }
                        .frame(height: 12)
                    }
                    
                    // Upload bar
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Upload Speed")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        
                        GeometryReader { geo in
                            // This would normally use a real percentage, but we're using a simulated value
                            let percentage = min(entry.networkTraffic.upload / (512 * 1024), 1.0)
                            
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 12)
                                    .cornerRadius(6)
                                
                                Rectangle()
                                    .fill(Color.blue)
                                    .frame(width: geo.size.width * CGFloat(percentage), height: 12)
                                    .cornerRadius(6)
                            }
                        }
                        .frame(height: 12)
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 5)
            
            Spacer()
            
            Text("Last updated: \(formattedDateTime(entry.networkTraffic.timestamp))")
                .font(.caption)
                .foregroundStyle(.secondary)
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
        .description("Shows network upload and download speeds.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
} 