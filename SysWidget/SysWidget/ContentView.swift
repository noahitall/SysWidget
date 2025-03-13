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
                // Memory Widget Preview
                MemoryWidgetPreview()
                    .tabItem {
                        Image(systemName: "memorychip")
                        Text("Memory")
                    }
                    .tag(0)
                
                // Disk Space Widget Preview
                DiskSpaceWidgetPreview()
                    .tabItem {
                        Image(systemName: "internaldrive")
                        Text("Disk Space")
                    }
                    .tag(1)
                
                // Network Widget Preview
                NetworkWidgetPreview()
                    .tabItem {
                        Image(systemName: "network")
                        Text("Network")
                    }
                    .tag(2)
                
                // Folder Space Widget Preview and Configuration
                FolderSpaceConfigView()
                    .tabItem {
                        Image(systemName: "folder.badge.gearshape")
                        Text("Folder Space")
                    }
                    .tag(3)
            }
        }
    }
}

#Preview {
    ContentView()
}
