import SwiftUI
import WidgetKit

// Small widget view - compact display of folder size
struct FolderSpaceSmallView: View {
    var folderSize: FolderSpaceModel.FolderSize
    var folderName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(.blue)
                Text(folderName)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .center, spacing: 8) {
                // Circular progress view
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 90, height: 90)
                    
                    Circle()
                        .trim(from: 0, to: folderSize.sizePercentage / 100)
                        .stroke(
                            Color(folderSize.colorCode),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 0) {
                        Text(folderSize.sizeFormatted)
                            .font(.system(size: 16, weight: .bold))
                        
                        Text("\(Int(folderSize.sizePercentage))%")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Stats
                HStack(spacing: 4) {
                    Text("\(folderSize.fileCount) files")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            
            Spacer()
        }
        .padding()
    }
}

// Medium widget view - more detailed info including files and folders
struct FolderSpaceMediumView: View {
    var folderSize: FolderSpaceModel.FolderSize
    var folderName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(.blue)
                Text(folderName)
                    .font(.system(size: 14, weight: .bold))
                Spacer()
            }
            
            Divider()
            
            HStack(spacing: 15) {
                // Left: Circular progress indicator
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: folderSize.sizePercentage / 100)
                        .stroke(
                            Color(folderSize.colorCode),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text(folderSize.sizeFormatted)
                            .font(.system(size: 16, weight: .bold))
                        
                        Text("\(Int(folderSize.sizePercentage))%")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Right: Stats
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundColor(.blue)
                        Text("\(folderSize.fileCount) files")
                            .font(.system(size: 14))
                    }
                    
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.blue)
                        Text("\(folderSize.folderCount) folders")
                            .font(.system(size: 14))
                    }
                    
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(Color(folderSize.colorCode))
                        Text(folderSize.relativeSizeDescription)
                            .font(.system(size: 14))
                            .foregroundColor(Color(folderSize.colorCode))
                    }
                }
                .padding(.leading, 5)
            }
            
            Spacer()
        }
        .padding()
    }
}

// Large widget view - comprehensive info with bar chart and detailed stats
struct FolderSpaceLargeView: View {
    var folderSize: FolderSpaceModel.FolderSize
    var folderName: String
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(.blue)
                Text(folderName)
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Text("Updated: \(formattedDate)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Main stats
            HStack(alignment: .top, spacing: 20) {
                // Left column: Circle chart
                VStack(alignment: .center) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: folderSize.sizePercentage / 100)
                            .stroke(
                                Color(folderSize.colorCode),
                                style: StrokeStyle(lineWidth: 15, lineCap: .round)
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 4) {
                            Text(folderSize.sizeFormatted)
                                .font(.system(size: 18, weight: .bold))
                            
                            Text("\(Int(folderSize.sizePercentage))% of disk")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(folderSize.relativeSizeDescription)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(folderSize.colorCode))
                        .padding(.top, 8)
                }
                .frame(width: 130)
                
                // Right column: Detailed stats
                VStack(alignment: .leading, spacing: 10) {
                    Text("Folder Statistics")
                        .font(.system(size: 14, weight: .bold))
                    
                    Group {
                        HStack {
                            Image(systemName: "doc.fill")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Files")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text("\(folderSize.fileCount)")
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }
                        
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Folders")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text("\(folderSize.folderCount)")
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }
                        
                        HStack {
                            Image(systemName: "externaldrive.fill")
                                .foregroundColor(.green)
                                .frame(width: 20)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Total Disk Size")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                Text(ByteCountFormatter.string(fromByteCount: folderSize.totalDiskSpace, countStyle: .file))
                                    .font(.system(size: 14, weight: .medium))
                            }
                        }
                    }
                }
            }
            
            // Bar chart comparing folder size to total volume
            VStack(alignment: .leading, spacing: 6) {
                Text("Disk Usage Comparison")
                    .font(.system(size: 14, weight: .bold))
                
                // Total volume usage bar
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Volume Usage")
                            .font(.system(size: 12))
                        Spacer()
                        let volumePercentage = Double(folderSize.totalDiskSpaceUsed) / Double(folderSize.totalDiskSpace) * 100
                        Text("\(Int(volumePercentage))%")
                            .font(.system(size: 12))
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 12)
                                .cornerRadius(6)
                            
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(folderSize.totalDiskSpaceUsed) / CGFloat(folderSize.totalDiskSpace), height: 12)
                                .cornerRadius(6)
                        }
                    }
                    .frame(height: 12)
                }
                
                // This folder's usage bar
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("This Folder")
                            .font(.system(size: 12))
                        Spacer()
                        Text("\(Int(folderSize.sizePercentage))%")
                            .font(.system(size: 12))
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 12)
                                .cornerRadius(6)
                            
                            Rectangle()
                                .fill(Color(folderSize.colorCode))
                                .frame(width: geometry.size.width * CGFloat(folderSize.sizePercentage) / 100, height: 12)
                                .cornerRadius(6)
                        }
                    }
                    .frame(height: 12)
                }
            }
            
            Spacer()
        }
        .padding()
    }
} 