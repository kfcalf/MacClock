import SwiftUI
import MapKit
import Combine

/// World map view with satellite imagery
struct WorldMapView: NSViewRepresentable {
    let cities: [City]
    let currentTime: Date
    var centerOnCity: City?
    var shouldResetZoom: Bool
    
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
            return
        }
        
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
    WorldMapView(cities: City.defaultCities, currentTime: Date(), centerOnCity: nil, shouldResetZoom: false)
        .frame(width: 800, height: 400)
}
