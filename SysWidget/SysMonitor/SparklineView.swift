import SwiftUI

struct SparklineView: View {
    let dataPoints: [TimeSeriesDataPoint]
    let lineColor: Color
    let fillColor: Color
    let showFill: Bool
    let lineWidth: CGFloat
    let showDots: Bool
    let showMinMaxLabels: Bool
    
    init(
        dataPoints: [TimeSeriesDataPoint],
        lineColor: Color = .blue,
        fillColor: Color = .blue.opacity(0.2),
        showFill: Bool = true,
        lineWidth: CGFloat = 1.5,
        showDots: Bool = false,
        showMinMaxLabels: Bool = false
    ) {
        self.dataPoints = dataPoints
        self.lineColor = lineColor
        self.fillColor = fillColor
        self.showFill = showFill
        self.lineWidth = lineWidth
        self.showDots = showDots
        self.showMinMaxLabels = showMinMaxLabels
    }
    
    // Get min value from dataPoints
    private var minValue: Double {
        dataPoints.min { $0.value < $1.value }?.value ?? 0
    }
    
    // Get max value from dataPoints
    private var maxValue: Double {
        dataPoints.max { $0.value < $1.value }?.value ?? 1
    }
    
    // Format value for label
    private func formatValue(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "%.1f MB", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "%.1f KB", value / 1_000)
        } else {
            return String(format: "%.0f", value)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            if !dataPoints.isEmpty {
                ZStack {
                    // Min/Max labels if enabled
                    if showMinMaxLabels {
                        VStack {
                            HStack {
                                Text(formatValue(maxValue))
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 2)
                                Spacer()
                            }
                            
                            Spacer()
                            
                            HStack {
                                Text(formatValue(minValue))
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 2)
                                Spacer()
                            }
                        }
                    }
                    
                    // Fill area under the line
                    if showFill {
                        SparklineFillShape(dataPoints: normalizedDataPoints(size: geometry.size))
                            .fill(fillColor)
                    }
                    
                    // Line
                    SparklineShape(dataPoints: normalizedDataPoints(size: geometry.size))
                        .stroke(lineColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    
                    // Data points (optional)
                    if showDots {
                        ForEach(0..<dataPoints.count, id: \.self) { i in
                            let point = normalizedDataPoints(size: geometry.size)[i]
                            Circle()
                                .fill(lineColor)
                                .frame(width: 4, height: 4)
                                .position(x: point.x, y: point.y)
                        }
                    }
                }
            } else {
                // Show an empty state if no data
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geometry.size.height * 0.5))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height * 0.5))
                }
                .stroke(lineColor.opacity(0.3), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round, dash: [5, 5]))
            }
        }
    }
    
    // Convert data points to normalized CGPoints for drawing
    private func normalizedDataPoints(size: CGSize) -> [CGPoint] {
        guard !dataPoints.isEmpty, let minTime = dataPoints.first?.timestamp.timeIntervalSince1970 else {
            return []
        }
        
        let maxTime = dataPoints.last?.timestamp.timeIntervalSince1970 ?? minTime
        let timeRange = maxTime - minTime
        
        // Calculate min and max values
        var minValue = dataPoints.min { $0.value < $1.value }?.value ?? 0
        var maxValue = dataPoints.max { $0.value < $1.value }?.value ?? 1
        
        // Ensure we have a valid range
        if minValue == maxValue {
            minValue = max(0, minValue - 1)
            maxValue = maxValue + 1
        }
        
        let valueRange = maxValue - minValue
        
        return dataPoints.map { point in
            let xPosition: CGFloat
            if timeRange > 0 {
                let normalizedX = (point.timestamp.timeIntervalSince1970 - minTime) / timeRange
                xPosition = CGFloat(normalizedX) * size.width
            } else {
                xPosition = 0
            }
            
            let normalizedY = 1.0 - (point.value - minValue) / valueRange
            let yPosition = CGFloat(normalizedY) * size.height
            
            return CGPoint(x: xPosition, y: yPosition)
        }
    }
}

// Shape for drawing the sparkline
struct SparklineShape: Shape {
    let dataPoints: [CGPoint]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard !dataPoints.isEmpty else {
            return path
        }
        
        // Start at the first point
        path.move(to: dataPoints[0])
        
        // Connect the dots
        for i in 1..<dataPoints.count {
            path.addLine(to: dataPoints[i])
        }
        
        return path
    }
}

// Shape for filling the area under the sparkline
struct SparklineFillShape: Shape {
    let dataPoints: [CGPoint]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard !dataPoints.isEmpty else {
            return path
        }
        
        // Start at the bottom left
        path.move(to: CGPoint(x: dataPoints[0].x, y: rect.height))
        
        // Go to the first point
        path.addLine(to: dataPoints[0])
        
        // Connect all the points
        for i in 1..<dataPoints.count {
            path.addLine(to: dataPoints[i])
        }
        
        // Go to the bottom right
        path.addLine(to: CGPoint(x: dataPoints[dataPoints.count - 1].x, y: rect.height))
        
        // Close the path
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    VStack(spacing: 20) {
        // Generate sample data for preview
        SparklineView(
            dataPoints: (0..<20).map { i in
                TimeSeriesDataPoint(
                    timestamp: Date().addingTimeInterval(Double(-i * 60)),
                    value: Double.random(in: 20...80)
                )
            },
            lineColor: .blue,
            fillColor: .blue.opacity(0.2)
        )
        .frame(height: 50)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        
        SparklineView(
            dataPoints: (0..<20).map { i in
                TimeSeriesDataPoint(
                    timestamp: Date().addingTimeInterval(Double(-i * 60)),
                    value: Double.random(in: 0...1024*1024)
                )
            },
            lineColor: .green,
            fillColor: .green.opacity(0.2)
        )
        .frame(height: 50)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    .padding()
} 