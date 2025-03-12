//
//  SysMonitor.swift
//  SysMonitor
//
//  Created by Noah Zitsman on 3/12/25.
//

import WidgetKit
import SwiftUI

// MARK: - This file has been reorganized
/*
 This file previously contained the original SysMonitor widget implementation.
 The code has been restructured and split into separate files for better maintainability:
 
 - DiskSpaceWidget.swift: Contains the disk space monitoring widget
 - MemoryWidget.swift: Contains the memory usage monitoring widget
 - NetworkWidget.swift: Contains the network traffic monitoring widget
 - SysMonitorModels.swift: Contains shared data models and utilities
 - AppIntent.swift: Contains configuration intents for all widgets
 - SysMonitorBundle.swift: Contains the widget bundle configuration
 
 This reorganization allows for more modular code and easier maintenance.
*/

// Legacy widget implementation - this is kept only for reference
// All functionality has been moved to separate files
// This code will be removed once migration is complete

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "Configure the widget." }

    @Parameter(title: "Update Frequency", default: .hourly)
    var updateFrequency: UpdateFrequency
}
