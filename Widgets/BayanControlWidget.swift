import WidgetKit
import SwiftUI
import AppIntents

// MARK: - iOS 18+ Control Center & Lock Screen Quick Control
@available(iOS 18.0, *)
public struct BayanControlWidget: ControlWidget {
    public static let kind: String = "com.bayan.app.control.identify"

    public init() {}

    public var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: RecognizeQuranIntent()) {
                Label("Identify Quran", systemImage: "waveform.circle.fill")
            }
        }
        .displayName("Identify Quran")
        .description("Tap to identify Surah, Ayah, and Reciter with Bayan.")
    }
}
