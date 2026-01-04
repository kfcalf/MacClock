import SwiftUI

/// Card displaying city clock with analog clock and info
struct CityClockCard: View {
    let city: City
    let style: ClockStyle
    let currentTime: Date
    var isSelected: Bool = false
    var onTap: (() -> Void)?
    var onDelete: (() -> Void)?
    
    @State private var isHovering = false
    
    private var timeComponents: (hour: Int, minute: Int, second: Int) {
        city.timeComponents()
    }
    
    private var sunriseString: String {
        guard let tz = city.timeZone else { return "--:--" }
        let sunrise = SunCalculator.sunriseTime(for: city.coordinate, on: currentTime, timeZone: tz)
        return SunCalculator.formatSunTime(sunrise, timeZone: tz)
    }
    
    private var sunsetString: String {
        guard let tz = city.timeZone else { return "--:--" }
        let sunset = SunCalculator.sunsetTime(for: city.coordinate, on: currentTime, timeZone: tz)
        return SunCalculator.formatSunTime(sunset, timeZone: tz)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Analog clock
            ZStack(alignment: .topTrailing) {
                AnalogClockView(
                    hour: timeComponents.hour,
                    minute: timeComponents.minute,
                    second: timeComponents.second,
                    style: style,
                    size: 120
                )
                
                // Delete button on hover
                if isHovering, let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.white, .gray.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .offset(x: 8, y: -8)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            // City info
            VStack(spacing: 4) {
                Text(city.localizedName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(city.formattedTime(style: .short))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                
                Text(city.timeDifferenceString())
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
                
                HStack(spacing: 8) {
                    Label(sunriseString, systemImage: "sunrise.fill")
                    Label(sunsetString, systemImage: "sunset.fill")
                }
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Color.orange : Color.white.opacity(0.1), lineWidth: isSelected ? 2.5 : 1)
        )
        .shadow(color: isSelected ? Color.orange.opacity(0.4) : Color.clear, radius: 8, x: 0, y: 0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            onTap?()
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    HStack(spacing: 16) {
        CityClockCard(
            city: City.presets[0],
            style: .light,
            currentTime: Date(),
            isSelected: true
        ) {
            print("Tapped")
        } onDelete: {
            print("Delete")
        }
        CityClockCard(
            city: City.presets[13],
            style: .dark,
            currentTime: Date(),
            isSelected: false
        )
    }
    .padding(40)
    .background(Color.black)
}
