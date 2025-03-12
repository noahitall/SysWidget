import Foundation
import IOKit
import IOKit.ps

class SystemMetricsModel: ObservableObject {
    @Published var diskUsage: DiskUsage = DiskUsage()
    @Published var memoryUsage: MemoryUsage = MemoryUsage()
    @Published var cpuTemperature: Double = 0.0
    @Published var networkTraffic: NetworkTraffic = NetworkTraffic()
    
    private var timer: Timer?
    
    struct DiskUsage {
        var total: UInt64 = 0
        var free: UInt64 = 0
        var used: UInt64 = 0
        var usedPercentage: Double = 0
        
        var totalFormatted: String {
            ByteCountFormatter.string(fromByteCount: Int64(total), countStyle: .file)
        }
        
        var freeFormatted: String {
            ByteCountFormatter.string(fromByteCount: Int64(free), countStyle: .file)
        }
        
        var usedFormatted: String {
            ByteCountFormatter.string(fromByteCount: Int64(used), countStyle: .file)
        }
    }
    
    struct MemoryUsage {
        var total: UInt64 = 0
        var used: UInt64 = 0
        var free: UInt64 = 0
        var usedPercentage: Double = 0
        
        var totalFormatted: String {
            ByteCountFormatter.string(fromByteCount: Int64(total), countStyle: .memory)
        }
        
        var freeFormatted: String {
            ByteCountFormatter.string(fromByteCount: Int64(free), countStyle: .memory)
        }
        
        var usedFormatted: String {
            ByteCountFormatter.string(fromByteCount: Int64(used), countStyle: .memory)
        }
    }
    
    struct NetworkTraffic {
        var upload: Double = 0  // bytes per second
        var download: Double = 0 // bytes per second
        
        var uploadFormatted: String {
            ByteCountFormatter.string(fromByteCount: Int64(upload), countStyle: .memory) + "/s"
        }
        
        var downloadFormatted: String {
            ByteCountFormatter.string(fromByteCount: Int64(download), countStyle: .memory) + "/s"
        }
    }
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        updateMetrics()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    // This method is specifically for widget use, as widgets don't have continuous timers
    func updateMetricsForWidget() {
        updateDiskUsage()
        updateMemoryUsage()
        updateCPUTemperature()
        updateNetworkTraffic()
    }
    
    private func updateMetrics() {
        updateDiskUsage()
        updateMemoryUsage()
        updateCPUTemperature()
        updateNetworkTraffic()
    }
    
    private func updateDiskUsage() {
        let fileURL = URL(fileURLWithPath: "/")
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
            if let totalCapacity = values.volumeTotalCapacity, let availableCapacity = values.volumeAvailableCapacity {
                diskUsage.total = UInt64(totalCapacity)
                diskUsage.free = UInt64(availableCapacity)
                diskUsage.used = diskUsage.total - diskUsage.free
                diskUsage.usedPercentage = Double(diskUsage.used) / Double(diskUsage.total) * 100
            }
        } catch {
            print("Error getting disk usage: \(error)")
        }
    }
    
    private func updateMemoryUsage() {
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
            let total = ProcessInfo.processInfo.physicalMemory
            let free = UInt64(stats.free_count) * pageSize
            let active = UInt64(stats.active_count) * pageSize
            let inactive = UInt64(stats.inactive_count) * pageSize
            let wired = UInt64(stats.wire_count) * pageSize
            let compressed = UInt64(stats.compressor_page_count) * pageSize
            
            let used = active + wired + compressed
            
            memoryUsage.total = total
            memoryUsage.used = used
            memoryUsage.free = free
            memoryUsage.usedPercentage = Double(used) / Double(total) * 100
        }
    }
    
    private func updateCPUTemperature() {
        // This is a placeholder - actual CPU temperature monitoring requires SMC access
        // For a real implementation, consider using a library like SMCKit
        // This is a simulated value between 30-80 degrees Celsius
        self.cpuTemperature = Double.random(in: 30...80)
    }
    
    private func updateNetworkTraffic() {
        // This is a placeholder - actual network traffic monitoring is complex
        // For a real implementation, consider using APIs like getifaddrs or a library
        // These are simulated values
        self.networkTraffic.download = Double.random(in: 0...1024 * 1024) // 0-1MB/s
        self.networkTraffic.upload = Double.random(in: 0...512 * 1024) // 0-512KB/s
    }
} 