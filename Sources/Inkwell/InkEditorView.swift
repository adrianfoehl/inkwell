import SwiftUI
import WebKit

struct InkEditorView: NSViewRepresentable {
    let text: String
    let onTextChange: (String) -> Void

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "contentChange")
        config.userContentController.add(context.coordinator, name: "editorReady")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.wantsLayer = true
        webView.layer?.masksToBounds = true

        // Load HTML as string so network imports (esm.sh) are allowed
        if let url = Bundle.module.url(forResource: "editor", withExtension: "html"),
           let html = try? String(contentsOf: url, encoding: .utf8) {
            webView.loadHTMLString(html, baseURL: URL(string: "https://esm.sh"))
        }

        context.coordinator.webView = webView
        context.coordinator.pendingContent = text
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if context.coordinator.lastSetContent != text {
            context.coordinator.setContent(text)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTextChange: onTextChange)
    }

    class Coordinator: NSObject, WKScriptMessageHandler {
        let onTextChange: (String) -> Void
        weak var webView: WKWebView?
        var isReady = false
        var pendingContent: String?
        var lastSetContent: String = ""
        private var isDarkMode: Bool = false
        private var appearanceObserver: NSKeyValueObservation?

        init(onTextChange: @escaping (String) -> Void) {
            self.onTextChange = onTextChange
            super.init()

            appearanceObserver = NSApp.observe(\.effectiveAppearance) { [weak self] app, _ in
                let dark = app.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                if dark != self?.isDarkMode {
                    self?.isDarkMode = dark
                    self?.webView?.evaluateJavaScript(
                        "setAppearance('\(dark ? "dark" : "light")')",
                        completionHandler: nil
                    )
                }
            }
            isDarkMode = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        }

        func userContentController(
            _ controller: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            switch message.name {
            case "editorReady":
                isReady = true
                if let content = pendingContent {
                    setContent(content)
                    pendingContent = nil
                }

            case "contentChange":
                if let doc = message.body as? String {
                    lastSetContent = doc
                    DispatchQueue.main.async {
                        self.onTextChange(doc)
                    }
                }

            default:
                break
            }
        }

        func setContent(_ markdown: String) {
            lastSetContent = markdown
            guard isReady, let webView else {
                pendingContent = markdown
                return
            }
            let escaped = escapeForJS(markdown)
            webView.evaluateJavaScript("setContent(`\(escaped)`)", completionHandler: nil)
        }

        private func escapeForJS(_ str: String) -> String {
            str.replacingOccurrences(of: "\\", with: "\\\\")
               .replacingOccurrences(of: "`", with: "\\`")
               .replacingOccurrences(of: "$", with: "\\$")
        }
    }
}
