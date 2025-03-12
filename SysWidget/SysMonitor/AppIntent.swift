//
//  AppIntent.swift
//  SysMonitor
//
//  Created by Noah Zitsman on 3/12/25.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Disk Monitor Configuration" }
    static var description: IntentDescription { "Configure your disk space widget." }

    // Configuration for refresh interval
    @Parameter(title: "Update Frequency", default: .hourly)
    var updateFrequency: UpdateFrequency
}

enum UpdateFrequency: String, AppEnum {
    case minutes15 = "15 minutes"
    case minutes30 = "30 minutes"
    case hourly = "1 hour"
    case hours3 = "3 hours"
    case hours6 = "6 hours"
    case daily = "24 hours"
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Update Frequency")
    static var caseDisplayRepresentations: [UpdateFrequency: DisplayRepresentation] = [
        .minutes15: DisplayRepresentation(title: "Every 15 minutes"),
        .minutes30: DisplayRepresentation(title: "Every 30 minutes"),
        .hourly: DisplayRepresentation(title: "Every hour"),
        .hours3: DisplayRepresentation(title: "Every 3 hours"),
        .hours6: DisplayRepresentation(title: "Every 6 hours"),
        .daily: DisplayRepresentation(title: "Once a day")
    ]
    
    var timeInterval: TimeInterval {
        switch self {
        case .minutes15: return 15 * 60
        case .minutes30: return 30 * 60
        case .hourly: return 60 * 60
        case .hours3: return 3 * 60 * 60
        case .hours6: return 6 * 60 * 60
        case .daily: return 24 * 60 * 60
        }
    }
}
