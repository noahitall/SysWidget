//
//  ContentView.swift
//  SysWidget
//
//  Created by Noah Zitsman on 3/12/25.
//

import SwiftUI
import WidgetKit
import AppKit

struct ContentView: View {
    @StateObject private var metricsModel = SystemMetricsModel()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // System Metrics tab
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("System Metrics")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top)
                        
                        // Disk Usage Section
                        SectionView(title: "Disk Usage", icon: "internaldrive", color: .blue) {
                            VStack(spacing: 16) {
                                HStack {
                                    MetricCard(
                                        title: "Total",
                                        value: metricsModel.diskUsage.totalFormatted,
                                        icon: "internaldrive.fill",
                                        color: .blue
                                    )
                                    
                                    MetricCard(
                                        title: "Free",
                                        value: metricsModel.diskUsage.freeFormatted,
                                        icon: "internaldrive",
                                        color: .green
                                    )
                                }
                                
                                ProgressView(value: metricsModel.diskUsage.usedPercentage, total: 100) {
                                    HStack {
                                        Text("Used: \(metricsModel.diskUsage.usedFormatted)")
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(Int(metricsModel.diskUsage.usedPercentage))%")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                }
                                .tint(.blue)
                            }
                        }
                        
                        // Memory Usage Section
                        SectionView(title: "Memory Usage", icon: "memorychip", color: .green) {
                            VStack(spacing: 16) {
                                HStack {
                                    MetricCard(
                                        title: "Total",
                                        value: metricsModel.memoryUsage.totalFormatted,
                                        icon: "memorychip.fill",
                                        color: .green
                                    )
                                    
                                    MetricCard(
                                        title: "Free",
                                        value: metricsModel.memoryUsage.freeFormatted,
                                        icon: "memorychip",
                                        color: .blue
                                    )
                                }
                                
                                ProgressView(value: metricsModel.memoryUsage.usedPercentage, total: 100) {
                                    HStack {
                                        Text("Used: \(metricsModel.memoryUsage.usedFormatted)")
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(Int(metricsModel.memoryUsage.usedPercentage))%")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                }
                                .tint(.green)
                            }
                        }
                        
                        // CPU Temperature Section
                        SectionView(title: "CPU Temperature", icon: "thermometer", color: temperatureColor) {
                            VStack(alignment: .center, spacing: 16) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                                        .frame(width: 150, height: 150)
                                    
                                    Circle()
                                        .trim(from: 0, to: CGFloat(metricsModel.cpuTemperature) / 100)
                                        .stroke(temperatureColor, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                                        .frame(width: 150, height: 150)
                                        .rotationEffect(.degrees(-90))
                                    
                                    VStack {
                                        Text("\(Int(metricsModel.cpuTemperature))°C")
                                            .font(.system(size: 36, weight: .bold))
                                            .foregroundColor(temperatureColor)
                                        
                                        Text(temperatureStatus)
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        
                        // Network Traffic Section
                        SectionView(title: "Network Traffic", icon: "network", color: .purple) {
                            VStack(spacing: 16) {
                                HStack {
                                    MetricCard(
                                        title: "Upload",
                                        value: metricsModel.networkTraffic.uploadFormatted,
                                        icon: "arrow.up.circle.fill",
                                        color: .blue
                                    )
                                    
                                    MetricCard(
                                        title: "Download",
                                        value: metricsModel.networkTraffic.downloadFormatted,
                                        icon: "arrow.down.circle.fill",
                                        color: .green
                                    )
                                }
                            }
                        }
                        
                        // Widget Instructions
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Widget Instructions")
                                .font(.headline)
                                .padding(.top)
                            
                            Text("To add this widget to your desktop:")
                                .font(.subheadline)
                            
                            Text("1. Long press on your desktop")
                                .font(.subheadline)
                            
                            Text("2. Click 'Edit Widgets'")
                                .font(.subheadline)
                            
                            Text("3. Find 'System Metrics' in the widget gallery")
                                .font(.subheadline)
                            
                            Text("4. Drag it to your desktop")
                                .font(.subheadline)
                            
                            Button("Refresh Widgets") {
                                WidgetCenter.shared.reloadAllTimelines()
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.top, 8)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding()
                }
                .navigationTitle("System Metrics")
                .tabItem {
                    Image(systemName: "gauge")
                    Text("System Metrics")
                }
                .tag(0)
                
                // Folder Space Widget Configuration tab
                FolderSpaceConfigView()
                .navigationTitle("Folder Space Widget")
                .tabItem {
                    Image(systemName: "folder.badge.gearshape")
                    Text("Folder Widget")
                }
                .tag(1)
            }
        }
    }
    
    private var temperatureColor: Color {
        if metricsModel.cpuTemperature < 50 {
            return .green
        } else if metricsModel.cpuTemperature < 70 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var temperatureStatus: String {
        if metricsModel.cpuTemperature < 50 {
            return "Normal"
        } else if metricsModel.cpuTemperature < 70 {
            return "Warm"
        } else {
            return "Hot"
        }
    }
}

struct SectionView<Content: View>: View {
    var title: String
    var icon: String
    var color: Color
    let content: Content
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            content
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MetricCard: View {
    var title: String
    var value: String
    var icon: String
    var color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    ContentView()
}
