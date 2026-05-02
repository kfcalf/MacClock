import SwiftUI
import Combine

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
