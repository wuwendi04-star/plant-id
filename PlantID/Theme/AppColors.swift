import SwiftUI

enum AppColors {
    // Background gradient stops (match Android)
    static let backgroundTop    = Color(hex: "#C3D0AB")
    static let backgroundMid    = Color(hex: "#D4E0BB")
    static let backgroundBottom = Color(hex: "#E6EFCE")

    // Primary surface
    static let cardBackground   = Color.white.opacity(0.85)
    static let cardBorder       = Color(hex: "#B8C9A3")

    // Watering urgency
    static let urgencyOK        = Color(hex: "#6BAA75")
    static let urgencyDueToday  = Color(hex: "#E8A838")
    static let urgencyOverdue   = Color(hex: "#D95F3B")

    // Status chips
    static let statusAlive      = Color(hex: "#5C8A63")
    static let statusArchived   = Color(hex: "#9E9E9E")

    // Text
    static let textPrimary      = Color(hex: "#2C3E1A")
    static let textSecondary    = Color(hex: "#6B7A5E")
    static let textMuted        = Color(hex: "#9EA89A")

    // Tab bar
    static let tabBarBackground = Color(hex: "#2C3E1A").opacity(0.9)
    static let tabBarSelected   = Color.white
    static let tabBarUnselected = Color.white.opacity(0.5)

    // Danger
    static let danger           = Color(hex: "#C0392B")
    static let dangerBackground = Color(hex: "#FDECEA")
}
