import Foundation
import CoreLocation

/// Calculator for sun position and day/night terminator
struct SunCalculator {
    
    /// Calculate the subsolar point (where the sun is directly overhead)
    /// Returns the latitude and longitude of the subsolar point
    static func subsolarPoint(for date: Date = Date()) -> CLLocationCoordinate2D {
        let calendar = Calendar(identifier: .gregorian)
        var utcCalendar = calendar
        utcCalendar.timeZone = TimeZone(identifier: "UTC")!
        
        // Get day of year
        let dayOfYear = utcCalendar.ordinality(of: .day, in: .year, for: date) ?? 1
        
        // Get time in hours (UTC)
        let components = utcCalendar.dateComponents([.hour, .minute, .second], from: date)
        let hours = Double(components.hour ?? 0)
        let minutes = Double(components.minute ?? 0)
        let seconds = Double(components.second ?? 0)
        let timeInHours = hours + minutes / 60.0 + seconds / 3600.0
        
        // Calculate declination angle (latitude of subsolar point)
        // Using a simplified formula
        let declination = -23.45 * cos(2.0 * .pi * (Double(dayOfYear) + 10) / 365.0)
        
        // Calculate longitude of subsolar point
        // The sun is at longitude 0 at 12:00 UTC, and moves 15 degrees per hour westward
        var longitude = (12.0 - timeInHours) * 15.0
        if longitude > 180 {
            longitude -= 360
        } else if longitude < -180 {
            longitude += 360
        }
        
        return CLLocationCoordinate2D(latitude: declination, longitude: longitude)
    }
    
    /// Generate points along the day/night terminator
    /// Returns an array of coordinates forming the terminator line
    static func terminatorPoints(for date: Date = Date(), pointCount: Int = 180) -> [CLLocationCoordinate2D] {
        let subsolar = subsolarPoint(for: date)
        var points: [CLLocationCoordinate2D] = []
        
        // The terminator is a great circle 90 degrees from the subsolar point
        for i in 0..<pointCount {
            let angle = Double(i) * 360.0 / Double(pointCount)
            let radAngle = angle * .pi / 180.0
            
            // Calculate point on terminator
            let lat = asin(cos(radAngle) * cos(subsolar.latitude * .pi / 180.0))
            var lon = subsolar.longitude + 90.0 + atan2(sin(radAngle), tan(subsolar.latitude * .pi / 180.0)) * 180.0 / .pi
            
            // Normalize longitude
            while lon > 180 { lon -= 360 }
            while lon < -180 { lon += 360 }
            
            points.append(CLLocationCoordinate2D(latitude: lat * 180.0 / .pi, longitude: lon))
        }
        
        return points
    }
    
