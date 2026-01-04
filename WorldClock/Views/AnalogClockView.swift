import SwiftUI

/// Analog clock view with hour, minute, and second hands
struct AnalogClockView: View {
    let hour: Int
    let minute: Int
    let second: Int
    let style: ClockStyle
    let size: CGFloat
    
    init(hour: Int, minute: Int, second: Int, style: ClockStyle = .light, size: CGFloat = 120) {
        self.hour = hour
        self.minute = minute
        self.second = second
        self.style = style
        self.size = size
    }
    
    private var backgroundColor: Color {
        style == .dark ? Color(white: 0.15) : .white
    }
    
    private var dialColor: Color {
        style == .dark ? .white : .black
    }
    
    private var accentColor: Color {
        .orange
    }
    
    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let radius = min(canvasSize.width, canvasSize.height) / 2 - 4
            
            // Draw clock face background
            let backgroundPath = Path(ellipseIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            ))
            context.fill(backgroundPath, with: .color(backgroundColor))
            context.stroke(backgroundPath, with: .color(dialColor.opacity(0.3)), lineWidth: 2)
            
            // Draw hour markers and numbers
            for i in 1...12 {
                let angle = CGFloat(i) * 30.0 - 90.0
                let radians = angle * .pi / 180.0
                
                // Calculate positions
                let markerInnerRadius = radius * 0.85
                let markerOuterRadius = radius * 0.95
                let numberRadius = radius * 0.72
                
                let innerPoint = CGPoint(
                    x: center.x + markerInnerRadius * CoreGraphics.cos(radians),
                    y: center.y + markerInnerRadius * CoreGraphics.sin(radians)
                )
                let outerPoint = CGPoint(
                    x: center.x + markerOuterRadius * CoreGraphics.cos(radians),
                    y: center.y + markerOuterRadius * CoreGraphics.sin(radians)
                )
                
                // Draw marker
                var markerPath = Path()
                markerPath.move(to: innerPoint)
                markerPath.addLine(to: outerPoint)
                context.stroke(markerPath, with: .color(dialColor), lineWidth: i % 3 == 0 ? 2 : 1)
                
                // Draw number
                let numberPoint = CGPoint(
                    x: center.x + numberRadius * CoreGraphics.cos(radians),
                    y: center.y + numberRadius * CoreGraphics.sin(radians)
                )
                
                let text = Text("\(i)")
                    .font(.system(size: radius * 0.18, weight: .medium, design: .rounded))
                    .foregroundColor(dialColor)
                
                context.draw(text, at: numberPoint)
            }
            
            // Draw minute markers
            for i in 0..<60 {
                if i % 5 != 0 { // Skip hour positions
                    let angle = CGFloat(i) * 6.0 - 90.0
                    let radians = angle * .pi / 180.0
                    
                    let innerRadius = radius * 0.92
                    let outerRadius = radius * 0.95
                    
                    let innerPoint = CGPoint(
                        x: center.x + innerRadius * CoreGraphics.cos(radians),
                        y: center.y + innerRadius * CoreGraphics.sin(radians)
                    )
                    let outerPoint = CGPoint(
                        x: center.x + outerRadius * CoreGraphics.cos(radians),
                        y: center.y + outerRadius * CoreGraphics.sin(radians)
                    )
                    
                    var path = Path()
                    path.move(to: innerPoint)
                    path.addLine(to: outerPoint)
                    context.stroke(path, with: .color(dialColor.opacity(0.4)), lineWidth: 0.5)
                }
            }
            
            // Calculate hand angles
            let secondAngle = Double(second) * 6.0 - 90.0
            let minuteAngle = Double(minute) * 6.0 + Double(second) * 0.1 - 90.0
            let hourAngle = Double(hour % 12) * 30.0 + Double(minute) * 0.5 - 90.0
            
            // Draw hour hand
            drawHand(
                context: context,
                center: center,
                angle: hourAngle,
                length: radius * 0.5,
                width: 4,
                color: dialColor
            )
            
            // Draw minute hand
            drawHand(
                context: context,
                center: center,
                angle: minuteAngle,
                length: radius * 0.7,
                width: 3,
                color: dialColor
            )
            
            // Draw second hand
            drawHand(
                context: context,
                center: center,
                angle: secondAngle,
                length: radius * 0.8,
                width: 1.5,
                color: accentColor,
                hasTail: true,
                tailLength: radius * 0.15
            )
            
            // Draw center dot
            let dotRadius: CGFloat = 4
            let dotPath = Path(ellipseIn: CGRect(
                x: center.x - dotRadius,
                y: center.y - dotRadius,
                width: dotRadius * 2,
                height: dotRadius * 2
            ))
            context.fill(dotPath, with: .color(accentColor))
        }
        .frame(width: size, height: size)
    }
    
    private func drawHand(
        context: GraphicsContext,
        center: CGPoint,
        angle: Double,
        length: CGFloat,
        width: CGFloat,
        color: Color,
        hasTail: Bool = false,
        tailLength: CGFloat = 0
    ) {
        let radians = CGFloat(angle * .pi / 180.0)
        
        var path = Path()
        
        if hasTail {
            let tailRadians = CGFloat((angle + 180) * .pi / 180.0)
            let tailPoint = CGPoint(
                x: center.x + tailLength * CoreGraphics.cos(tailRadians),
                y: center.y + tailLength * CoreGraphics.sin(tailRadians)
            )
            path.move(to: tailPoint)
        } else {
            path.move(to: center)
        }
        
        let endPoint = CGPoint(
            x: center.x + length * CoreGraphics.cos(radians),
            y: center.y + length * CoreGraphics.sin(radians)
        )
        
        path.addLine(to: endPoint)
        
        context.stroke(
            path,
            with: .color(color),
            style: StrokeStyle(lineWidth: width, lineCap: .round)
        )
    }
}

#Preview {
    HStack(spacing: 20) {
        AnalogClockView(hour: 10, minute: 10, second: 30, style: .light, size: 150)
        AnalogClockView(hour: 10, minute: 10, second: 30, style: .dark, size: 150)
    }
    .padding()
    .background(Color.gray.opacity(0.3))
}
