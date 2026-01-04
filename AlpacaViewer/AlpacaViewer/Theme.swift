import SwiftUI

struct Theme {
    static let background = Color(hex: "121212")
    static let cardBackground = Color(hex: "1C1C1E")
    
    static let brandPurple = Color(hex: "7F5AF0")
    static let financialGreen = Color(hex: "2CB67D")
    static let financialRed = Color(hex: "EF4565")
    
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "94A1B2")
    
    static let greenGradient = LinearGradient(
        colors: [financialGreen.opacity(0.4), financialGreen.opacity(0.0)],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4) & 0xF * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
