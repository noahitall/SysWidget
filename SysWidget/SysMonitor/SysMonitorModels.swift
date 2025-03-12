import Foundation
import SystemConfiguration
import IOKit.ps
// For network interfaces
import Darwin

// MARK: - Disk Usage Model
public struct DiskUsageData {
    public let total: UInt64
    public let free: UInt64
    public let used: UInt64
    public let usedPercentage: Double
    
    public var totalFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(total), countStyle: .file)
    }
    
    public var freeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(free), countStyle: .file)
    }
    
    public var usedFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(used), countStyle: .file)
    }
    
    // Helper function to get disk usage information
    public static func getCurrentDiskUsage() -> DiskUsageData {
        let fileURL = URL(fileURLWithPath: "/")
        var total: UInt64 = 0
        var free: UInt64 = 0
        var used: UInt64 = 0
        var percentage: Double = 0
        
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
            if let totalCapacity = values.volumeTotalCapacity, let availableCapacity = values.volumeAvailableCapacity {
                total = UInt64(totalCapacity)
                free = UInt64(availableCapacity)
                used = total - free
                percentage = Double(used) / Double(total) * 100
            }
        } catch {
            print("Error getting disk usage: \(error)")
        }
        
        return DiskUsageData(
            total: total,
            free: free,
            used: used,
            usedPercentage: percentage
        )
    }
    
    // Public initializer
    public init(total: UInt64, free: UInt64, used: UInt64, usedPercentage: Double) {
        self.total = total
        self.free = free
        self.used = used
        self.usedPercentage = usedPercentage
    }
}

// MARK: - Memory Usage Model
public struct MemoryUsageData {
    public let total: UInt64
    public let used: UInt64
    public let free: UInt64
    public let usedPercentage: Double
    public let active: UInt64
    public let inactive: UInt64
    public let wired: UInt64
    
    public var totalFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(total), countStyle: .memory)
    }
    
    public var freeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(free), countStyle: .memory)
    }
    
    public var usedFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(used), countStyle: .memory)
    }
    
    public var activeFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(active), countStyle: .memory)
    }
    
    public var inactiveFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(inactive), countStyle: .memory)
    }
    
    public var wiredFormatted: String {
        ByteCountFormatter.string(fromByteCount: Int64(wired), countStyle: .memory)
    }
    
    // Helper function to get memory usage information
    public static func getCurrentMemoryUsage() -> MemoryUsageData {
        var total: UInt64 = 0
        var free: UInt64 = 0
        var used: UInt64 = 0
        var active: UInt64 = 0
        var inactive: UInt64 = 0
        var wired: UInt64 = 0
        var percentage: Double = 0
        
        // Get total physical memory
        total = ProcessInfo.processInfo.physicalMemory
        
        // Get memory usage statistics
        var stats = vm_statistics64()
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let hostPort = mach_host_self()
        let kernReturn = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &size)
            }
        }
        
        if kernReturn == KERN_SUCCESS {
            let pageSize = UInt64(vm_kernel_page_size)
            free = UInt64(stats.free_count) * pageSize
            active = UInt64(stats.active_count) * pageSize
            inactive = UInt64(stats.inactive_count) * pageSize
            wired = UInt64(stats.wire_count) * pageSize
            let compressed = UInt64(stats.compressor_page_count) * pageSize
            
            used = active + wired + compressed
            percentage = Double(used) / Double(total) * 100
        }
        
        return MemoryUsageData(
            total: total,
            used: used,
            free: free,
            usedPercentage: percentage,
            active: active,
            inactive: inactive,
            wired: wired
        )
    }
    
    // Public initializer
    public init(total: UInt64, used: UInt64, free: UInt64, usedPercentage: Double, active: UInt64, inactive: UInt64, wired: UInt64) {
        self.total = total
        self.used = used
        self.free = free
        self.usedPercentage = usedPercentage
        self.active = active
        self.inactive = inactive
        self.wired = wired
    }
}

// MARK: - Network Interface Model
public struct NetworkInterface: Identifiable, Hashable {
    public var id: String { name }
    public let name: String
    public let displayName: String
    
    public static func getAvailableInterfaces() -> [NetworkInterface] {
        var interfaces: [NetworkInterface] = []
        
        // Add "All Interfaces" option
        interfaces.append(NetworkInterface(name: "all", displayName: "All Interfaces"))
        
        // Get list of network interfaces using getifaddrs
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return interfaces }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee else { continue }
            let name = String(cString: interface.ifa_name)
            
            // Skip loopback interface
            if name == "lo0" { continue }
            
            // Skip interfaces we've already added
            if !interfaces.contains(where: { $0.name == name }) {
                // Create a display name
                let displayName: String
                if name.hasPrefix("en") {
                    displayName = "Wi-Fi (\(name))"
                } else if name.hasPrefix("bridge") {
                    displayName = "Bridge (\(name))"
                } else if name.hasPrefix("awdl") {
                    displayName = "AWDL (\(name))"
                } else if name.hasPrefix("llw") {
                    displayName = "Low Latency (\(name))"
                } else {
                    displayName = name
                }
                
                interfaces.append(NetworkInterface(name: name, displayName: displayName))
            }
        }
        
        return interfaces
    }
    
    // Public initializer
    public init(name: String, displayName: String) {
        self.name = name
        self.displayName = displayName
    }
}

// MARK: - Network Traffic Model
public struct NetworkTrafficData {
    public let upload: Double       // bytes per second
    public let download: Double     // bytes per second
    public let interfaceName: String
    public let timestamp: Date
    
    public var uploadFormatted: String {
        formatBandwidth(upload)
    }
    
    public var downloadFormatted: String {
        formatBandwidth(download)
    }
    
    private func formatBandwidth(_ bytesPerSecond: Double) -> String {
        if bytesPerSecond < 1024 {
            return String(format: "%.1f B/s", bytesPerSecond)
        } else if bytesPerSecond < 1024 * 1024 {
            return String(format: "%.1f KB/s", bytesPerSecond / 1024)
        } else if bytesPerSecond < 1024 * 1024 * 1024 {
            return String(format: "%.1f MB/s", bytesPerSecond / (1024 * 1024))
        } else {
            return String(format: "%.2f GB/s", bytesPerSecond / (1024 * 1024 * 1024))
        }
    }
    
    // Helper function to get simulated network traffic
    // In a real implementation, you would track actual network usage over time
    public static func getCurrentNetworkTraffic(for interfaceName: String) -> NetworkTrafficData {
        // For a real implementation, you'd need to:
        // 1. Track previous and current bytes transmitted/received
        // 2. Calculate the difference over time
        // 3. Store this information between widget refreshes
        
        // This is a placeholder with simulated values:
        let download = interfaceName == "all" ? 
            Double.random(in: 0...1024 * 1024) : // 0-1MB/s
            Double.random(in: 0...512 * 1024)    // 0-512KB/s
        
        let upload = interfaceName == "all" ? 
            Double.random(in: 0...512 * 1024) :  // 0-512KB/s
            Double.random(in: 0...256 * 1024)    // 0-256KB/s
        
        return NetworkTrafficData(
            upload: upload,
            download: download,
            interfaceName: interfaceName,
            timestamp: Date()
        )
    }
    
    // Public initializer
    public init(upload: Double, download: Double, interfaceName: String, timestamp: Date) {
        self.upload = upload
        self.download = download
        self.interfaceName = interfaceName
        self.timestamp = timestamp
    }
} 