import SwiftUI
import WidgetKit

enum WidgetSize: String, CaseIterable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    
    var family: WidgetFamily {
        switch self {
        case .small: return .systemSmall
        case .medium: return .systemMedium
        case .large: return .systemLarge
        }
    }
}

struct WidgetPreviewView<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let content: (WidgetFamily) -> Content
    @State private var selectedSize: WidgetSize = .small
    
    init(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: @escaping (WidgetFamily) -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.system(size: 24, weight: .bold))
            }
            .padding(.top)
            
            // Size Selector
            Picker("Widget Size", selection: $selectedSize) {
                ForEach(WidgetSize.allCases, id: \.self) { size in
                    Text(size.rawValue).tag(size)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Widget Preview
            ZStack {
                Color.gray.opacity(0.1)
                    .cornerRadius(12)
                
                content(selectedSize.family)
                    .frame(maxWidth: selectedSize == .small ? 170 : (selectedSize == .medium ? 350 : 350),
                           maxHeight: selectedSize == .small ? 170 : (selectedSize == .medium ? 170 : 380))
                    .padding()
            }
            .frame(maxWidth: .infinity)
            .padding()
            
            Spacer()
        }
        .padding()
    }
}

// Preview providers for each widget type
struct MemoryWidgetPreview: View {
    @StateObject private var metricsModel = SystemMetricsModel()
    
    var body: some View {
        WidgetPreviewView(
            title: "Memory Widget",
            icon: "memorychip",
            iconColor: .green
        ) { family in
            // Memory widget preview content
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "memorychip")
                        .foregroundStyle(.green)
                    Text("Memory")
                        .font(.headline)
                    Spacer()
                }
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 90, height: 90)
                    
                    Circle()
                        .trim(from: 0, to: metricsModel.memoryUsage.usedPercentage / 100)
                        .stroke(Color.green, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(Int(metricsModel.memoryUsage.usedPercentage))%")
                            .font(.system(size: 16, weight: .bold))
                        Text("Used")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text("\(metricsModel.memoryUsage.freeFormatted) free")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

struct DiskSpaceWidgetPreview: View {
    @StateObject private var metricsModel = SystemMetricsModel()
    
    var body: some View {
        WidgetPreviewView(
            title: "Disk Space Widget",
            icon: "internaldrive",
            iconColor: .blue
        ) { family in
            // Disk space widget preview content
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "internaldrive")
                        .foregroundStyle(.blue)
                    Text("Disk Space")
                        .font(.headline)
                    Spacer()
                }
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 90, height: 90)
                    
                    Circle()
                        .trim(from: 0, to: metricsModel.diskUsage.usedPercentage / 100)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(Int(metricsModel.diskUsage.usedPercentage))%")
                            .font(.system(size: 16, weight: .bold))
                        Text("Used")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Text("\(metricsModel.diskUsage.freeFormatted) free")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

struct NetworkWidgetPreview: View {
    @StateObject private var metricsModel = SystemMetricsModel()
    
    var body: some View {
        WidgetPreviewView(
            title: "Network Widget",
            icon: "network",
            iconColor: .purple
        ) { family in
            // Network widget preview content
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "network")
                        .foregroundStyle(.purple)
                    Text("Network")
                        .font(.headline)
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.green)
                        Text("Download")
                            .font(.system(size: 12))
                        Spacer()
                        Text(metricsModel.networkTraffic.downloadFormatted)
                            .font(.system(size: 14, weight: .bold))
                    }
                    
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.blue)
                        Text("Upload")
                            .font(.system(size: 12))
                        Spacer()
                        Text(metricsModel.networkTraffic.uploadFormatted)
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .padding(.vertical, 8)
            }
            .padding()
        }
    }
}

struct FolderSpaceWidgetPreview: View {
    var body: some View {
        WidgetPreviewView(
            title: "Folder Space Widget",
            icon: "folder.badge.gearshape",
            iconColor: .blue
        ) { family in
            // Folder space widget preview content
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "folder")
                        .foregroundStyle(.blue)
                    Text("Folder Space")
                        .font(.headline)
                    Spacer()
                }
                
                Text("Configure folder in settings")
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
} 