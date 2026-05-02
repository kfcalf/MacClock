import SwiftUI
import MapKit
import Combine

/// World map view with satellite imagery
struct WorldMapView: NSViewRepresentable {
    let cities: [City]
    let currentTime: Date
    var centerOnCity: City?
    var shouldResetZoom: Bool
    var isGoogleMapMode: Bool
    
    func makeNSView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = .satelliteFlyover
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        
        // Set initial region to show the whole world
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 140, longitudeDelta: 360)
        )
        mapView.setRegion(region, animated: false)
        
        // Add initial annotations
        for city in cities {
            let annotation = CityAnnotation(city: city)
            mapView.addAnnotation(annotation)
        }
        
        // Store mapView reference and start refresh timer
        context.coordinator.mapViewRef = mapView
        context.coordinator.startRefreshTimer()
        
        return mapView
    }
    
    func updateNSView(_ mapView: MKMapView, context: Context) {
        // Only update annotations if cities list changed
        let currentCityIds = Set(cities.map { $0.id })
        let existingAnnotations = mapView.annotations.compactMap { $0 as? CityAnnotation }
        let existingCityIds = Set(existingAnnotations.map { $0.city.id })
        
        // Add new cities or update existing ones
        if currentCityIds != existingCityIds {
            mapView.removeAnnotations(mapView.annotations)
            for city in cities {
                let annotation = CityAnnotation(city: city)
                mapView.addAnnotation(annotation)
            }
        }
        
        // Store cities reference for refresh timer
        context.coordinator.cities = cities
        
        // Reset zoom to show entire globe (keep current center, just zoom out)
        if shouldResetZoom {
            let currentCenter = mapView.centerCoordinate
            let region = MKCoordinateRegion(
                center: currentCenter,
                span: MKCoordinateSpan(latitudeDelta: 140, longitudeDelta: 180)
            )
            mapView.setRegion(region, animated: true)
            context.coordinator.lastCenteredCityId = nil
            // Reset zoom handled, update google map mode below
        }
        
        // Handle Google Map Mode toggle
        context.coordinator.updateGoogleMapMode(isGoogleMapMode)
        
        // Center on selected city if changed
        if let city = centerOnCity, city.id != context.coordinator.lastCenteredCityId {
            context.coordinator.lastCenteredCityId = city.id
            
            let region = MKCoordinateRegion(
                center: city.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 60, longitudeDelta: 80)
            )
            mapView.setRegion(region, animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: WorldMapView
        var lastCenteredCityId: UUID?
        weak var mapViewRef: MKMapView?
        var cities: [City] = []
        var isGoogleMapMode = false
        var googleMapOverlay: MKTileOverlay?
        private var refreshTimer: AnyCancellable?
        
        init(_ parent: WorldMapView) {
            self.parent = parent
        }
        
        deinit {
            refreshTimer?.cancel()
        }
        
        /// Start a timer to refresh annotation views synced with the minute change
        func startRefreshTimer() {
            // Calculate seconds until next minute (when seconds = 0)
            let now = Date()
            let calendar = Calendar.current
            let seconds = calendar.component(.second, from: now)
            let secondsUntilNextMinute = Double(60 - seconds)
            
            // First, wait until the next minute boundary, then refresh and start the 60-second timer
            DispatchQueue.main.asyncAfter(deadline: .now() + secondsUntilNextMinute) { [weak self] in
                self?.refreshAnnotationViews()
                
                // Then set up the recurring 60-second timer
                self?.refreshTimer = Timer.publish(every: 60, on: .main, in: .common)
                    .autoconnect()
                    .sink { [weak self] _ in
                        self?.refreshAnnotationViews()
                    }
            }
        }
        
        /// Refresh all annotation views with smooth animation
        private func refreshAnnotationViews() {
            guard let mapView = mapViewRef else { return }
            
            for annotation in mapView.annotations {
                guard let cityAnnotation = annotation as? CityAnnotation,
                      let annotationView = mapView.view(for: cityAnnotation) else { continue }
                
                // Find the hosting view containing the CityMarkerView
                if let hostingView = annotationView.subviews.first as? NSHostingView<CityMarkerView> {
                    // Create new hosting view with updated time
                    let newHostingView = NSHostingView(rootView: CityMarkerView(city: cityAnnotation.city))
                    let size = newHostingView.fittingSize
                    newHostingView.frame = hostingView.frame
                    newHostingView.alphaValue = 0
                    
                    annotationView.addSubview(newHostingView)
                    
                    // Smooth crossfade animation
                    NSAnimationContext.runAnimationGroup({ context in
                        context.duration = 0.3
                        context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                        hostingView.animator().alphaValue = 0
                        newHostingView.animator().alphaValue = 1
                    }, completionHandler: {
                        hostingView.removeFromSuperview()
                    })
                }
            }
        }
        
        func updateGoogleMapMode(_ isEnabled: Bool) {
            guard isEnabled != isGoogleMapMode, let mapView = mapViewRef else { return }
            isGoogleMapMode = isEnabled
            
            if isEnabled {
                let overlay = CachedGoogleMapOverlay.shared
                overlay.mapView = mapView
                self.googleMapOverlay = overlay
                mapView.addOverlay(overlay, level: .aboveRoads)
            } else {
                if let overlay = googleMapOverlay {
                    mapView.removeOverlay(overlay)
                    self.googleMapOverlay = nil
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tileOverlay = overlay as? MKTileOverlay {
                let renderer = MKTileOverlayRenderer(tileOverlay: tileOverlay)
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let cityAnnotation = annotation as? CityAnnotation else { return nil }
            
            let identifier = "CityAnnotation_\(cityAnnotation.city.id)"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: cityAnnotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
                
                // Create custom marker view
                let hostingView = NSHostingView(rootView: CityMarkerView(city: cityAnnotation.city))
                let size = hostingView.fittingSize
                hostingView.frame = CGRect(origin: .zero, size: size)
                
                annotationView?.addSubview(hostingView)
                annotationView?.frame.size = size
                
                // Position so the bottom anchor dot points to the coordinate
                // The anchor dot is at the bottom center of the view
                annotationView?.centerOffset = CGPoint(x: 0, y: -size.height/2)
            } else {
                annotationView?.annotation = cityAnnotation
                // Update the hosting view with new time
                if let hostingView = annotationView?.subviews.first as? NSHostingView<CityMarkerView> {
                    hostingView.rootView = CityMarkerView(city: cityAnnotation.city)
                }
            }
            
            return annotationView
        }
    }
}

// MARK: - City Annotation666

class CityAnnotation: NSObject, MKAnnotation {
    let city: City
    
    var coordinate: CLLocationCoordinate2D {
        city.coordinate
    }
    
    var title: String? {
        city.localizedName
    }
    
    var subtitle: String? {
        city.formattedTime()
    }
    
    init(city: City) {
        self.city = city
    }
}

// MARK: - City Marker View

struct CityMarkerView: View {
    let city: City
    
    var body: some View {
        VStack(spacing: 2) {
            // Label above the anchor point
            VStack(spacing: 1) {
                Text(city.localizedName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(city.formattedTime(style: .short))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.black.opacity(0.7))
            )
            
            // Anchor dot at the exact coordinate
            Circle()
                .fill(Color.orange)
                .frame(width: 6, height: 6)
        }
    }
}

#Preview {
    WorldMapView(cities: City.defaultCities, currentTime: Date(), centerOnCity: nil, shouldResetZoom: false, isGoogleMapMode: false)
        .frame(width: 800, height: 400)
}

// MARK: - Optimized Google Satellite Overlay

class CachedGoogleMapOverlay: MKTileOverlay {
    /// Shared singleton to reuse URLSession and caches across toggle cycles
    static let shared = CachedGoogleMapOverlay()
    
    weak var mapView: MKMapView?
    
    private let session: URLSession
    private let memoryCache = NSCache<NSString, NSData>()
    private let diskCacheDir: URL
    
    /// Dedicated concurrent queue for disk reads
    private let diskReadQueue = DispatchQueue(label: "GoogleTileDiskRead", qos: .userInitiated, attributes: .concurrent)
    /// Dedicated serial queue for disk writes to prevent stalling reads
    private let diskWriteQueue = DispatchQueue(label: "GoogleTileDiskWrite", qos: .background)
    
    override init(urlTemplate: String? = nil) {
        // Persistent disk cache directory
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("GoogleMapTiles", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        self.diskCacheDir = cacheDir
        
        // Use ephemeral configuration to disable default URLCache.
        // This avoids "double caching" overhead since we manage disk cache manually.
        let config = URLSessionConfiguration.ephemeral
        config.httpMaximumConnectionsPerHost = 10 // Reduced from 40 to avoid Google rate-limiting
        config.timeoutIntervalForRequest = 8
        config.timeoutIntervalForResource = 20
        config.waitsForConnectivity = false
        config.httpShouldUsePipelining = true
        self.session = URLSession(configuration: config)
        
        // Configure memory cache limits
        memoryCache.countLimit = 500
        memoryCache.totalCostLimit = 150 * 1024 * 1024 // 150MB
        
        super.init(urlTemplate: urlTemplate)
        self.canReplaceMapContent = true
        self.maximumZ = 20
        self.tileSize = CGSize(width: 256, height: 256)
    }
    
    /// Disk cache file path for a tile
    @inline(__always)
    private func diskPath(forKey key: String) -> URL {
        diskCacheDir.appendingPathComponent(key)
    }
    
    override func url(forTilePath path: MKTileOverlayPath) -> URL {
        let subdomains = ["mt0", "mt1", "mt2", "mt3"]
        let subdomain = subdomains[Int(abs(path.x + path.y) % 4)]
        let scale = path.contentScaleFactor > 1.0 ? 2 : 1
        let urlString = "https://\(subdomain).google.com/vt/lyrs=s&x=\(path.x)&y=\(path.y)&z=\(path.z)&scale=\(scale)"
        return URL(string: urlString)!
    }
    
    /// Fast cache key without percent-encoding overhead
    @inline(__always)
    private func cacheKey(for path: MKTileOverlayPath) -> String {
        "\(path.z)_\(path.x)_\(path.y)_\(path.contentScaleFactor > 1.0 ? 2 : 1)"
    }
    
    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        let key = cacheKey(for: path)
        let nsKey = key as NSString
        
        // L1: Memory cache — instant
        if let cachedData = memoryCache.object(forKey: nsKey) {
            result(cachedData as Data, nil)
            return
        }
        
        // L2: Disk cache — non-blocking concurrent read
        let filePath = diskPath(forKey: key)
        diskReadQueue.async { [weak self] in
            // Direct read without fileExists check (saves 1 disk I/O operation)
            if let diskData = try? Data(contentsOf: filePath) {
                self?.memoryCache.setObject(diskData as NSData, forKey: nsKey, cost: diskData.count)
                result(diskData, nil)
                return
            }
            
            // L3: Network fetch
            self?.fetchTileFromNetwork(url: self!.url(forTilePath: path), nsKey: nsKey, filePath: filePath, path: path, result: result)
        }
    }
    
    /// Fetch tile from network with priority adjustment based on visibility
    private func fetchTileFromNetwork(url: URL, nsKey: NSString, filePath: URL, path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let data = data, error == nil {
                // Save to memory cache
                self.memoryCache.setObject(data as NSData, forKey: nsKey, cost: data.count)
                
                // Save to disk asynchronously on a separate background serial queue.
                self.diskWriteQueue.async {
                    try? data.write(to: filePath, options: .atomic)
                }
            }
            result(data, error)
        }
        
        // Dynamically adjust task priority based on whether the tile is currently visible
        DispatchQueue.main.async { [weak self, weak task] in
            guard let self = self, let task = task, task.state == .running || task.state == .suspended else { return }
            if let mapView = self.mapView {
                let tileRect = path.boundingMapRect()
                if mapView.visibleMapRect.intersects(tileRect) {
                    task.priority = URLSessionTask.highPriority
                } else {
                    task.priority = URLSessionTask.lowPriority
                }
            } else {
                task.priority = URLSessionTask.highPriority
            }
        }
        
        task.resume()
    }
    
}

extension MKTileOverlayPath {
    /// Calculates the MKMapRect for this tile to determine if it is visible on the map
    func boundingMapRect() -> MKMapRect {
        let zoom = Double(self.z)
        let n = pow(2.0, zoom)
        
        let width = MKMapSize.world.width / n
        let height = MKMapSize.world.height / n
        
        let mapX = Double(self.x) * width
        let mapY = Double(self.y) * height
        
        return MKMapRect(x: mapX, y: mapY, width: width, height: height)
    }
}
