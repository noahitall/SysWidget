import Foundation
import SystemConfiguration
import IOKit.ps
// For network interfaces
import Darwin

// MARK: - Data Point Structs
struct TimeSeriesDataPoint {
    let timestamp: Date
    let value: Double
}

// Codable version of TimeSeriesDataPoint for persistence
struct TimeSeriesDataPointCodable: Codable {
    let timestamp: TimeInterval
    let value: Double
    
    init(from dataPoint: TimeSeriesDataPoint) {
        self.timestamp = dataPoint.timestamp.timeIntervalSince1970
        self.value = dataPoint.value
    }
    
    func toTimeSeriesDataPoint() -> TimeSeriesDataPoint {
        return TimeSeriesDataPoint(
            timestamp: Date(timeIntervalSince1970: timestamp),
            value: value
        )
    }
}

// MARK: - Historical Data Storage
class HistoricalDataManager {
    static let shared = HistoricalDataManager()
    
    // 15 minutes of data with points collected every 15 seconds
    private let maxDataPoints = 60 // 15 minutes * 4 points per minute
    private let samplingInterval: TimeInterval = 15 // Sample every 15 seconds
    
    // UserDefaults keys
    private let memoryHistoryKey = "memoryUsageHistory"
    private let downloadHistoryKey = "networkDownloadHistory"
    private let uploadHistoryKey = "networkUploadHistory"
    private let lastSamplingTimeKey = "lastSamplingTime"
    
    // Historical data storage
    private var memoryUsageHistory: [TimeSeriesDataPoint] = []
    private var networkDownloadHistory: [TimeSeriesDataPoint] = []
    private var networkUploadHistory: [TimeSeriesDataPoint] = []
    
    // Last collection timestamps to prevent duplicate values
    private var lastMemoryCollectionTime = Date(timeIntervalSince1970: 0)
    private var lastNetworkCollectionTime = Date(timeIntervalSince1970: 0)
    
    // Timer for background sampling
    private var backgroundSamplingTimer: Timer?
    
    private init() {
        loadDataFromUserDefaults()
        setupBackgroundSampling()
    }
    
