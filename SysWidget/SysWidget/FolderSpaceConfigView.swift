import SwiftUI
import WidgetKit

struct FolderSpaceConfigView: View {
    @State private var selectedFolderURL: URL? = nil
    @State private var selectedFolderName: String = "Not selected"
    @State private var refreshInterval: RefreshInterval = .everyHour
    @State private var showFolderPicker = false
    @State private var isSaved = false
    
    private let userDefaults = UserDefaults(suiteName: "group.com.noahzitsman.syswidget")
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "folder.badge.gearshape")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                    Text("Folder Widget Configuration")
                        .font(.system(size: 24, weight: .bold))
                }
                .padding(.top)
                
                // Folder Selection Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Selected Folder")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.blue)
                        
                        Text(selectedFolderName)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Button(action: { showFolderPicker = true }) {
                            HStack {
                                Image(systemName: "folder.badge.plus")
                                Text("Select Folder")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Refresh Interval Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Refresh Interval")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(RefreshInterval.allCases) { interval in
                            HStack {
                                Image(systemName: refreshInterval == interval ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(refreshInterval == interval ? .blue : .gray)
                                
                                Text("Every \(interval.displayName)")
                                    .font(.system(size: 14))
                                
                                Spacer()
                            }
                            .padding()
                            .background(refreshInterval == interval ? Color.blue.opacity(0.1) : Color.clear)
                            .cornerRadius(8)
                            .onTapGesture {
                                refreshInterval = interval
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Save Button Card
                VStack(spacing: 12) {
                    Button(action: saveConfiguration) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Configuration")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedFolderURL != nil ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(selectedFolderURL == nil)
                    
                    if isSaved {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Configuration saved! Widget will update shortly.")
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                
                // Instructions Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Widget Instructions")
                            .font(.headline)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        InstructionRow(number: 1, text: "Right-click on your desktop")
                        InstructionRow(number: 2, text: "Select 'Edit Widgets'")
                        InstructionRow(number: 3, text: "Find 'Folder Space' in the widget gallery")
                        InstructionRow(number: 4, text: "Drag it to your desktop")
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            .padding()
        }
        .fileImporter(
            isPresented: $showFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    selectedFolderURL = url
                    selectedFolderName = url.lastPathComponent
                }
            case .failure(let error):
                print("Error selecting folder: \(error.localizedDescription)")
            }
        }
        .onAppear(perform: loadSavedConfiguration)
    }
    
    private func saveConfiguration() {
        guard let url = selectedFolderURL else { return }
        
        userDefaults?.set(url.path, forKey: "selectedFolderPath")
        userDefaults?.set(refreshInterval.rawValue, forKey: "refreshInterval")
        
        isSaved = true
        WidgetCenter.shared.reloadAllTimelines()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isSaved = false
        }
    }
    
    private func loadSavedConfiguration() {
        if let savedPath = userDefaults?.string(forKey: "selectedFolderPath") {
            selectedFolderURL = URL(fileURLWithPath: savedPath)
            selectedFolderName = selectedFolderURL?.lastPathComponent ?? "Not selected"
        }
        
        if let savedInterval = userDefaults?.integer(forKey: "refreshInterval"),
           let interval = RefreshInterval(rawValue: savedInterval) {
            refreshInterval = interval
        }
    }
}

struct InstructionRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 24, height: 24)
                
                Text("\(number)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.blue)
            }
            
            Text(text)
                .font(.system(size: 14))
        }
    }
}

#Preview {
    FolderSpaceConfigView()
} 