import WidgetKit
import SwiftUI
import Intents

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SystemMetricsEntry {
        SystemMetricsEntry(date: Date(), metrics: placeholderMetrics)
    }

    func getSnapshot(in context: Context, completion: @escaping (SystemMetricsEntry) -> ()) {
        let entry = SystemMetricsEntry(date: Date(), metrics: placeholderMetrics)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SystemMetricsEntry] = []
        let metrics = SystemMetricsModel()
        metrics.updateMetricsForWidget()
        
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: 10 * hourOffset, to: currentDate)!
            let entry = SystemMetricsEntry(date: entryDate, metrics: metrics)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private var placeholderMetrics: SystemMetricsModel {
        let metrics = SystemMetricsModel()
        
        // Set up placeholder values
        metrics.diskUsage.total = 1000000000000  // 1TB
        metrics.diskUsage.free = 500000000000   // 500GB
        metrics.diskUsage.used = 500000000000   // 500GB
        metrics.diskUsage.usedPercentage = 50
        
        metrics.memoryUsage.total = 16000000000  // 16GB
        metrics.memoryUsage.used = 8000000000   // 8GB
        metrics.memoryUsage.free = 8000000000   // 8GB
        metrics.memoryUsage.usedPercentage = 50
        
        metrics.cpuTemperature = 50.0
        
        metrics.networkTraffic.upload = 500000  // 500KB/s
        metrics.networkTraffic.download = 2000000  // 2MB/s
        
        return metrics
    }
}

struct SystemMetricsEntry: TimelineEntry {
    let date: Date
    let metrics: SystemMetricsModel
}

struct SysMetricsWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(metrics: entry.metrics)
        case .systemMedium:
            MediumWidgetView(metrics: entry.metrics)
        case .systemLarge:
            LargeWidgetView(metrics: entry.metrics)
        @unknown default:
            SmallWidgetView(metrics: entry.metrics)
        }
    }
}

struct SmallWidgetView: View {
    var metrics: SystemMetricsModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "memorychip")
                    .font(.system(size: 14))
                Text("System Metrics")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
            }
            .padding(.bottom, 2)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                // Disk usage
                HStack {
                    Image(systemName: "internaldrive")
                        .foregroundColor(.blue)
                    Text("\(Int(metrics.diskUsage.usedPercentage))%")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                }
                
                // RAM usage
                HStack {
                    Image(systemName: "memorychip")
                        .foregroundColor(.green)
                    Text("\(Int(metrics.memoryUsage.usedPercentage))%")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                }
                
                // CPU temperature
                TemperatureView(temperature: metrics.cpuTemperature)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct MediumWidgetView: View {
    var metrics: SystemMetricsModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "memorychip")
                    .font(.system(size: 14))
                Text("System Metrics")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
            }
            
            Divider()
            
            HStack(alignment: .top, spacing: 20) {
                // Left column
                VStack(alignment: .leading, spacing: 8) {
                    MetricView(
                        icon: "internaldrive",
                        title: "Disk",
                        value: "\(metrics.diskUsage.freeFormatted) free",
                        color: .blue
                    )
                    
                    MetricView(
                        icon: "memorychip",
                        title: "RAM",
                        value: "\(metrics.memoryUsage.freeFormatted) free",
                        color: .green
                    )
                }
                
                // Right column
                VStack(alignment: .leading, spacing: 8) {
                    TemperatureView(temperature: metrics.cpuTemperature)
                        .padding(.top, 4)
                    
                    NetworkView(
                        upload: metrics.networkTraffic.uploadFormatted,
                        download: metrics.networkTraffic.downloadFormatted
                    )
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct LargeWidgetView: View {
    var metrics: SystemMetricsModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "memorychip")
                    .font(.system(size: 14))
                Text("System Metrics")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
            }
            
            Divider()
            
            // Disk usage
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "internaldrive")
                        .foregroundColor(.blue)
                    Text("Disk Space")
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    Text("\(metrics.diskUsage.usedFormatted) / \(metrics.diskUsage.totalFormatted)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                ProgressBarView(value: metrics.diskUsage.usedPercentage, color: .blue)
            }
            .padding(.bottom, 8)
            
            // RAM usage
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "memorychip")
                        .foregroundColor(.green)
                    Text("Memory")
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    Text("\(metrics.memoryUsage.usedFormatted) / \(metrics.memoryUsage.totalFormatted)")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                ProgressBarView(value: metrics.memoryUsage.usedPercentage, color: .green)
            }
            .padding(.bottom, 8)
            
            // CPU temperature
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "thermometer")
                        .foregroundColor(metrics.cpuTemperature < 50 ? .green : (metrics.cpuTemperature < 70 ? .orange : .red))
                    Text("CPU Temperature")
                        .font(.system(size: 14, weight: .medium))
                    Spacer()
                    Text("\(Int(metrics.cpuTemperature))°C")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(metrics.cpuTemperature < 50 ? .green : (metrics.cpuTemperature < 70 ? .orange : .red))
                }
            }
            .padding(.bottom, 8)
            
            // Network traffic
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "network")
                        .foregroundColor(.purple)
                    Text("Network")
                        .font(.system(size: 14, weight: .medium))
                }
                
                HStack {
                    NetworkView(
                        upload: metrics.networkTraffic.uploadFormatted,
                        download: metrics.networkTraffic.downloadFormatted
                    )
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct SysMetricsWidget: Widget {
    let kind: String = "SysMetricsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SysMetricsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("System Metrics")
        .description("Monitor disk, memory, CPU temperature, and network traffic.")
        #if os(macOS)
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        #else
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        #endif
    }
}

struct SysMetricsWidget_Previews: PreviewProvider {
    static var previews: some View {
        let metrics = SystemMetricsModel()
        metrics.diskUsage.total = 1000000000000  // 1TB
        metrics.diskUsage.free = 500000000000   // 500GB
        metrics.diskUsage.used = 500000000000   // 500GB
        metrics.diskUsage.usedPercentage = 50
        
        metrics.memoryUsage.total = 16000000000  // 16GB
        metrics.memoryUsage.used = 8000000000   // 8GB
        metrics.memoryUsage.free = 8000000000   // 8GB
        metrics.memoryUsage.usedPercentage = 50
        
        metrics.cpuTemperature = 50.0
        
        metrics.networkTraffic.upload = 500000  // 500KB/s
        metrics.networkTraffic.download = 2000000  // 2MB/s
        
        return Group {
            SysMetricsWidgetEntryView(entry: SystemMetricsEntry(date: Date(), metrics: metrics))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            SysMetricsWidgetEntryView(entry: SystemMetricsEntry(date: Date(), metrics: metrics))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            
            SysMetricsWidgetEntryView(entry: SystemMetricsEntry(date: Date(), metrics: metrics))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
} 