    // Set up background sampling
    private func setupBackgroundSampling() {
        // Create a timer that fires every 15 seconds
        backgroundSamplingTimer = Timer.scheduledTimer(withTimeInterval: samplingInterval, repeats: true) { [weak self] _ in
            self?.sampleNetworkTraffic()
        }
        
        // Make sure timer runs even when widget is not refreshing
        if let timer = backgroundSamplingTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    // Sample network traffic in the background
    private func sampleNetworkTraffic() {
        // Get current network traffic for all interfaces
        let _ = NetworkTrafficData.getCurrentNetworkTraffic(for: "all")
        
        // Get interfaces list
        let interfaces = NetworkInterface.getAvailableInterfaces()
        
        // Sample each active interface
        for interface in interfaces where interface.isUp && interface.name != "all" {
            let _ = NetworkTrafficData.getCurrentNetworkTraffic(for: interface.name)
        }
        
        // Save timestamp of last sampling
        let userDefaults = UserDefaults(suiteName: "group.com.noahzitsman.syswidget") ?? UserDefaults.standard
        userDefaults.set(Date().timeIntervalSince1970, forKey: lastSamplingTimeKey)
        userDefaults.synchronize()
    }
    
    // Load data from UserDefaults
    private func loadDataFromUserDefaults() {
        let userDefaults = UserDefaults(suiteName: "group.com.noahzitsman.syswidget") ?? UserDefaults.standard
        
        if let memoryData = userDefaults.data(forKey: memoryHistoryKey),
           let memoryHistory = try? JSONDecoder().decode([TimeSeriesDataPointCodable].self, from: memoryData) {
            memoryUsageHistory = memoryHistory.map { $0.toTimeSeriesDataPoint() }
        }
        
        if let downloadData = userDefaults.data(forKey: downloadHistoryKey),
           let downloadHistory = try? JSONDecoder().decode([TimeSeriesDataPointCodable].self, from: downloadData) {
            networkDownloadHistory = downloadHistory.map { $0.toTimeSeriesDataPoint() }
        }
        
        if let uploadData = userDefaults.data(forKey: uploadHistoryKey),
           let uploadHistory = try? JSONDecoder().decode([TimeSeriesDataPointCodable].self, from: uploadData) {
            networkUploadHistory = uploadHistory.map { $0.toTimeSeriesDataPoint() }
        }
        
        // Load last sampling time
        lastNetworkCollectionTime = Date(timeIntervalSince1970: userDefaults.double(forKey: lastSamplingTimeKey))
    }
    
    // Save data to UserDefaults
    private func saveDataToUserDefaults() {
        let userDefaults = UserDefaults(suiteName: "group.com.noahzitsman.syswidget") ?? UserDefaults.standard
        
        let memoryHistoryCodable = memoryUsageHistory.map { TimeSeriesDataPointCodable(from: $0) }
        if let memoryData = try? JSONEncoder().encode(memoryHistoryCodable) {
            userDefaults.set(memoryData, forKey: memoryHistoryKey)
        }
        
        let downloadHistoryCodable = networkDownloadHistory.map { TimeSeriesDataPointCodable(from: $0) }
        if let downloadData = try? JSONEncoder().encode(downloadHistoryCodable) {
            userDefaults.set(downloadData, forKey: downloadHistoryKey)
        }
        
        let uploadHistoryCodable = networkUploadHistory.map { TimeSeriesDataPointCodable(from: $0) }
        if let uploadData = try? JSONEncoder().encode(uploadHistoryCodable) {
            userDefaults.set(uploadData, forKey: uploadHistoryKey)
        }
        
        userDefaults.synchronize()
    }
    
    // Add a memory usage data point
    func addMemoryDataPoint(usagePercentage: Double) {
        // Only collect data every samplingInterval seconds
        let now = Date()
        if now.timeIntervalSince(lastMemoryCollectionTime) < samplingInterval {
            return
        }
        
        lastMemoryCollectionTime = now
        memoryUsageHistory.append(TimeSeriesDataPoint(timestamp: now, value: usagePercentage))
        
        // Trim if needed
        if memoryUsageHistory.count > maxDataPoints {
            memoryUsageHistory.removeFirst(memoryUsageHistory.count - maxDataPoints)
        }
        
        // Save to UserDefaults
        saveDataToUserDefaults()
    }
    
    // Add network traffic data points
    func addNetworkDataPoints(downloadSpeed: Double, uploadSpeed: Double) {
        // Only collect data every samplingInterval seconds
        let now = Date()
        if now.timeIntervalSince(lastNetworkCollectionTime) < samplingInterval {
            return
        }
        
        lastNetworkCollectionTime = now
        networkDownloadHistory.append(TimeSeriesDataPoint(timestamp: now, value: downloadSpeed))
        networkUploadHistory.append(TimeSeriesDataPoint(timestamp: now, value: uploadSpeed))
        
        // Trim if needed
        if networkDownloadHistory.count > maxDataPoints {
            networkDownloadHistory.removeFirst(networkDownloadHistory.count - maxDataPoints)
        }
        
        if networkUploadHistory.count > maxDataPoints {
            networkUploadHistory.removeFirst(networkUploadHistory.count - maxDataPoints)
        }
        
        // Save to UserDefaults
        saveDataToUserDefaults()
    }
    
    // Get memory usage history for the specified duration in minutes
    func getMemoryUsageHistory(minutes: Int = 15) -> [TimeSeriesDataPoint] {
        return filterDataPoints(memoryUsageHistory, minutes: minutes)
    }
    
    // Get network download history for the specified duration in minutes
    func getNetworkDownloadHistory(minutes: Int = 15) -> [TimeSeriesDataPoint] {
        return filterDataPoints(networkDownloadHistory, minutes: minutes)
    }
    
    // Get network upload history for the specified duration in minutes
    func getNetworkUploadHistory(minutes: Int = 15) -> [TimeSeriesDataPoint] {
        return filterDataPoints(networkUploadHistory, minutes: minutes)
    }
    
    // Helper function to filter data points by time
    private func filterDataPoints(_ dataPoints: [TimeSeriesDataPoint], minutes: Int) -> [TimeSeriesDataPoint] {
        let cutoffTime = Date().addingTimeInterval(-Double(minutes * 60))
        return dataPoints.filter { $0.timestamp > cutoffTime }
    }
    
    // Clear all data - used when changing interfaces, etc.
    func clearNetworkData() {
        networkDownloadHistory.removeAll()
        networkUploadHistory.removeAll()
        saveDataToUserDefaults()
    }
    
    // Cleanup resources when app terminates
    deinit {
        backgroundSamplingTimer?.invalidate()
    }
}

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
    public let timestamp: Date
    
    // Static timestamp to track last sample time
    private static var lastSampleTime = Date(timeIntervalSince1970: 0)
    
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
        
        let now = Date()
        let memoryData = MemoryUsageData(
            total: total,
            used: used,
            free: free,
            usedPercentage: percentage,
            active: active,
            inactive: inactive,
            wired: wired,
            timestamp: now
        )
        
        // Only add data point to historical data if 15 seconds have passed since last sample
        let samplingInterval: TimeInterval = 15
        if now.timeIntervalSince(lastSampleTime) >= samplingInterval {
            HistoricalDataManager.shared.addMemoryDataPoint(usagePercentage: memoryData.usedPercentage)
            lastSampleTime = now
        }
        
        return memoryData
    }
    
    // Public initializer
    public init(total: UInt64, used: UInt64, free: UInt64, usedPercentage: Double, active: UInt64, inactive: UInt64, wired: UInt64, timestamp: Date) {
        self.total = total
        self.used = used
        self.free = free
        self.usedPercentage = usedPercentage
        self.active = active
        self.inactive = inactive
        self.wired = wired
        self.timestamp = timestamp
    }
}

