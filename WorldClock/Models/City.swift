import Foundation
import CoreLocation

/// Represents a city with timezone information for the world clock
struct City: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var localizedName: String
    var timeZoneIdentifier: String
    var latitude: Double
    var longitude: Double
    
    init(id: UUID = UUID(), name: String, localizedName: String? = nil, timeZoneIdentifier: String, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.localizedName = localizedName ?? name
        self.timeZoneIdentifier = timeZoneIdentifier
        self.latitude = latitude
        self.longitude = longitude
    }
    
    var timeZone: TimeZone? {
        TimeZone(identifier: timeZoneIdentifier)
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// Current time in this city's timezone
    func currentTime() -> Date {
        Date()
    }
    
    /// Formatted time string for this city
    func formattedTime(style: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.timeStyle = style
        formatter.dateStyle = .none
        return formatter.string(from: Date())
    }
    
    /// Hour and minute components for analog clock
    func timeComponents() -> (hour: Int, minute: Int, second: Int) {
        let calendar = Calendar.current
        var cal = calendar
        cal.timeZone = timeZone ?? .current
        let components = cal.dateComponents([.hour, .minute, .second], from: Date())
        return (components.hour ?? 0, components.minute ?? 0, components.second ?? 0)
    }
    
    /// Time difference from local timezone in hours
    func timeDifferenceFromLocal() -> Int {
        guard let cityTZ = timeZone else { return 0 }
        let localOffset = TimeZone.current.secondsFromGMT()
        let cityOffset = cityTZ.secondsFromGMT()
        return (cityOffset - localOffset) / 3600
    }
    
    /// Formatted time difference string
    func timeDifferenceString() -> String {
        let diff = timeDifferenceFromLocal()
        if diff == 0 {
            return "今天 +0小时"
        } else if diff > 0 {
            return "今天 +\(diff)小时"
        } else {
            return "今天 \(diff)小时"
        }
    }
}

