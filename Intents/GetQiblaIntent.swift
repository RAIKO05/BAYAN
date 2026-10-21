import AppIntents
import Foundation

// MARK: - Voice-Enabled Siri Qibla Direction Intent
public struct GetQiblaIntent: AppIntent {
    public static var title: LocalizedStringResource = "Get Qibla Direction"
    public static var description = IntentDescription("Asks Siri for the compass heading and direction towards the Holy Kaaba in Makkah.")
    public static var openAppWhenRun: Bool = false

    public init() {}

    public func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let defaults = UserDefaults(suiteName: "group.tools.rea.Bayan") ?? UserDefaults.standard
        let savedLat = defaults.double(forKey: "bayan_last_latitude")
        let savedLng = defaults.double(forKey: "bayan_last_longitude")
        let lat = savedLat != 0.0 ? savedLat : 33.5731
        let lng = savedLng != 0.0 ? savedLng : -7.5898
        let city = defaults.string(forKey: "bayan_last_city_name") ?? "Casablanca"

        // Calculate exact Qibla Great-Circle Bearing to Holy Kaaba (21.4225, 39.8262)
        let kaabaLat = 21.4225 * .pi / 180.0
        let kaabaLng = 39.8262 * .pi / 180.0
        let userLat = lat * .pi / 180.0
        let userLng = lng * .pi / 180.0

        let dLng = kaabaLng - userLng
        let y = sin(dLng) * cos(kaabaLat)
        let x = cos(userLat) * sin(kaabaLat) - sin(userLat) * cos(kaabaLat) * cos(dLng)
        var bearing = atan2(y, x) * 180.0 / .pi
        if bearing < 0 { bearing += 360.0 }

        let cardinalDirection: String
        switch bearing {
        case 0..<22.5, 337.5...360: cardinalDirection = "North"
        case 22.5..<67.5: cardinalDirection = "Northeast"
        case 67.5..<112.5: cardinalDirection = "East"
        case 112.5..<157.5: cardinalDirection = "Southeast"
        case 157.5..<202.5: cardinalDirection = "South"
        case 202.5..<247.5: cardinalDirection = "Southwest"
        case 247.5..<292.5: cardinalDirection = "West"
        default: cardinalDirection = "Northwest"
        }

        let response = "The Qibla is at \(Int(bearing)) degrees (\(cardinalDirection)) from your location in \(city)."
        return .result(value: response, dialog: IntentDialog(stringLiteral: response))
    }
}