// MARK: - Network Interface Model
public struct NetworkInterface: Identifiable, Hashable {
    public var id: String { name }
    public let name: String
    public let displayName: String
    public let isUp: Bool
    
    public static func getAvailableInterfaces() -> [NetworkInterface] {
        var interfaces: [NetworkInterface] = []
        
        // Add "All Interfaces" option
        interfaces.append(NetworkInterface(name: "all", displayName: "All Interfaces", isUp: true))
        
        // Get list of network interfaces using getifaddrs
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return interfaces }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        var interfaceNames = Set<String>()
        
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee else { continue }
            let name = String(cString: interface.ifa_name)
            
            // Skip loopback interface
            if name == "lo0" { continue }
            
            // Skip interfaces we've already added
            if !interfaceNames.contains(name) {
                interfaceNames.insert(name)
                
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
                
                let flags = Int32(interface.ifa_flags)
                let isUp = (flags & Int32(IFF_UP) != 0) && (flags & Int32(IFF_RUNNING) != 0)
                
                interfaces.append(NetworkInterface(name: name, displayName: displayName, isUp: isUp))
            }
        }
        
        return interfaces
    }
    
    // Public initializer
    public init(name: String, displayName: String, isUp: Bool) {
        self.name = name
        self.displayName = displayName
        self.isUp = isUp
    }
}

// MARK: - Network Traffic Model
public struct NetworkTrafficData {
    public let upload: Double       // bytes per second
    public let download: Double     // bytes per second
    public let interfaceName: String
    public let timestamp: Date
    
    // Static storage for byte counts across widget refreshes
    private static var lastDownloadBytes: [String: UInt64] = [:]
    private static var lastUploadBytes: [String: UInt64] = [:]
    private static var lastSampleTime: [String: Date] = [:]
    
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
    
    // Helper function to get current network traffic
    public static func getCurrentNetworkTraffic(for interfaceName: String) -> NetworkTrafficData {
        let now = Date()
        var downloadSpeed: Double = 0
        var uploadSpeed: Double = 0
        
        // Get the current byte counts
        let (downloadBytes, uploadBytes) = getInterfaceByteCount(for: interfaceName)
        
        // Calculate speeds based on difference from last sample
        if let lastDownload = lastDownloadBytes[interfaceName],
           let lastUpload = lastUploadBytes[interfaceName],
           let lastTime = lastSampleTime[interfaceName] {
            
            let timeDiff = now.timeIntervalSince(lastTime)
            
            if timeDiff > 0 {
                // Calculate bytes per second
                if downloadBytes >= lastDownload {
                    downloadSpeed = Double(downloadBytes - lastDownload) / timeDiff
                }
                
                if uploadBytes >= lastUpload {
                    uploadSpeed = Double(uploadBytes - lastUpload) / timeDiff
                }
            }
        }
        
        // Store current values for next calculation
        lastDownloadBytes[interfaceName] = downloadBytes
        lastUploadBytes[interfaceName] = uploadBytes
        lastSampleTime[interfaceName] = now
        
        let networkData = NetworkTrafficData(
            upload: uploadSpeed,
            download: downloadSpeed,
            interfaceName: interfaceName,
            timestamp: now
        )
        
        // Add data points to historical data
        HistoricalDataManager.shared.addNetworkDataPoints(downloadSpeed: downloadSpeed, uploadSpeed: uploadSpeed)
        
        return networkData
    }
    
    // Get byte counts for a specific interface or all interfaces
    private static func getInterfaceByteCount(for interfaceName: String) -> (UInt64, UInt64) {
        var totalDownloadBytes: UInt64 = 0
        var totalUploadBytes: UInt64 = 0
        
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return (0, 0) }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee,
                  let addr = interface.ifa_addr,
                  (addr.pointee.sa_family == UInt8(AF_LINK) || addr.pointee.sa_family == UInt8(AF_INET)) else {
                continue
            }
            
            let name = String(cString: interface.ifa_name)
            
            // Skip loopback interface
            if name == "lo0" { continue }
            
            // If we want stats for a specific interface, filter by name
            if interfaceName != "all" && name != interfaceName { continue }
            
            // Get traffic data from the interface
            var data = if_data()
            if addr.pointee.sa_family == UInt8(AF_LINK) {
                let dlAddr = unsafeBitCast(interface.ifa_data, to: UnsafePointer<if_data>.self)
                data = dlAddr.pointee
                
                totalDownloadBytes += UInt64(data.ifi_ibytes)
                totalUploadBytes += UInt64(data.ifi_obytes)
            }
        }
        
        return (totalDownloadBytes, totalUploadBytes)
    }
    
    // Public initializer
    public init(upload: Double, download: Double, interfaceName: String, timestamp: Date) {
        self.upload = upload
        self.download = download
        self.interfaceName = interfaceName
        self.timestamp = timestamp
    }
} 