// MARK: - Preset Cities (World Capitals)
extension City {
    static let presets: [City] = [
        // Asia
        City(name: "Beijing", localizedName: "北京", timeZoneIdentifier: "Asia/Shanghai", latitude: 39.9042, longitude: 116.4074),
        City(name: "Shanghai", localizedName: "上海", timeZoneIdentifier: "Asia/Shanghai", latitude: 31.2304, longitude: 121.4737),
        City(name: "Hong Kong", localizedName: "香港", timeZoneIdentifier: "Asia/Hong_Kong", latitude: 22.3193, longitude: 114.1694),
        City(name: "Taipei", localizedName: "台北", timeZoneIdentifier: "Asia/Taipei", latitude: 25.0330, longitude: 121.5654),
        City(name: "Urumqi", localizedName: "乌鲁木齐", timeZoneIdentifier: "Asia/Shanghai", latitude: 43.8256, longitude: 87.6168),
        City(name: "Tokyo", localizedName: "东京", timeZoneIdentifier: "Asia/Tokyo", latitude: 35.6762, longitude: 139.6503),
        City(name: "Seoul", localizedName: "首尔", timeZoneIdentifier: "Asia/Seoul", latitude: 37.5665, longitude: 126.9780),
        City(name: "Pyongyang", localizedName: "平壤", timeZoneIdentifier: "Asia/Pyongyang", latitude: 39.0392, longitude: 125.7625),
        City(name: "Bangkok", localizedName: "曼谷", timeZoneIdentifier: "Asia/Bangkok", latitude: 13.7563, longitude: 100.5018),
        City(name: "Hanoi", localizedName: "河内", timeZoneIdentifier: "Asia/Ho_Chi_Minh", latitude: 21.0285, longitude: 105.8542),
        City(name: "Manila", localizedName: "马尼拉", timeZoneIdentifier: "Asia/Manila", latitude: 14.5995, longitude: 120.9842),
        City(name: "Jakarta", localizedName: "雅加达", timeZoneIdentifier: "Asia/Jakarta", latitude: -6.2088, longitude: 106.8456),
        City(name: "Kuala Lumpur", localizedName: "吉隆坡", timeZoneIdentifier: "Asia/Kuala_Lumpur", latitude: 3.1390, longitude: 101.6869),
        City(name: "Singapore", localizedName: "新加坡", timeZoneIdentifier: "Asia/Singapore", latitude: 1.3521, longitude: 103.8198),
        City(name: "New Delhi", localizedName: "新德里", timeZoneIdentifier: "Asia/Kolkata", latitude: 28.6139, longitude: 77.2090),
        City(name: "Mumbai", localizedName: "孟买", timeZoneIdentifier: "Asia/Kolkata", latitude: 19.0760, longitude: 72.8777),
        City(name: "Islamabad", localizedName: "伊斯兰堡", timeZoneIdentifier: "Asia/Karachi", latitude: 33.6844, longitude: 73.0479),
        City(name: "Dhaka", localizedName: "达卡", timeZoneIdentifier: "Asia/Dhaka", latitude: 23.8103, longitude: 90.4125),
        City(name: "Kathmandu", localizedName: "加德满都", timeZoneIdentifier: "Asia/Kathmandu", latitude: 27.7172, longitude: 85.3240),
        City(name: "Dubai", localizedName: "迪拜", timeZoneIdentifier: "Asia/Dubai", latitude: 25.2048, longitude: 55.2708),
        City(name: "Abu Dhabi", localizedName: "阿布扎比", timeZoneIdentifier: "Asia/Dubai", latitude: 24.4539, longitude: 54.3773),
        City(name: "Riyadh", localizedName: "利雅得", timeZoneIdentifier: "Asia/Riyadh", latitude: 24.7136, longitude: 46.6753),
        City(name: "Tehran", localizedName: "德黑兰", timeZoneIdentifier: "Asia/Tehran", latitude: 35.6892, longitude: 51.3890),
        City(name: "Baghdad", localizedName: "巴格达", timeZoneIdentifier: "Asia/Baghdad", latitude: 33.3152, longitude: 44.3661),
        City(name: "Jerusalem", localizedName: "耶路撒冷", timeZoneIdentifier: "Asia/Jerusalem", latitude: 31.7683, longitude: 35.2137),
        City(name: "Ankara", localizedName: "安卡拉", timeZoneIdentifier: "Europe/Istanbul", latitude: 39.9334, longitude: 32.8597),
        City(name: "Istanbul", localizedName: "伊斯坦布尔", timeZoneIdentifier: "Europe/Istanbul", latitude: 41.0082, longitude: 28.9784),
        
        // Europe
        City(name: "London", localizedName: "伦敦", timeZoneIdentifier: "Europe/London", latitude: 51.5074, longitude: -0.1278),
        City(name: "Paris", localizedName: "巴黎", timeZoneIdentifier: "Europe/Paris", latitude: 48.8566, longitude: 2.3522),
        City(name: "Berlin", localizedName: "柏林", timeZoneIdentifier: "Europe/Berlin", latitude: 52.5200, longitude: 13.4050),
        City(name: "Rome", localizedName: "罗马", timeZoneIdentifier: "Europe/Rome", latitude: 41.9028, longitude: 12.4964),
        City(name: "Madrid", localizedName: "马德里", timeZoneIdentifier: "Europe/Madrid", latitude: 40.4168, longitude: -3.7038),
        City(name: "Lisbon", localizedName: "里斯本", timeZoneIdentifier: "Europe/Lisbon", latitude: 38.7223, longitude: -9.1393),
        City(name: "Amsterdam", localizedName: "阿姆斯特丹", timeZoneIdentifier: "Europe/Amsterdam", latitude: 52.3676, longitude: 4.9041),
        City(name: "Brussels", localizedName: "布鲁塞尔", timeZoneIdentifier: "Europe/Brussels", latitude: 50.8503, longitude: 4.3517),
        City(name: "Vienna", localizedName: "维也纳", timeZoneIdentifier: "Europe/Vienna", latitude: 48.2082, longitude: 16.3738),
        City(name: "Zurich", localizedName: "苏黎世", timeZoneIdentifier: "Europe/Zurich", latitude: 47.3769, longitude: 8.5417),
        City(name: "Stockholm", localizedName: "斯德哥尔摩", timeZoneIdentifier: "Europe/Stockholm", latitude: 59.3293, longitude: 18.0686),
        City(name: "Oslo", localizedName: "奥斯陆", timeZoneIdentifier: "Europe/Oslo", latitude: 59.9139, longitude: 10.7522),
        City(name: "Copenhagen", localizedName: "哥本哈根", timeZoneIdentifier: "Europe/Copenhagen", latitude: 55.6761, longitude: 12.5683),
        City(name: "Helsinki", localizedName: "赫尔辛基", timeZoneIdentifier: "Europe/Helsinki", latitude: 60.1699, longitude: 24.9384),
        City(name: "Warsaw", localizedName: "华沙", timeZoneIdentifier: "Europe/Warsaw", latitude: 52.2297, longitude: 21.0122),
        City(name: "Prague", localizedName: "布拉格", timeZoneIdentifier: "Europe/Prague", latitude: 50.0755, longitude: 14.4378),
        City(name: "Budapest", localizedName: "布达佩斯", timeZoneIdentifier: "Europe/Budapest", latitude: 47.4979, longitude: 19.0402),
        City(name: "Athens", localizedName: "雅典", timeZoneIdentifier: "Europe/Athens", latitude: 37.9838, longitude: 23.7275),
        City(name: "Moscow", localizedName: "莫斯科", timeZoneIdentifier: "Europe/Moscow", latitude: 55.7558, longitude: 37.6173),
        City(name: "Kyiv", localizedName: "基辅", timeZoneIdentifier: "Europe/Kyiv", latitude: 50.4501, longitude: 30.5234),
        City(name: "Dublin", localizedName: "都柏林", timeZoneIdentifier: "Europe/Dublin", latitude: 53.3498, longitude: -6.2603),
        City(name: "Edinburgh", localizedName: "爱丁堡", timeZoneIdentifier: "Europe/London", latitude: 55.9533, longitude: -3.1883),
        
        // Americas
        City(name: "Washington D.C.", localizedName: "华盛顿", timeZoneIdentifier: "America/New_York", latitude: 38.9072, longitude: -77.0369),
        City(name: "New York", localizedName: "纽约", timeZoneIdentifier: "America/New_York", latitude: 40.7128, longitude: -74.0060),
        City(name: "Los Angeles", localizedName: "洛杉矶", timeZoneIdentifier: "America/Los_Angeles", latitude: 34.0522, longitude: -118.2437),
        City(name: "Chicago", localizedName: "芝加哥", timeZoneIdentifier: "America/Chicago", latitude: 41.8781, longitude: -87.6298),
        City(name: "San Francisco", localizedName: "旧金山", timeZoneIdentifier: "America/Los_Angeles", latitude: 37.7749, longitude: -122.4194),
        City(name: "Seattle", localizedName: "西雅图", timeZoneIdentifier: "America/Los_Angeles", latitude: 47.6062, longitude: -122.3321),
        City(name: "Miami", localizedName: "迈阿密", timeZoneIdentifier: "America/New_York", latitude: 25.7617, longitude: -80.1918),
        City(name: "Philadelphia", localizedName: "费城", timeZoneIdentifier: "America/New_York", latitude: 39.9526, longitude: -75.1652),
        City(name: "Ottawa", localizedName: "渥太华", timeZoneIdentifier: "America/Toronto", latitude: 45.4215, longitude: -75.6972),
        City(name: "Toronto", localizedName: "多伦多", timeZoneIdentifier: "America/Toronto", latitude: 43.6532, longitude: -79.3832),
        City(name: "Vancouver", localizedName: "温哥华", timeZoneIdentifier: "America/Vancouver", latitude: 49.2827, longitude: -123.1207),
        City(name: "Mexico City", localizedName: "墨西哥城", timeZoneIdentifier: "America/Mexico_City", latitude: 19.4326, longitude: -99.1332),
        City(name: "Havana", localizedName: "哈瓦那", timeZoneIdentifier: "America/Havana", latitude: 23.1136, longitude: -82.3666),
        City(name: "Brasília", localizedName: "巴西利亚", timeZoneIdentifier: "America/Sao_Paulo", latitude: -15.7975, longitude: -47.8919),
        City(name: "São Paulo", localizedName: "圣保罗", timeZoneIdentifier: "America/Sao_Paulo", latitude: -23.5505, longitude: -46.6333),
        City(name: "Rio de Janeiro", localizedName: "里约热内卢", timeZoneIdentifier: "America/Sao_Paulo", latitude: -22.9068, longitude: -43.1729),
        City(name: "Buenos Aires", localizedName: "布宜诺斯艾利斯", timeZoneIdentifier: "America/Argentina/Buenos_Aires", latitude: -34.6037, longitude: -58.3816),
        City(name: "Santiago", localizedName: "圣地亚哥", timeZoneIdentifier: "America/Santiago", latitude: -33.4489, longitude: -70.6693),
        City(name: "Lima", localizedName: "利马", timeZoneIdentifier: "America/Lima", latitude: -12.0464, longitude: -77.0428),
        City(name: "Bogotá", localizedName: "波哥大", timeZoneIdentifier: "America/Bogota", latitude: 4.7110, longitude: -74.0721),
        
        // Africa
        City(name: "Cairo", localizedName: "开罗", timeZoneIdentifier: "Africa/Cairo", latitude: 30.0444, longitude: 31.2357),
        City(name: "Lagos", localizedName: "拉各斯", timeZoneIdentifier: "Africa/Lagos", latitude: 6.5244, longitude: 3.3792),
        City(name: "Nairobi", localizedName: "内罗毕", timeZoneIdentifier: "Africa/Nairobi", latitude: -1.2921, longitude: 36.8219),
        City(name: "Johannesburg", localizedName: "约翰内斯堡", timeZoneIdentifier: "Africa/Johannesburg", latitude: -26.2041, longitude: 28.0473),
        City(name: "Cape Town", localizedName: "开普敦", timeZoneIdentifier: "Africa/Johannesburg", latitude: -33.9249, longitude: 18.4241),
        City(name: "Casablanca", localizedName: "卡萨布兰卡", timeZoneIdentifier: "Africa/Casablanca", latitude: 33.5731, longitude: -7.5898),
        City(name: "Addis Ababa", localizedName: "亚的斯亚贝巴", timeZoneIdentifier: "Africa/Addis_Ababa", latitude: 9.0320, longitude: 38.7469),
        
        // Oceania
        City(name: "Canberra", localizedName: "堪培拉", timeZoneIdentifier: "Australia/Sydney", latitude: -35.2809, longitude: 149.1300),
        City(name: "Sydney", localizedName: "悉尼", timeZoneIdentifier: "Australia/Sydney", latitude: -33.8688, longitude: 151.2093),
        City(name: "Melbourne", localizedName: "墨尔本", timeZoneIdentifier: "Australia/Melbourne", latitude: -37.8136, longitude: 144.9631),
        City(name: "Wellington", localizedName: "惠灵顿", timeZoneIdentifier: "Pacific/Auckland", latitude: -41.2865, longitude: 174.7762),
        City(name: "Auckland", localizedName: "奥克兰", timeZoneIdentifier: "Pacific/Auckland", latitude: -36.8485, longitude: 174.7633),
        City(name: "Fiji", localizedName: "斐济", timeZoneIdentifier: "Pacific/Fiji", latitude: -18.1416, longitude: 178.4419),
    ]
    
    static let defaultCities: [City] = [
        presets.first { $0.name == "Beijing" }!,
        presets.first { $0.name == "Philadelphia" }!,
        presets.first { $0.name == "Urumqi" }!,
    ]
}
