//
//  SysMonitorBundle.swift
//  SysMonitor
//
//  Created by Noah Zitsman on 3/12/25.
//

import WidgetKit
import SwiftUI

@main
struct SysMonitorBundle: WidgetBundle {
    var body: some Widget {
        // Disk Space Widget
        DiskSpaceWidget()
        
        // Memory Usage Widget
        MemoryUsageWidget()
        
        // Network Traffic Widget
        NetworkTrafficWidget()
    }
}
