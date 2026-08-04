import AppKit
import SwiftUI

enum UtilityTheme {
    static let accent = adaptive(
        light: NSColor(
            red: 0.18,
            green: 0.36,
            blue: 0.45,
            alpha: 1
        ),
        dark: NSColor(
            red: 0.45,
            green: 0.66,
            blue: 0.75,
            alpha: 1
        )
    )
    static let ready = adaptive(
        light: NSColor(
            red: 0.18,
            green: 0.45,
            blue: 0.42,
            alpha: 1
        ),
        dark: NSColor(
            red: 0.37,
            green: 0.70,
            blue: 0.65,
            alpha: 1
        )
    )
    static let review = adaptive(
        light: NSColor(
            red: 0.65,
            green: 0.40,
            blue: 0.16,
            alpha: 1
        ),
        dark: NSColor(
            red: 0.84,
            green: 0.60,
            blue: 0.33,
            alpha: 1
        )
    )
    static let managed = adaptive(
        light: NSColor(
            red: 0.42,
            green: 0.46,
            blue: 0.50,
            alpha: 1
        ),
        dark: NSColor(
            red: 0.61,
            green: 0.65,
            blue: 0.69,
            alpha: 1
        )
    )

    static let canvas = Color(nsColor: .windowBackgroundColor)
    static let hairline = Color.primary.opacity(0.11)
    static let strongerHairline = Color.primary.opacity(0.18)

    static func color(for safety: CleanupSafety) -> Color {
        switch safety {
        case .reclaimable:
            ready
        case .reviewRequired:
            review
        case .protected:
            managed
        }
    }

    private static func adaptive(
        light: NSColor,
        dark: NSColor
    ) -> Color {
        Color(
            nsColor: NSColor(name: nil) { appearance in
                appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                    ? dark
                    : light
            }
        )
    }
}

enum UtilityLayout {
    static let contentInset: CGFloat = 20
}
