import Foundation

class FolderSpaceModel {
    struct FolderSize {
        let url: URL
        let displayName: String
        let totalBytes: Int64
        let fileCount: Int
        let folderCount: Int
        
        var sizeFormatted: String {
            return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        }
        
        var sizePercentage: Double {
            // Calculate percentage of total disk space
            do {
                let values = try url.resourceValues(forKeys: [.volumeTotalCapacityKey])
                if let totalCapacity = values.volumeTotalCapacity {
                    return Double(totalBytes) / Double(totalCapacity) * 100.0
                }
            } catch {
                print("Error getting volume capacity: \(error)")
            }
            return 0
        }
        
        // Get the total disk space of the volume containing this folder
        var totalDiskSpace: Int64 {
            do {
                let values = try url.resourceValues(forKeys: [.volumeTotalCapacityKey])
                if let totalCapacity = values.volumeTotalCapacity {
                    return Int64(totalCapacity)
                }
            } catch {
                print("Error getting volume capacity: \(error)")
            }
            return 0
        }
        
        // Get the used disk space of the volume containing this folder
        var totalDiskSpaceUsed: Int64 {
            do {
                let values = try url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey])
                if let totalCapacity = values.volumeTotalCapacity, 
                   let availableCapacity = values.volumeAvailableCapacity {
                    return Int64(totalCapacity - availableCapacity)
                }
            } catch {
                print("Error getting volume capacity: \(error)")
            }
            return 0
        }
        
        // Relative size compared to the entire disk space
        var relativeSizeDescription: String {
            let percentage = sizePercentage
            if percentage < 0.1 {
                return "Negligible (<0.1%)"
            } else if percentage < 1 {
                return "Very small (< 1%)"
            } else if percentage < 5 {
                return "Small (< 5%)"
            } else if percentage < 15 {
                return "Moderate"
            } else if percentage < 30 {
                return "Significant"
            } else if percentage < 50 {
                return "Large"
            } else {
                return "Very large"
            }
        }
        
        // Get a color representing the size (from green to red based on size)
        var colorCode: String {
            let percentage = sizePercentage
            if percentage < 5 {
                return "green"  // Small
            } else if percentage < 15 {
                return "blue"   // Moderate
            } else if percentage < 30 {
                return "orange" // Significant
            } else {
                return "red"    // Large
            }
        }
    }
    
    // Calculate the size of a folder recursively
    static func calculateFolderSize(url: URL, displayName: String) -> FolderSize? {
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]) else {
            return nil
        }
        
        var totalSize: Int64 = 0
        var fileCount = 0
        var folderCount = 0
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                
                if let isDirectory = resourceValues.isDirectory, isDirectory {
                    folderCount += 1
                } else {
                    fileCount += 1
                    if let fileSize = resourceValues.fileSize {
                        totalSize += Int64(fileSize)
                    }
                }
                
            } catch {
                print("Error: \(error)")
            }
        }
        
        return FolderSize(
            url: url,
            displayName: displayName,
            totalBytes: totalSize,
            fileCount: fileCount,
            folderCount: folderCount
        )
    }
    
    // Asynchronously calculate folder size to avoid blocking UI
    static func calculateFolderSizeAsync(url: URL, displayName: String, completion: @escaping (FolderSize?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = calculateFolderSize(url: url, displayName: displayName)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
} 