import Foundation

// MARK: - Hi-Res / Dolby Hi-Fi Audio Quality Profile
public enum AudioQualityProfile: String, CaseIterable, Identifiable, Sendable {
    case hiResMaster = "hires"
    case dolbySpatial = "spatial"
    case warmHiFi = "warm"
    case studioNeutral = "neutral"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .hiResMaster: return "Hi-Res Studio Master"
        case .dolbySpatial: return "Dolby Spatial Sanctuary"
        case .warmHiFi: return "Warm Acoustic Hi-Fi"
        case .studioNeutral: return "Studio Neutral"
        }
    }

    public var subtitle: String {
        switch self {
        case .hiResMaster: return "24-bit • 48,000 Hz Lossless Studio Buffer"
        case .dolbySpatial: return "3D Immersive Sanctuary Soundstage"
        case .warmHiFi: return "Analog Tube Warmth & Vocal Resonance"
        case .studioNeutral: return "Flat Frequency Reference Monitoring"
        }
    }

    public var badgeText: String {
        switch self {
        case .hiResMaster: return "24-BIT • 48kHz HI-RES"
        case .dolbySpatial: return "DOLBY SPATIAL"
        case .warmHiFi: return "HI-FI WARMTH"
        case .studioNeutral: return "STUDIO"
        }
    }

    public var badge: String {
        switch self {
        case .hiResMaster: return "Hi-Res"
        case .dolbySpatial: return "Spatial"
        case .warmHiFi: return "Hi-Fi"
        case .studioNeutral: return "Studio"
        }
    }

    public var iconName: String {
        switch self {
        case .hiResMaster: return "sparkles"
        case .dolbySpatial: return "spatial"
        case .warmHiFi: return "waveform.circle.fill"
        case .studioNeutral: return "speaker.wave.2.fill"
        }
    }
}
