import SwiftUI
import Combine
import CoreLocation

// MARK: - Coordinate Formatter

struct CoordinateFormatter {
    static func formatDMS(latitude: Double, longitude: Double) -> String {
        let latDirection = latitude >= 0 ? "北纬" : "南纬"
        let lonDirection = longitude >= 0 ? "东经" : "西经"
        
        let absLat = abs(latitude)
        let latDeg = Int(absLat)
        let latMinDec = (absLat - Double(latDeg)) * 60
        let latMin = Int(latMinDec)
        var latSec = Int(round((latMinDec - Double(latMin)) * 60))
        
        var finalLatDeg = latDeg
        var finalLatMin = latMin
        if latSec >= 60 {
            latSec = 0
            finalLatMin += 1
            if finalLatMin >= 60 {
                finalLatMin = 0
                finalLatDeg += 1
            }
        }
        
        let absLon = abs(longitude)
        let lonDeg = Int(absLon)
        let lonMinDec = (absLon - Double(lonDeg)) * 60
        let lonMin = Int(lonMinDec)
        var lonSec = Int(round((lonMinDec - Double(lonMin)) * 60))
        
        var finalLonDeg = lonDeg
        var finalLonMin = lonMin
        if lonSec >= 60 {
            lonSec = 0
            finalLonMin += 1
            if finalLonMin >= 60 {
                finalLonMin = 0
                finalLonDeg += 1
            }
        }
        
        return String(format: "%@ %d°%02d′%02d″  %@ %d°%02d′%02d″",
                      latDirection, finalLatDeg, finalLatMin, latSec,
                      lonDirection, finalLonDeg, finalLonMin, lonSec)
    }
    
    static func formatDecimal(latitude: Double, longitude: Double) -> String {
        let latDirection = latitude >= 0 ? "北纬" : "南纬"
        let lonDirection = longitude >= 0 ? "东经" : "西经"
        return String(format: "%@ %.4f°  %@ %.4f°", latDirection, abs(latitude), lonDirection, abs(longitude))
    }
}

// MARK: - Map Coordinate State

class MapCoordinateState: ObservableObject {
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var isHovering: Bool = false
    @Published var formatStyle: CoordinateFormatStyle = .dms
    
    enum CoordinateFormatStyle: Int {
        case dms = 0
        case decimal = 1
        case full = 2
    }
    
    func update(coordinate: CLLocationCoordinate2D?, isHovering: Bool) {
        if self.isHovering != isHovering {
            self.isHovering = isHovering
        }
        if coordinate == nil {
            if self.coordinate != nil {
                self.coordinate = nil
            }
            return
        }
        guard let newCoord = coordinate else { return }
        if let oldCoord = self.coordinate {
            if abs(oldCoord.latitude - newCoord.latitude) > 0.000005 ||
               abs(oldCoord.longitude - newCoord.longitude) > 0.000005 {
                self.coordinate = newCoord
            }
        } else {
            self.coordinate = newCoord
        }
    }
    
    var formattedText: String {
        guard let coord = coordinate else { return "" }
        switch formatStyle {
        case .dms:
            return CoordinateFormatter.formatDMS(latitude: coord.latitude, longitude: coord.longitude)
        case .decimal:
            return CoordinateFormatter.formatDecimal(latitude: coord.latitude, longitude: coord.longitude)
        case .full:
            let dms = CoordinateFormatter.formatDMS(latitude: coord.latitude, longitude: coord.longitude)
            let latDir = coord.latitude >= 0 ? "N" : "S"
            let lonDir = coord.longitude >= 0 ? "E" : "W"
            return String(format: "%@ (%.4f° %@, %.4f° %@)", dms, abs(coord.latitude), latDir, abs(coord.longitude), lonDir)
        }
    }
    
    var currentString: String {
        formattedText
    }
    
    var dmsString: String {
        guard let coord = coordinate else { return "" }
        return CoordinateFormatter.formatDMS(latitude: coord.latitude, longitude: coord.longitude)
    }
    
    var decimalString: String {
        guard let coord = coordinate else { return "" }
        return CoordinateFormatter.formatDecimal(latitude: coord.latitude, longitude: coord.longitude)
    }
    
    var standardPairString: String {
        guard let coord = coordinate else { return "" }
        return String(format: "%.6f, %.6f", coord.latitude, coord.longitude)
    }
    
    func cycleFormat() {
        switch formatStyle {
        case .dms:
            formatStyle = .decimal
        case .decimal:
            formatStyle = .full
        case .full:
            formatStyle = .dms
        }
    }
}

