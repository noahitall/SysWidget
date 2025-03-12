import AppKit
import Intents
import WidgetKit

// Define refresh interval options
enum RefreshInterval: Int, CaseIterable, Identifiable {
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
}

// Intent definition for folder selection
class SelectFolderIntent: INIntent {
    var folderURL: URL?
    var folderDisplayName: String?
    var refreshInterval: RefreshInterval = .everyHour
    
    init(folderURL: URL?, folderDisplayName: String?, refreshInterval: RefreshInterval = .everyHour) {
        self.folderURL = folderURL
        self.folderDisplayName = folderDisplayName
        self.refreshInterval = refreshInterval
        super.init()
    }
    
    required init?(coder: NSCoder) {
        self.folderURL = coder.decodeObject(forKey: "folderURL") as? URL
        self.folderDisplayName = coder.decodeObject(forKey: "folderDisplayName") as? String
        if let intervalValue = coder.decodeObject(forKey: "refreshInterval") as? Int,
           let interval = RefreshInterval(rawValue: intervalValue) {
            self.refreshInterval = interval
        } else {
            self.refreshInterval = .everyHour
        }
        super.init(coder: coder)
    }
    
    override func encodeWithCoder(_ coder: NSCoder) {
        super.encodeWithCoder(coder)
        coder.encode(folderURL, forKey: "folderURL")
        coder.encode(folderDisplayName, forKey: "folderDisplayName")
        coder.encode(refreshInterval.rawValue, forKey: "refreshInterval")
    }
}

// Provider class for intent handling
class SelectFolderIntentProvider {
    static func createConfiguration(from intent: SelectFolderIntent) -> FolderSpaceConfiguration {
        // Create a configuration based on the user's selections
        if let folderURL = intent.folderURL, let displayName = intent.folderDisplayName {
            return FolderSpaceConfiguration(
                folderURL: folderURL,
                folderDisplayName: displayName,
                refreshInterval: intent.refreshInterval
            )
        } else {
            return FolderSpaceConfiguration.default
        }
    }
    
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