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
        VStack(alignment: .leading, spacing: 20) {
            Text("Folder Space Widget Configuration")
                .font(.title)
                .fontWeight(.bold)
            
            Divider()
            
            // Folder selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Selected Folder")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.blue)
                    
                    Text(selectedFolderName)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button("Select Folder") {
                        showFolderPicker = true
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Refresh interval selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Refresh Interval")
                    .font(.headline)
                
                Picker("Refresh Interval", selection: $refreshInterval) {
                    ForEach(RefreshInterval.allCases) { interval in
                        Text("Every \(interval.displayName)")
                            .tag(interval)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Save button
            Button(action: saveConfiguration) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save Configuration")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedFolderURL == nil)
            .padding(.top, 10)
            
            if isSaved {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Configuration saved! Widget will update shortly.")
                        .foregroundColor(.green)
                }
                .padding(.top, 5)
            }
            
            Spacer()
            
            Text("The widget will monitor the selected folder and display its size. You can add this widget to your desktop by right-clicking on the desktop and selecting 'Edit Widgets'.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
        .onAppear(perform: loadSavedConfiguration)
        .onChange(of: showFolderPicker) { isShowing in
            if isShowing {
                selectFolder()
            }
        }
    }
    
    private func selectFolder() {
        SelectFolderIntentProvider.selectFolder { url, displayName in
            showFolderPicker = false
            
            if let url = url, let displayName = displayName {
                selectedFolderURL = url
                selectedFolderName = displayName
            }
        }
    }
    
    private func saveConfiguration() {
        guard let folderURL = selectedFolderURL else { return }
        
        let configuration = FolderSpaceConfiguration(
            folderURL: folderURL,
            folderDisplayName: selectedFolderName,
            refreshInterval: refreshInterval
        )
        
        do {
            let data = try JSONEncoder().encode(configuration)
            userDefaults?.set(data, forKey: "folderSpaceConfiguration")
            isSaved = true
            
            // Reload the widget
            WidgetCenter.shared.reloadAllTimelines()
            
            // Hide the saved message after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                isSaved = false
            }
        } catch {
            print("Error saving configuration: \(error)")
        }
    }
    
    private func loadSavedConfiguration() {
        guard let data = userDefaults?.data(forKey: "folderSpaceConfiguration") else {
            return
        }
        
        do {
            let configuration = try JSONDecoder().decode(FolderSpaceConfiguration.self, from: data)
            selectedFolderURL = configuration.folderURL
            selectedFolderName = configuration.folderDisplayName
            refreshInterval = configuration.refreshInterval
        } catch {
            print("Error loading configuration: \(error)")
        }
    }
} 