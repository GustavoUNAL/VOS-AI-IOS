import SwiftUI

/// Paleta sobria alineada al sistema iOS: claro limpio, oscuro mate sin brillos.
enum AppTheme {
    static var canvas: Color { Color(.systemGroupedBackground) }
    static var card: Color { Color(.secondarySystemGroupedBackground) }
    static var hairline: Color { Color(.separator).opacity(0.45) }

    /// Acento suave: en oscuro pierde saturación para no “encender” la UI.
    static var accentMuted: Color {
        Color("AccentColor")
    }

    static var accentSoftFill: Color {
        accentMuted.opacity(0.12)
    }

    static var pageGradient: LinearGradient {
        LinearGradient(
            colors: [canvas, canvas],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func cardBackground() -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(card)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(hairline, lineWidth: 0.5)
            )
    }
}

struct SoberCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.cardBackground())
    }
}

extension View {
    func soberCard(minHeight: CGFloat? = nil) -> some View {
        modifier(SoberCardModifier())
            .frame(minHeight: minHeight)
    }
}