    /// Generate polygon points for the night region
    /// Returns coordinates that form a closed polygon covering the night side of Earth
    static func nightPolygonPoints(for date: Date = Date()) -> [CLLocationCoordinate2D] {
        let subsolar = subsolarPoint(for: date)
        var points: [CLLocationCoordinate2D] = []
        
        // Generate terminator points
        let terminatorCount = 180
        for i in 0...terminatorCount {
            let angle = Double(i) * 180.0 / Double(terminatorCount)
            let radAngle = angle * .pi / 180.0
            
            let declinationRad = subsolar.latitude * .pi / 180.0
            
            // Calculate latitude on terminator
            let lat = asin(sin(radAngle) * cos(declinationRad)) * 180.0 / .pi
            
            // Calculate longitude offset
            var lonOffset: Double
            if abs(cos(radAngle)) < 0.0001 {
                lonOffset = 0
            } else {
                lonOffset = atan2(cos(radAngle), -tan(declinationRad) * sin(radAngle)) * 180.0 / .pi
            }
            
            var lon = subsolar.longitude + 90.0 + lonOffset
            while lon > 180 { lon -= 360 }
            while lon < -180 { lon += 360 }
            
            points.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        
        // Add corner points to complete the night polygon
        // We need to determine which hemisphere is in darkness
        let nightCenterLon = subsolar.longitude + 180.0 > 180 ? subsolar.longitude - 180.0 : subsolar.longitude + 180.0
        
        // Close the polygon by adding boundary points
        if let lastPoint = points.last {
            points.append(CLLocationCoordinate2D(latitude: -90, longitude: lastPoint.longitude))
            points.append(CLLocationCoordinate2D(latitude: -90, longitude: nightCenterLon))
        }
        if let firstPoint = points.first {
            points.append(CLLocationCoordinate2D(latitude: -90, longitude: firstPoint.longitude))
            points.insert(CLLocationCoordinate2D(latitude: 90, longitude: firstPoint.longitude), at: 0)
        }
        
        return points
    }
    
    /// Calculate sunrise time for a given location and date
    static func sunriseTime(for coordinate: CLLocationCoordinate2D, on date: Date = Date(), timeZone: TimeZone) -> Date? {
        return calculateSunEvent(for: coordinate, on: date, timeZone: timeZone, isSunrise: true)
    }
    
    /// Calculate sunset time for a given location and date
    static func sunsetTime(for coordinate: CLLocationCoordinate2D, on date: Date = Date(), timeZone: TimeZone) -> Date? {
        return calculateSunEvent(for: coordinate, on: date, timeZone: timeZone, isSunrise: false)
    }
    
    private static func calculateSunEvent(for coordinate: CLLocationCoordinate2D, on date: Date, timeZone: TimeZone, isSunrise: Bool) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        
        // Get local date components in the target timezone
        let localComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Calculate day of year using the local date
        guard let localMidnight = calendar.date(from: localComponents),
              let dayOfYear = calendar.ordinality(of: .day, in: .year, for: localMidnight) else {
            return nil
        }
        
        // Calculate fractional year (in radians)
        let isLeapYear = calendar.range(of: .day, in: .year, for: localMidnight)?.count == 366
        let daysInYear = isLeapYear ? 366.0 : 365.0
        let gamma = 2.0 * .pi / daysInYear * (Double(dayOfYear) - 1)
        
        // Equation of time (in minutes) - accounts for Earth's elliptical orbit and axial tilt
        let eqTime = 229.18 * (0.000075 + 0.001868 * cos(gamma) - 0.032077 * sin(gamma)
                                - 0.014615 * cos(2 * gamma) - 0.040849 * sin(2 * gamma))
        
        // Solar declination (in radians)
        let decl = 0.006918 - 0.399912 * cos(gamma) + 0.070257 * sin(gamma)
                   - 0.006758 * cos(2 * gamma) + 0.000907 * sin(2 * gamma)
                   - 0.002697 * cos(3 * gamma) + 0.00148 * sin(3 * gamma)
        
        let latRad = coordinate.latitude * .pi / 180.0
        
        // Calculate hour angle for sunrise/sunset
        // Using -0.833 degrees to account for atmospheric refraction and sun's radius
        let zenith = 90.833 * .pi / 180.0
        let cosHourAngle = (cos(zenith) / (cos(latRad) * cos(decl))) - (tan(latRad) * tan(decl))
        
        // Check if sun rises/sets at this location on this day
        if cosHourAngle > 1 {
            return nil // Polar night - sun never rises
        }
        if cosHourAngle < -1 {
            return nil // Polar day - sun never sets
        }
        
        // Hour angle in degrees
        let hourAngleDeg = acos(cosHourAngle) * 180.0 / .pi
        
        // Calculate sunrise/sunset time in minutes from midnight UTC
        var eventTimeUTC: Double
        if isSunrise {
            eventTimeUTC = 720 - 4 * (coordinate.longitude + hourAngleDeg) - eqTime
        } else {
            eventTimeUTC = 720 - 4 * (coordinate.longitude - hourAngleDeg) - eqTime
        }
        
        // Get the timezone offset for this specific date (handles DST correctly)
        let tzOffset = Double(timeZone.secondsFromGMT(for: localMidnight)) / 60.0
        
        // Convert to local time
        var eventTimeLocal = eventTimeUTC + tzOffset
        
        // Normalize to 0-1440 minutes
        while eventTimeLocal < 0 { eventTimeLocal += 1440 }
        while eventTimeLocal >= 1440 { eventTimeLocal -= 1440 }
        
        // Create date from components
        var resultComponents = localComponents
        resultComponents.hour = Int(eventTimeLocal / 60)
        resultComponents.minute = Int(eventTimeLocal.truncatingRemainder(dividingBy: 60))
        resultComponents.second = 0
        
        return calendar.date(from: resultComponents)
    }
    
    /// Format sunrise/sunset time
    static func formatSunTime(_ date: Date?, timeZone: TimeZone) -> String {
        guard let date = date else { return "--:--" }
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
