import Foundation

enum AppConfig {
    /// Base URL del backend NestJS. Nunca incluye la API key de OpenAI.
    /// Debug (simulador): API local. Release: producción detrás de Nginx.
    static var apiBaseURL: URL {
        #if DEBUG
        if let override = Bundle.main.object(forInfoDictionaryKey: "VOS_API_BASE_URL") as? String,
           let url = URL(string: override), !override.isEmpty {
            return url
        }
        return URL(string: "http://127.0.0.1:3000")!
        #else
        if let override = Bundle.main.object(forInfoDictionaryKey: "VOS_API_BASE_URL") as? String,
           let url = URL(string: override), !override.isEmpty {
            return url
        }
        return URL(string: "https://vos-ia.com/backend")!
        #endif
    }

    static let sessionStartMarker = "__SESSION_START__"
    static let maxHistoryItems = 12
    static let brandName = "VOS IA"
}
