import Foundation

enum AppConfig {
    /// Backend NestJS. Nunca incluye la API key de OpenAI.
    /// Por defecto: producción (simulador listo sin stack local).
    /// Override: Info.plist / build setting `VOS_API_BASE_URL`.
    static var apiBaseURL: URL {
        if let override = Bundle.main.object(forInfoDictionaryKey: "VOS_API_BASE_URL") as? String,
           let url = URL(string: override.trimmingCharacters(in: .whitespacesAndNewlines)),
           !override.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return url
        }
        return URL(string: "https://vos-ia.com/backend")!
    }

    /// Front web (módulos vía WKWebView). Mismo origen que la web pública.
    static var webBaseURL: URL {
        if let override = Bundle.main.object(forInfoDictionaryKey: "VOS_WEB_BASE_URL") as? String,
           let url = URL(string: override.trimmingCharacters(in: .whitespacesAndNewlines)),
           !override.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return url
        }
        return URL(string: "https://vos-ia.com")!
    }

    static let sessionStartMarker = "__SESSION_START__"
    static let maxHistoryItems = 12
    static let brandName = "VOS IA"
}
