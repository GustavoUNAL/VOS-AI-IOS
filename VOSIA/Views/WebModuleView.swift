import SwiftUI
import WebKit

/// Abre el módulo completo de la web con la misma sesión JWT de la app nativa.
struct WebModuleView: View {
    @Environment(SessionStore.self) private var session
    let module: AppModule

    var body: some View {
        Group {
            if let token = session.accessToken, !token.isEmpty,
               let slug = session.user?.companySlug.trimmingCharacters(in: .whitespacesAndNewlines),
               !slug.isEmpty,
               let path = module.webPath {
                WebModuleRepresentable(
                    token: token,
                    companyId: session.companyId ?? session.user?.companyId ?? "",
                    companySlug: slug,
                    viewPath: path
                )
            } else {
                ContentUnavailableView {
                    Label(module.title, systemImage: module.systemImage)
                } description: {
                    Text("No hay sesión o empresa para abrir este módulo.")
                }
            }
        }
        .background(AppTheme.canvas.ignoresSafeArea())
        .navigationTitle(module.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct WebModuleRepresentable: UIViewRepresentable {
    let token: String
    let companyId: String
    let companySlug: String
    let viewPath: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        context.coordinator.loadHandoff(
            into: webView,
            token: token,
            companyId: companyId,
            companySlug: companySlug,
            viewPath: viewPath
        )
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Recarga solo si cambió el destino (empresa/módulo).
        let key = "\(companySlug)|\(viewPath)|\(companyId)"
        if context.coordinator.lastKey != key {
            context.coordinator.loadHandoff(
                into: webView,
                token: token,
                companyId: companyId,
                companySlug: companySlug,
                viewPath: viewPath
            )
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var lastKey: String?

        func loadHandoff(
            into webView: WKWebView,
            token: String,
            companyId: String,
            companySlug: String,
            viewPath: String
        ) {
            lastKey = "\(companySlug)|\(viewPath)|\(companyId)"
            var comps = URLComponents(url: AppConfig.webBaseURL, resolvingAgainstBaseURL: false)
            var items: [URLQueryItem] = [
                URLQueryItem(name: "access_token", value: token),
                URLQueryItem(name: "next", value: "e/\(companySlug)/\(viewPath)"),
            ]
            if !companyId.isEmpty {
                items.append(URLQueryItem(name: "company_id", value: companyId))
            }
            // El handoff vive en el fragmento para no mandar el JWT en la request HTTP.
            let query = items
                .map { item -> String in
                    let name = item.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? item.name
                    let value = (item.value ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                    return "\(name)=\(value)"
                }
                .joined(separator: "&")
            comps?.fragment = "native-handoff?\(query)"
            guard let url = comps?.url else { return }
            webView.load(URLRequest(url: url))
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if let url = navigationAction.request.url,
               let scheme = url.scheme?.lowercased(),
               scheme != "http", scheme != "https", scheme != "about" {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}
