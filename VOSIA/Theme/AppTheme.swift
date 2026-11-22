import SwiftUI

/// Paleta sobria alineada al sistema iOS: claro limpio, oscuro mate sin brillos.
enum AppTheme {
    static var canvas: Color { Color(.systemGroupedBackground) }
    static var card: Color { Color(.secondarySystemGroupedBackground) }
    static var hairline: Color { Color(.separator).opacity(0.45) }
    static var danger: Color { Color.red.opacity(0.85) }
    static var positive: Color { Color.green.opacity(0.85) }

    static var accentMuted: Color { Color("AccentColor") }
    static var accentSoftFill: Color { accentMuted.opacity(0.12) }

    static func money(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "COP"
        f.maximumFractionDigits = 0
        f.locale = Locale(identifier: "es_CO")
        return f.string(from: NSNumber(value: value)) ?? "\(Int(value))"
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

/// Intro breve al inicio de cada módulo (mismo tono en toda la app).
struct ScreenIntro: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ScreenErrorText: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.footnote)
            .foregroundStyle(AppTheme.danger)
    }
}

struct ScreenEmptyText: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.body)
            .foregroundStyle(.secondary)
    }
}

struct ChatBubble: View {
    let isUser: Bool
    let authorLabel: String
    let text: String
    var useMarkdown: Bool = true

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 40) }
            VStack(alignment: .leading, spacing: 4) {
                Text(authorLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                if useMarkdown {
                    MarkdownText(text: text)
                } else {
                    Text(text)
                }
            }
            .padding(12)
            .background(isUser ? AppTheme.accentSoftFill : AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppTheme.hairline, lineWidth: 0.5)
            )
            if !isUser { Spacer(minLength: 40) }
        }
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

struct ScreenListChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(AppTheme.canvas.ignoresSafeArea())
            .tint(AppTheme.accentMuted)
    }
}

extension View {
    func soberCard(minHeight: CGFloat? = nil) -> some View {
        modifier(SoberCardModifier())
            .frame(minHeight: minHeight)
    }

    func screenListChrome() -> some View {
        modifier(ScreenListChrome())
    }
}
