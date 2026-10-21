import AppIntents
import Foundation

public enum PrayerQueryType: String, AppEnum {
    case next = "next"
    case fajr = "fajr"
    case sunrise = "sunrise"
    case dhuhr = "dhuhr"
    case asr = "asr"
    case maghrib = "maghrib"
    case isha = "isha"

    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "Prayer"

    public static var caseDisplayRepresentations: [PrayerQueryType: DisplayRepresentation] = [
        .next: "Next Prayer",
        .fajr: "Fajr",
        .sunrise: "Sunrise (Chorouq)",
        .dhuhr: "Dhuhr",
        .asr: "Asr",
        .maghrib: "Maghrib",
        .isha: "Isha"
    ]
}

// MARK: - Voice-Enabled Siri Prayer Time Intent
public struct GetPrayerTimeIntent: AppIntent {
    public static var title: LocalizedStringResource = "Get Prayer Time"
    public static var description = IntentDescription("Asks Siri for the next upcoming prayer or a specific prayer time (Fajr, Dhuhr, Asr, Maghrib, Isha).")
    public static var openAppWhenRun: Bool = false

    @Parameter(title: "Prayer", default: .next)
    public var prayer: PrayerQueryType

    public init() {
        self.prayer = .next
    }

    public init(prayer: PrayerQueryType) {
        self.prayer = prayer
    }

    public func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let defaults = UserDefaults(suiteName: "group.tools.rea.Bayan") ?? UserDefaults.standard
        let savedLat = defaults.double(forKey: "bayan_last_latitude")
        let savedLng = defaults.double(forKey: "bayan_last_longitude")
        let lat = savedLat != 0.0 ? savedLat : 33.5731
        let lng = savedLng != 0.0 ? savedLng : -7.5898
        let city = defaults.string(forKey: "bayan_last_city_name") ?? "Casablanca"

        let calcResult = PrayerCalculationService.shared.calculate(for: Date(), lat: lat, lng: lng)

        let responseText: String
        switch prayer {
        case .next:
            let next = calcResult.nextPrayer
            let diffMins = max(1, Int(next.time.timeIntervalSince(Date()) / 60))
            let hours = diffMins / 60
            let mins = diffMins % 60
            let timeRemaining: String
            if hours > 0 {
                timeRemaining = "in \(hours) hour\(hours > 1 ? "s" : "") and \(mins) minute\(mins > 1 ? "s" : "")"
            } else {
                timeRemaining = "in \(mins) minute\(mins > 1 ? "s" : "")"
            }
            responseText = "The next prayer is \(next.nameEnglish) at \(next.timeString) in \(city) (\(timeRemaining))."

        case .fajr:
            if let p = calcResult.prayers.first(where: { $0.type == .fajr }) {
                responseText = "Fajr prayer is at \(p.timeString) in \(city)."
            } else {
                responseText = "Fajr time is calculated in Bayan."
            }

        case .sunrise:
            if let p = calcResult.prayers.first(where: { $0.type == .sunrise }) {
                responseText = "Sunrise is at \(p.timeString) in \(city)."
            } else {
                responseText = "Sunrise time is calculated in Bayan."
            }

        case .dhuhr:
            if let p = calcResult.prayers.first(where: { $0.type == .dhuhr }) {
                responseText = "Dhuhr prayer is at \(p.timeString) in \(city)."
            } else {
                responseText = "Dhuhr time is calculated in Bayan."
            }

        case .asr:
            if let p = calcResult.prayers.first(where: { $0.type == .asr }) {
                responseText = "Asr prayer is at \(p.timeString) in \(city)."
            } else {
                responseText = "Asr time is calculated in Bayan."
            }

        case .maghrib:
            if let p = calcResult.prayers.first(where: { $0.type == .maghrib }) {
                responseText = "Maghrib prayer is at \(p.timeString) in \(city)."
            } else {
                responseText = "Maghrib time is calculated in Bayan."
            }

        case .isha:
            if let p = calcResult.prayers.first(where: { $0.type == .isha }) {
                responseText = "Isha prayer is at \(p.timeString) in \(city)."
            } else {
                responseText = "Isha time is calculated in Bayan."
            }
        }

        return .result(value: responseText, dialog: IntentDialog(stringLiteral: responseText))
    }
}
