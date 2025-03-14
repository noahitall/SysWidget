//
//  AppIntent.swift
//  SysMonitor
//
//  Created by Noah Zitsman on 3/12/25.
//

import WidgetKit
import AppIntents

// MARK: - Common Update Frequency

enum UpdateFrequency: String, AppEnum {
    case seconds1 = "1 second"
    case seconds5 = "5 seconds"
    case seconds10 = "10 seconds"
    case seconds30 = "30 seconds"
    case minutes1 = "1 minute"
    case minutes5 = "5 minutes"
    case minutes15 = "15 minutes"
    case minutes30 = "30 minutes"
    case hourly = "1 hour"
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Update Frequency")
    static var caseDisplayRepresentations: [UpdateFrequency: DisplayRepresentation] = [
        .seconds1: DisplayRepresentation(title: "Every second"),
        .seconds5: DisplayRepresentation(title: "Every 5 seconds"),
        .seconds10: DisplayRepresentation(title: "Every 10 seconds"),
        .seconds30: DisplayRepresentation(title: "Every 30 seconds"),
        .minutes1: DisplayRepresentation(title: "Every minute"),
        .minutes5: DisplayRepresentation(title: "Every 5 minutes"),
        .minutes15: DisplayRepresentation(title: "Every 15 minutes"),
        .minutes30: DisplayRepresentation(title: "Every 30 minutes"),
        .hourly: DisplayRepresentation(title: "Every hour")
    ]
    
    var timeInterval: TimeInterval {
        switch self {
        case .seconds1: return 1
        case .seconds5: return 5
        case .seconds10: return 10
        case .seconds30: return 30
        case .minutes1: return 60
        case .minutes5: return 5 * 60
        case .minutes15: return 15 * 60
        case .minutes30: return 30 * 60
        case .hourly: return 60 * 60
        }
    }
}

// MARK: - Disk Space Widget Configuration

struct DiskSpaceConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Disk Space Configuration" }
    static var description: IntentDescription { "Configure the disk space widget." }

    @Parameter(title: "Update Frequency", default: .minutes5)
    var updateFrequency: UpdateFrequency
}

// MARK: - Memory Widget Configuration

struct MemoryConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Memory Usage Configuration" }
    static var description: IntentDescription { "Configure the memory usage widget." }

    @Parameter(title: "Update Frequency", default: .seconds1)
    var updateFrequency: UpdateFrequency
}

// MARK: - Network Widget Configuration

struct NetworkInterfaceEntity: AppEntity {
    var id: String
    var name: String
    
    static var defaultQuery = NetworkInterfaceQuery()
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Network Interface")
    }
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct NetworkInterfaceQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [NetworkInterfaceEntity] {
        return identifiers.map { NetworkInterfaceEntity(id: $0, name: getDisplayName(for: $0)) }
    }
    
    func suggestedEntities() async throws -> [NetworkInterfaceEntity] {
        // Return list of available network interfaces
        return NetworkInterface.getAvailableInterfaces().map { 
            NetworkInterfaceEntity(id: $0.name, name: $0.displayName)
        }
    }
    
    private func getDisplayName(for interfaceID: String) -> String {
        if interfaceID == "all" {
            return "All Interfaces"
        }
        
        let interfaces = NetworkInterface.getAvailableInterfaces()
        if let match = interfaces.first(where: { $0.name == interfaceID }) {
            return match.displayName
        }
        
        return interfaceID
    }
}

struct NetworkTrafficConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Network Traffic Configuration" }
    static var description: IntentDescription { "Configure network traffic monitoring." }

    @Parameter(title: "Update Frequency", default: .seconds1)
    var updateFrequency: UpdateFrequency
    
    // Remove the static property approach
    @Parameter(title: "Network Interface")
    var networkInterface: NetworkInterfaceEntity
    
    // Implement init to set default value
    init() {
        self.networkInterface = NetworkInterfaceEntity(id: "all", name: "All Interfaces")
    }
    
    // Required initializer for AppIntent protocol
    init(updateFrequency: UpdateFrequency, networkInterface: NetworkInterfaceEntity) {
        self.updateFrequency = updateFrequency
        self.networkInterface = networkInterface
    }
}
