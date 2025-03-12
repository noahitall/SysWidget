import SwiftUI
import WidgetKit

struct ProgressBarView: View {
    var value: Double
    var color: Color
    var showText: Bool = true
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(height: 6)
                    .opacity(0.3)
                    .foregroundColor(color)
                    .cornerRadius(3)
                
                Rectangle()
                    .frame(width: min(CGFloat(value) / 100.0 * UIScreen.main.bounds.width, UIScreen.main.bounds.width), height: 6)
                    .foregroundColor(color)
                    .cornerRadius(3)
            }
            
            if showText {
                HStack {
                    Text("\(Int(value))%")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
    }
}

struct MetricView: View {
    var icon: String
    var title: String
    var value: String
    var color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct NetworkView: View {
    var upload: String
    var download: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.blue)
                    Text(upload)
                        .font(.system(size: 12, weight: .medium))
                }
                
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.green)
                    Text(download)
                        .font(.system(size: 12, weight: .medium))
                }
            }
            
            Spacer()
        }
    }
}

struct TemperatureView: View {
    var temperature: Double
    
    var color: Color {
        if temperature < 50 {
            return .green
        } else if temperature < 70 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: "thermometer")
                .foregroundColor(color)
            
            Text("\(Int(temperature))°C")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            
            Spacer()
        }
    }
} 