/// ViewModel for managing world clock state
class WorldClockViewModel: ObservableObject {
    @Published var cities: [City] = []
    @Published var selectedCityId: UUID?
    @Published var showingCityManager = false
    @Published var currentTime = Date()
    @Published var panelOpacity: Double = 0.8 {
        didSet {
            UserDefaults.standard.set(panelOpacity, forKey: "WorldClockPanelOpacity")
        }
    }
    @Published var shouldResetMapZoom = false
    @Published var isGoogleMapMode = false {
        didSet {
            UserDefaults.standard.set(isGoogleMapMode, forKey: "WorldClockIsGoogleMapMode")
        }
    }
    @Published var isCrosshairEnabled = false {
        didSet {
            UserDefaults.standard.set(isCrosshairEnabled, forKey: "WorldClockIsCrosshairEnabled")
            if !isCrosshairEnabled {
                coordinateState.update(coordinate: nil, isHovering: false)
            }
        }
    }
    let coordinateState = MapCoordinateState()
    @Published var isPanelVisible = true
    @Published var draggingCityId: UUID?
    @Published var scrollOffset: CGFloat = 0
    @Published var isScrollbarDragging = false
    @Published var scrollProgress: CGFloat = 0
    
    private var timer: AnyCancellable?
    private let userDefaultsKey = "WorldClockCities"
    
    init() {
        // Load saved opacity
        let savedOpacity = UserDefaults.standard.double(forKey: "WorldClockPanelOpacity")
        if savedOpacity > 0 {
            panelOpacity = savedOpacity
        }
        
        // Load saved map mode
        isGoogleMapMode = UserDefaults.standard.bool(forKey: "WorldClockIsGoogleMapMode")
        
        // Load saved crosshair mode
        isCrosshairEnabled = UserDefaults.standard.bool(forKey: "WorldClockIsCrosshairEnabled")
        
        loadCities()
        startTimer()
    }
    
    deinit {
        timer?.cancel()
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.currentTime = date
            }
    }
    
    // MARK: - City Management
    
    func addCity(_ city: City) {
        // Avoid duplicates
        guard !cities.contains(where: { $0.name == city.name }) else { return }
        cities.append(city)
        saveCities()
    }
    
    func removeCity(_ city: City) {
        cities.removeAll { $0.id == city.id }
        saveCities()
    }
    
    func removeCity(at offsets: IndexSet) {
        cities.remove(atOffsets: offsets)
        saveCities()
    }
    
    func moveCity(from source: IndexSet, to destination: Int) {
        cities.move(fromOffsets: source, toOffset: destination)
        saveCities()
    }
    
    // MARK: - Persistence
    
    func saveCities() {
        if let encoded = try? JSONEncoder().encode(cities) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadCities() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([City].self, from: data) {
            cities = decoded
        } else {
            // Load default cities on first launch
            cities = City.defaultCities
            saveCities()
        }
    }
    
    // MARK: - Helpers
    
    /// Select a city to center the map on
    func selectCity(_ city: City) {
        selectedCityId = city.id
    }
    
    /// Get the currently selected city
    var selectedCity: City? {
        guard let id = selectedCityId else { return nil }
        return cities.first { $0.id == id }
    }
    
    /// Reset map to show entire globe
    func resetMapZoom() {
        selectedCityId = nil
        shouldResetMapZoom = true
        // Reset flag after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldResetMapZoom = false
        }
    }
    
    func cityClockStyle(for city: City) -> ClockStyle {
        // Determine if it's daytime in this city
        guard let tz = city.timeZone else { return .light }
        
        let sunrise = SunCalculator.sunriseTime(for: city.coordinate, on: currentTime, timeZone: tz)
        let sunset = SunCalculator.sunsetTime(for: city.coordinate, on: currentTime, timeZone: tz)
        
        guard let rise = sunrise, let set = sunset else { return .light }
        
        var calendar = Calendar.current
        calendar.timeZone = tz
        
        let now = calendar.dateComponents([.hour, .minute], from: currentTime)
        let riseComponents = calendar.dateComponents([.hour, .minute], from: rise)
        let setComponents = calendar.dateComponents([.hour, .minute], from: set)
        
        let nowMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        let riseMinutes = (riseComponents.hour ?? 6) * 60 + (riseComponents.minute ?? 0)
        let setMinutes = (setComponents.hour ?? 18) * 60 + (setComponents.minute ?? 0)
        
        if nowMinutes >= riseMinutes && nowMinutes < setMinutes {
            return .light
        } else {
            return .dark
        }
    }
}

enum ClockStyle {
    case light
    case dark
}
