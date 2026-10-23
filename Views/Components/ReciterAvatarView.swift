import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Reciter Avatar Portrait View
/// Renders a circular, high-definition portrait of a Quran reciter.
/// Automatically resolves:
/// 1. Offline bundled local image (Resources/Reciters/{id}.jpg)
/// 2. Verified high-speed CDN URL via AsyncImage with cached loading
/// 3. Luxury gold-trimmed initial/calligraphy avatar fallback
public struct ReciterAvatarView: View {
    public let reciter: Reciter
    public var size: CGFloat = 44
    public var isSelected: Bool = false
    public var showBorder: Bool = true
    public var borderColor: Color? = nil
    public var borderWidth: CGFloat = 1.5
    public var showWaveform: Bool = false
    public var hasGlow: Bool = false

    public init(
        reciter: Reciter,
        size: CGFloat = 44,
        isSelected: Bool = false,
        showBorder: Bool = true,
        borderColor: Color? = nil,
        borderWidth: CGFloat = 1.5,
        showWaveform: Bool = false,
        hasGlow: Bool = false
    ) {
        self.reciter = reciter
        self.size = size
        self.isSelected = isSelected
        self.showBorder = showBorder
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.showWaveform = showWaveform
        self.hasGlow = hasGlow
    }

    private var activeBorderColor: Color {
        if let custom = borderColor {
            return custom
        }
        if isSelected {
            return BayanTheme.gold
        }
        return Color.white.opacity(0.12)
    }

    private var localBundleImage: UIImage? {
        #if canImport(UIKit)
        // 1. Direct named asset lookup
        if let img = UIImage(named: reciter.imageName) {
            return img
        }
        // 2. Check subdirectory "Reciters" in bundle
        if let path = Bundle.main.path(forResource: reciter.imageName, ofType: "jpg", inDirectory: "Reciters"),
           let img = UIImage(contentsOfFile: path) {
            return img
        }
        // 3. Check root bundle resources
        if let path = Bundle.main.path(forResource: reciter.imageName, ofType: "jpg"),
           let img = UIImage(contentsOfFile: path) {
            return img
        }
        #endif
        return nil
    }

    public var body: some View {
        ZStack {
            // 1. Image Content (Local or Remote)
            if let localImg = localBundleImage {
                #if canImport(UIKit)
                Image(uiImage: localImg)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                #endif
            } else if let url = reciter.imageUrl {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipShape(Circle())
                    case .failure:
                        fallbackAvatar
                    case .empty:
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.12, green: 0.14, blue: 0.20))
                                .frame(width: size, height: size)
                            ProgressView()
                                .scaleEffect(size > 50 ? 0.7 : 0.5)
                                .tint(BayanTheme.gold)
                        }
                    @unknown default:
                        fallbackAvatar
                    }
                }
            } else {
                fallbackAvatar
            }

            // 2. Waveform Overlay (when audio preview is playing)
            if showWaveform {
                Circle()
                    .fill(Color.black.opacity(0.48))
                    .frame(width: size, height: size)

                Image(systemName: "waveform")
                    .font(.system(size: size * 0.35, weight: .bold))
                    .foregroundColor(BayanTheme.gold)
                    .symbolEffect(.variableColor.iterative.reversing, isActive: true)
            }

            // 3. Selection Ring & Rim
            if showBorder || isSelected {
                Circle()
                    .stroke(activeBorderColor, lineWidth: isSelected ? max(borderWidth, 2.0) : borderWidth)
                    .frame(width: size, height: size)
                    .shadow(
                        color: (isSelected || hasGlow) ? BayanTheme.gold.opacity(0.55) : Color.clear,
                        radius: isSelected ? 6 : 0
                    )
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Fallback Avatar
    private var fallbackAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.18, blue: 0.25),
                            Color(red: 0.08, green: 0.10, blue: 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Text(reciterInitial)
                .font(.system(size: size * 0.42, weight: .bold, design: .serif))
                .foregroundColor(BayanTheme.gold)
        }
    }

    private var reciterInitial: String {
        let trimmed = reciter.nameArabic.trimmingCharacters(in: .whitespaces)
        if let first = trimmed.first {
            return String(first)
        }
        return "ق"
    }
}
