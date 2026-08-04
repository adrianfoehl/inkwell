import SwiftUI

@main
struct InkwellApp: App {
    static let mainWindowID = "editor"

    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup(id: Self.mainWindowID) {
            ContentView()
        }
        .defaultSize(width: 900, height: 700)
        .commands {
            // The default New Window keeps Cmd+N, which the app's own New File
            // needs; New Window moves to Shift+Cmd+N.
            CommandGroup(replacing: .newItem) {
                Button("New File") {
                    NotificationCenter.default.post(name: .newFile, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("New Window") {
                    openWindow(id: Self.mainWindowID)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }

            CommandGroup(after: .saveItem) {
                Button("Save") {
                    NotificationCenter.default.post(name: .saveFile, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)

                Button("Reload from Disk") {
                    NotificationCenter.default.post(name: .reloadFile, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
            }

            CommandGroup(after: .textEditing) {
                Button("Toggle Source Mode") {
                    NotificationCenter.default.post(name: .toggleSourceMode, object: nil)
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
            }

            CommandMenu("Format") {
                Section("Inline") {
                    Button("Bold") {
                        NotificationCenter.default.post(name: .formatCommand, object: "bold")
                    }
                    .keyboardShortcut("b", modifiers: .command)

                    Button("Italic") {
                        NotificationCenter.default.post(name: .formatCommand, object: "italic")
                    }
                    .keyboardShortcut("i", modifiers: .command)

                    Button("Inline Code") {
                        NotificationCenter.default.post(name: .formatCommand, object: "code")
                    }
                    .keyboardShortcut("e", modifiers: .command)

                    Button("Strikethrough") {
                        NotificationCenter.default.post(name: .formatCommand, object: "strikethrough")
                    }
                    .keyboardShortcut("d", modifiers: [.command, .shift])
                }

                Divider()

                Section("Block") {
                    Button("Heading 1") {
                        NotificationCenter.default.post(name: .formatCommand, object: "h1")
                    }
                    .keyboardShortcut("1", modifiers: [.command, .option])

                    Button("Heading 2") {
                        NotificationCenter.default.post(name: .formatCommand, object: "h2")
                    }
                    .keyboardShortcut("2", modifiers: [.command, .option])

                    Button("Heading 3") {
                        NotificationCenter.default.post(name: .formatCommand, object: "h3")
                    }
                    .keyboardShortcut("3", modifiers: [.command, .option])
                }

                Divider()

                Section("Insert") {
                    Button("Bullet List") {
                        NotificationCenter.default.post(name: .formatCommand, object: "bulletList")
                    }

                    Button("Numbered List") {
                        NotificationCenter.default.post(name: .formatCommand, object: "orderedList")
                    }

                    Button("Blockquote") {
                        NotificationCenter.default.post(name: .formatCommand, object: "blockquote")
                    }

                    Button("Code Block") {
                        NotificationCenter.default.post(name: .formatCommand, object: "codeBlock")
                    }

                    Button("Divider") {
                        NotificationCenter.default.post(name: .formatCommand, object: "hr")
                    }
                }
            }
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        deliver(url, attempt: 0)
    }

    /// Sends the file to a single window: the focused one, else the frontmost.
    ///
    /// On a cold launch the window may not exist yet, and even once it does its
    /// SwiftUI content needs a moment to learn which window it sits in. Both cases
    /// look the same from here: nobody took the file, so try again shortly rather
    /// than drop it.
    private func deliver(_ url: URL, attempt: Int) {
        let request = targetWindow().map { OpenFileRequest(url: url, window: $0) }
        if let request {
            NotificationCenter.default.post(name: .openFileFromOS, object: request)
        }
        guard request?.isHandled != true, attempt < 30 else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            deliver(url, attempt: attempt + 1)
        }
    }

    private func targetWindow() -> NSWindow? {
        NSApp.commandTargetWindow
    }
}

extension NSApplication {
    /// The single window an app-wide command applies to.
    ///
    /// `keyWindow` is briefly nil while a window is opening or closing. Falling
    /// back to "everyone may act" there would let a single Cmd+S save every open
    /// document, so this always narrows down to at most one window.
    var commandTargetWindow: NSWindow? {
        if let key = keyWindow, key.isDocumentWindow { return key }
        if let main = mainWindow, main.isDocumentWindow { return main }
        return windows.first { $0.isVisible && $0.isDocumentWindow }
    }
}

extension NSWindow {
    /// Panels, the about box and similar auxiliary windows are never command targets.
    var isDocumentWindow: Bool {
        !(self is NSPanel) && contentView != nil
    }
}

/// One file, one destination window. The receiving window reports back so the
/// delegate knows the file actually arrived.
final class OpenFileRequest {
    let url: URL
    weak var window: NSWindow?
    var isHandled = false

    init(url: URL, window: NSWindow) {
        self.url = url
        self.window = window
    }
}

extension Notification.Name {
    static let saveFile = Notification.Name("inkwell.saveFile")
    static let formatCommand = Notification.Name("inkwell.formatCommand")
    static let openFileFromOS = Notification.Name("inkwell.openFileFromOS")
    static let toggleSourceMode = Notification.Name("inkwell.toggleSourceMode")
    static let reloadFile = Notification.Name("inkwell.reloadFile")
    static let newFile = Notification.Name("inkwell.newFile")
}
