import SwiftUI
import WebKit

/// Locates the bundled editor resources.
///
/// `Bundle.module` is not usable here: SwiftPM generates an accessor that only looks
/// next to the `.app` wrapper and at the absolute build path baked in at compile time,
/// and it calls `fatalError` when neither exists. An installed app whose source folder
/// has moved therefore crashes on launch. We look in the places the bundle can actually
/// live and return nil instead of trapping.
enum EditorResources {
    private static let bundleName = "Inkwell_Inkwell.bundle"

    static func url(forResource name: String, withExtension ext: String) -> URL? {
        let main = Bundle.main
        let candidates = [
            main.resourceURL?.appendingPathComponent(bundleName),  // installed .app
            main.bundleURL.appendingPathComponent(bundleName),     // swift run / SwiftPM layout
            main.resourceURL,                                      // resources copied flat
        ]

        for case let directory? in candidates {
            if let bundle = Bundle(url: directory),
               let url = bundle.url(forResource: name, withExtension: ext) {
                return url
            }
        }
        return nil
    }
}

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

        // Load from file URL so local JS bundle (milkdown.bundle.js) is found
        if let url = EditorResources.url(forResource: "editor", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            webView.loadHTMLString(Self.missingResourcesHTML, baseURL: nil)
        }

        context.coordinator.webView = webView
        context.coordinator.pendingContent = text
        return webView
    }

    private static let missingResourcesHTML = """
        <html><body style="font: -apple-system-body; padding: 2rem; color: #888">
        <h3>Editor resources missing</h3>
        <p>Inkwell could not find <code>editor.html</code>. Reinstall the app with
        <code>./build.sh</code>.</p>
        </body></html>
        """

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
        private var formatObserver: Any?

        init(onTextChange: @escaping (String) -> Void) {
            self.onTextChange = onTextChange
            super.init()

            formatObserver = NotificationCenter.default.addObserver(
                forName: .editorFormatCommand, object: nil, queue: .main
            ) { [weak self] notification in
                guard let cmd = notification.object as? String else { return }
                self?.webView?.evaluateJavaScript("formatCommand('\(cmd)')", completionHandler: nil)
            }

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
