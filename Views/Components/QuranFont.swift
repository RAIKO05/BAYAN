import SwiftUI
import CoreText

// MARK: - Quran Authentic Typography
extension Font {
    /// Authentic Uthmanic Quran calligraphy font (Amiri Quran / KFGQPC style)
    public static func quran(size: CGFloat) -> Font {
        if UIFont(name: "AmiriQuran-Regular", size: size) != nil {
            return .custom("AmiriQuran-Regular", size: size)
        } else if UIFont(name: "Amiri Quran", size: size) != nil {
            return .custom("Amiri Quran", size: size)
        } else if UIFont(name: "DiwanMishafi", size: size) != nil {
            return .custom("DiwanMishafi", size: size)
        } else if UIFont(name: "GeezaPro", size: size) != nil {
            return .custom("GeezaPro", size: size)
        }
        return .system(size: size, weight: .regular, design: .serif)
    }

    /// Bold Uthmanic Quran calligraphy font
    public static func quranBold(size: CGFloat) -> Font {
        if UIFont(name: "AmiriQuran-Regular", size: size) != nil {
            return .custom("AmiriQuran-Regular", size: size)
        } else if UIFont(name: "Amiri Quran", size: size) != nil {
            return .custom("Amiri Quran", size: size)
        } else if UIFont(name: "GeezaPro-Bold", size: size) != nil {
            return .custom("GeezaPro-Bold", size: size)
        }
        return .system(size: size, weight: .bold, design: .serif)
    }
}
