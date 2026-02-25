import SwiftUI

enum Theme {
    // Surfaces
    static let background   = Color(hex: "f7f4ef")
    static let chrome       = Color(hex: "efe9df")
    static let border       = Color(hex: "e2dbd0")
    static let subtle       = Color(hex: "ece6db")

    // Text
    static let textPrimary  = Color(hex: "1c1a17")
    static let textBody     = Color(hex: "3a3428")
    static let textMuted    = Color(hex: "7a7060")
    static let textFaint    = Color(hex: "a09080")
    static let textMeta     = Color(hex: "b0a898")

    // Accent
    static let accent       = Color(hex: "7a9e8a")
    static let accentLight  = Color(hex: "7a9e8a").opacity(0.12)

    // Inline code
    static let codeBg       = Color(hex: "ece6db")
    static let codeText     = Color(hex: "5a7a6a")

    // Typography — IBM Plex Serif for reading content, SF Pro for UI chrome
    static let titleFont    = Font.custom("IBMPlexSerif-SemiBold",      size: 46)
    static let h2Font       = Font.custom("IBMPlexSerif-SemiBold",      size: 26)
    static let h3Font       = Font.custom("IBMPlexSerif-SemiBold",      size: 20)
    static let bodyFont     = Font.custom("IBMPlexSerif-Light",         size: 17)
    static let metaFont     = Font.system(size: 11, weight: .semibold, design: .default)
    static let uiFont       = Font.system(size: 12, weight: .regular,  design: .default)
    static let uiFontMedium = Font.system(size: 12, weight: .medium,   design: .default)
    static let monoFont     = Font.system(size: 13, weight: .medium,   design: .monospaced)
    static let statusFont   = Font.system(size: 11, weight: .regular,  design: .default)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
