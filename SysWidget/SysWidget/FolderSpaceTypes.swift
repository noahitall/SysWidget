import Foundation
import AppKit

// Define refresh interval options
enum RefreshInterval: Int, CaseIterable, Identifiable, Codable {
    case every15Minutes = 15
    case every30Minutes = 30
    case everyHour = 60
    case every3Hours = 180
    case every6Hours = 360
    case every12Hours = 720
    case everyDay = 1440
    
    var id: Int { self.rawValue }
    
    var displayName: String {
        switch self {
        case .every15Minutes: return "15 minutes"
        case .every30Minutes: return "30 minutes"
        case .everyHour: return "1 hour"
        case .every3Hours: return "3 hours"
        case .every6Hours: return "6 hours"
        case .every12Hours: return "12 hours"
        case .everyDay: return "24 hours"
        }
    }
    
    // Convert to minutes for TimeInterval
    var timeInterval: TimeInterval {
        return TimeInterval(self.rawValue * 60)
    }
}

struct FolderSpaceConfiguration: Codable {
    let folderURL: URL
    let folderDisplayName: String
    let refreshInterval: RefreshInterval
    
    static let `default` = FolderSpaceConfiguration(
        folderURL: URL(fileURLWithPath: NSHomeDirectory()),
        folderDisplayName: "Home",
        refreshInterval: .everyHour
    )
    
    enum CodingKeys: String, CodingKey {
        case folderURL
        case folderDisplayName
        case refreshInterval
    }
    
    init(folderURL: URL, folderDisplayName: String, refreshInterval: RefreshInterval) {
        self.folderURL = folderURL
        self.folderDisplayName = folderDisplayName
        self.refreshInterval = refreshInterval
    }
    
    // Custom initialization from decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode folder URL from bookmark data or path string
        if let bookmarkData = try? container.decode(Data.self, forKey: .folderURL) {
            var isStale = false
            do {
                folderURL = try URL(resolvingBookmarkData: bookmarkData, 
                                   options: .withSecurityScope, 
                                   relativeTo: nil, 
                                   bookmarkDataIsStale: &isStale)
            } catch {
                // Fallback to path string if bookmark fails
                let pathString = try container.decode(String.self, forKey: .folderURL)
                folderURL = URL(fileURLWithPath: pathString)
            }
        } else {
            // Try decoding as a path string
            let pathString = try container.decode(String.self, forKey: .folderURL)
            folderURL = URL(fileURLWithPath: pathString)
        }
        
        folderDisplayName = try container.decode(String.self, forKey: .folderDisplayName)
        
        // Decode refresh interval
        if let intervalValue = try? container.decode(Int.self, forKey: .refreshInterval),
           let interval = RefreshInterval(rawValue: intervalValue) {
            refreshInterval = interval
        } else {
            refreshInterval = .everyHour
        }
    }
    
    // Custom encoding to encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Try to encode URL as a bookmark for security-scoped access
        do {
            let bookmarkData = try folderURL.bookmarkData(options: .withSecurityScope, 
                                                       includingResourceValuesForKeys: nil, 
                                                       relativeTo: nil)
            try container.encode(bookmarkData, forKey: .folderURL)
        } catch {
            // Fallback to path string
            try container.encode(folderURL.path, forKey: .folderURL)
        }
        
        try container.encode(folderDisplayName, forKey: .folderDisplayName)
        try container.encode(refreshInterval.rawValue, forKey: .refreshInterval)
    }
}

// Helper class for folder selection
class SelectFolderIntentProvider {
    static func selectFolder(completion: @escaping (URL?, String?) -> Void) {
        DispatchQueue.main.async {
            let openPanel = NSOpenPanel()
            openPanel.canChooseFiles = false
            openPanel.canChooseDirectories = true
            openPanel.allowsMultipleSelection = false
            openPanel.message = "Select a folder to monitor disk space"
            openPanel.prompt = "Select"
            
            if openPanel.runModal() == .OK, let url = openPanel.url {
                let displayName = url.lastPathComponent
                completion(url, displayName)
            } else {
                completion(nil, nil)
            }
        }
    }
} 