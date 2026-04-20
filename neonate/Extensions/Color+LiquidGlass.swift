import SwiftUI

// MARK: - Liquid Glass Color Palette

extension Color {

    // MARK: - Primary Glass Colors

    static let glassBlue = Color(red: 0.4, green: 0.6, blue: 1.0)
    static let glassPurple = Color(red: 0.6, green: 0.4, blue: 0.9)
    static let glassIndigo = Color(red: 0.5, green: 0.3, blue: 0.85)
    static let glassCyan = Color(red: 0.3, green: 0.5, blue: 0.95)

    // MARK: - Semantic Colors

    static let glassFeeding = Color.green
    static let glassSleep = Color.indigo
    static let glassDiaper = Color.blue
    static let glassHealth = Color.red
    static let glassReminder = Color.orange

    // MARK: - Background Gradients

    static func glassBackgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [
                colorScheme == .dark
                    ? Color.black
                    : Color(.systemBackground),
                colorScheme == .dark
                    ? Color.glassBlue.opacity(0.1)
                    : Color.glassBlue.opacity(0.03),
                colorScheme == .dark
                    ? Color.glassPurple.opacity(0.1)
                    : Color.glassPurple.opacity(0.03)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var meshGradientColors: [Color] {
        [
            Color.glassBlue,
            Color.glassPurple,
            Color.glassCyan,
            Color.glassIndigo
        ]
    }
}

// MARK: - Gradient Presets

struct LiquidGlassGradients {

    static let primaryAuth = LinearGradient(
        colors: [
            Color.glassBlue.opacity(0.8),
            Color.glassPurple.opacity(0.6)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let iconGradient = LinearGradient(
        colors: [Color.glassBlue, Color.glassPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let buttonGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.3),
            Color.white.opacity(0.1)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static let borderGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.6),
            Color.white.opacity(0.1)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static func cardGradient(for color: Color) -> LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.2),
                Color.white.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func glowGradient(for color: Color) -> RadialGradient {
        RadialGradient(
            colors: [
                color.opacity(0.3),
                color.opacity(0.1),
                Color.clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: 100
        )
    }
}
